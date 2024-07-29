#!/bin/bash

## Start Configuration ##

export xuetie_toolchain=https://occ-oss-prod.oss-cn-hangzhou.aliyuncs.com/resource//1663142514282
export toolchain_file_name=Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.1-20220906.tar.gz
export toolchain_tripe=riscv64-linux-gnu-
export ARCH=riscv
export nproc=12
WORKSPACE_DIR="th1520_build_556f057ac"
KERNEL_COMMIT_ID="556f057aca339cae1f71e91b41650337eaee4d9e"
export GITHUB_WORKSPACE="${HOME}/${WORKSPACE_DIR}"
export KERNEL_GIT="https://github.com/revyos/thead-kernel.git"

# Creates build directory and cds into it
mkdir ${WORKSPACE_DIR} && cd ${WORKSPACE_DIR} || { echo "INFO: Kernel clone failed, exiting..."; exit 1; }


# Updates OS and install necesary dependencies
sudo apt update && \
              sudo apt install -y gdisk dosfstools g++-12-riscv64-linux-gnu build-essential \
                                  libncurses-dev gawk flex bison openssl libssl-dev tree \
                                  dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf device-tree-compiler
              sudo update-alternatives --install \
                  /usr/bin/riscv64-linux-gnu-gcc riscv64-gcc /usr/bin/riscv64-linux-gnu-gcc-12 10
              sudo update-alternatives --install \
                  /usr/bin/riscv64-linux-gnu-g++ riscv64-g++ /usr/bin/riscv64-linux-gnu-g++-12 10

# Creates directories to store boot files, modules and binaries such as perf
mkdir rootfs && mkdir rootfs/boot
mkdir -p ${GITHUB_WORKSPACE}/rootfs/boot/
mkdir -p ${GITHUB_WORKSPACE}/rootfs/sbin/

# Kernel directory name and revyos configuration setup
KERNEL_DIR=kernel
KERNEL_CONFIG=revyos_defconfig

# Cloning kernel (last version). Later you can decide using an older version (need to specify commit_id in KERNEL_COMMIT_ID)
git clone ${KERNEL_GIT} ${KERNEL_DIR}

# Getting cross compile toolchain if necessary.
if [ ! -e "/opt/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.1" ]; then
	# If cross compile tools are not in /opt, decompress inside /opt
	wget ${xuetie_toolchain}/${toolchain_file_name}
	sudo tar -xvf ${toolchain_file_name} -C /opt
	export PATH="/opt/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.1/bin:$PATH"
else
	# If cross compile tools are in /opt, add to PATH
	export PATH="/opt/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.1/bin:$PATH"
fi


#BUILD KERNEL
echo "Building kernel..."
pushd $KERNEL_DIR
echo "Taking specific commit..."
git reset --hard $KERNEL_COMMIT_ID

echo "Compiling..."
make CROSS_COMPILE=${toolchain_tripe} ARCH=${ARCH} ${KERNEL_CONFIG}
make CROSS_COMPILE=${toolchain_tripe} ARCH=${ARCH} -j$(nproc)
make CROSS_COMPILE=${toolchain_tripe} ARCH=${ARCH} -j$(nproc) dtbs
if [ x"$(cat .config | grep CONFIG_MODULES=y)" = x"CONFIG_MODULES=y" ]; then
    sudo make CROSS_COMPILE=${toolchain_tripe}  ARCH=${ARCH} INSTALL_MOD_PATH=${GITHUB_WORKSPACE}/rootfs/ modules_install -j$(nproc)
fi


#BUILD PERF
#make CROSS_COMPILE=${toolchain_tripe} ARCH=riscv LDFLAGS=-static NO_LIBELF=1 NO_JVMTI=1 VF=1 -C tools/perf/
#sudo cp -v tools/perf/perf ${GITHUB_WORKSPACE}/rootfs/sbin/perf-thead


#(?)#[ ! -d ${GITHUB_WORKSPACE}/rootfs/boot/ ] && mkdir -p ${GITHUB_WORKSPACE}/rootfs/boot/

# record commit-id
echo "Recording commit id"
git rev-parse HEAD > kernel-commitid
sudo cp -v kernel-commitid ${GITHUB_WORKSPACE}/rootfs/boot/


# Install kernel
echo "Installing kernel into rootfs/boot/"
echo $PWD
sudo cp -v arch/riscv/boot/Image ${GITHUB_WORKSPACE}/rootfs/boot/

# INSTALL DTB, device tree to target directory (ORIGINAL KERNEL FROM SIPEED)
echo "Installing dtbs to target directory"
sudo cp -v arch/riscv/boot/dts/thead/{light-lpi4a.dtb,light-lpi4a-16gb.dtb} ${GITHUB_WORKSPACE}/rootfs/boot/

#kernel 6.8 files DTB
#arch/riscv/boot/dts/thead/{th1520.dtsi,th1520-lichee-module-4a.dtsi,th1520-lichee-pi-4a.dtsi}
#make CROSS_COMPILE=${toolchain_tripe} ARCH=${ARCH} dtbs
#sudo cp -v ./arch/riscv/boot/dts/thead/th1520-lichee-pi-4a.dts ${GITHUB_WORKSPACE}/rootfs/boot

popd