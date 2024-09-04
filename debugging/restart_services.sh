#!/bin/bash

# Constants
LOG_FILE="/var/log/service_restart.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Functions

log() {
    local message="$1"
    echo "$DATE: $message" | tee -a "$LOG_FILE"
}

check_service_exists() {
    local service_name="$1"
    if systemctl list-units --type=service | grep -q "$service_name.service"; then
        return 0
    else
        log "Service $service_name does not exist."
        return 1
    fi
}

restart_service() {
    local service_name="$1"
    if check_service_exists "$service_name"; then
        log "Attempting to restart $service_name..."
        if systemctl restart "$service_name"; then
            log "Successfully restarted $service_name."
        else
            log "Failed to restart $service_name."
            return 1
        fi
    else
        return 1
    fi
}

restart_services() {
    local services=("$@")
    for service in "${services[@]}"; do
        restart_service "$service" || return 1
    done
}

show_usage() {
    echo "Usage: $0 [--dry-run] [--help]"
    echo
    echo "Options:"
    echo "  --dry-run  Simulate the restart without actually restarting services."
    echo "  --help     Show this help message."
}

# Main Script
DRY_RUN=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            show_usage
            exit 1
            ;;
    esac
done

APACHE_SERVICES=("apache2")
NEUTRON_SERVICES=(
    "neutron-api"
    "neutron-openvswitch-agent"
    "neutron-rpc-server"
    "neutron-metadata-agent"
    "neutron-dhcp-agent"
    "neutron-l3-agent"
)
NOVA_SERVICES=(
    "nova-api"
    "nova-scheduler"
    "nova-conductor"
    "nova-novncproxy"
)

if $DRY_RUN; then
    log "Dry run mode enabled. No services will be restarted."
else
    log "Starting service restart process..."

    restart_services "${APACHE_SERVICES[@]}" || exit 1
    restart_services "${NEUTRON_SERVICES[@]}" || exit 1
    restart_services "${NOVA_SERVICES[@]}" || exit 1

    log "Service restart process completed."
fi

exit 0
