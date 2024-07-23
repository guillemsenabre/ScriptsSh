#!/bin/bash

# cd into kernel directory
pushd ~/kernel_last

# Define the starting commit (the on defined is 1 commit before, due to the nature of the command used (rev-list))
START_COMMIT="c32ad7b836c87ab5b796e724c39f14d5cbcb4715"

# Get the list of commits from the starting point to the latest
commits=$(git rev-list --reverse $START_COMMIT..HEAD)

# Iterate over each commit in the list
for current_commit in $commits
do
    # Get the commit message and other details for the current commit
    current_details=$(git log -1 --pretty=format:"%h %an %ad %s" --date=short "$current_commit")

    # Print the commit information
    echo "--------------------------------------------------"
    echo "Commit: $current_details"
    echo "--------------------------------------------------"

    # Show the details of the commit using less for pagination
    git show "$current_commit" | less -R

    # Wait for user input before moving to the next commit
    read -p "Press [Enter] to continue to the next commit..."
done

popd
