#!/usr/bin/env bash

# Establish run order
main() {
    declare_globals
    main_menu
}

shell_settings(){
    set -euo pipefail
    trap finish EXIT
    IFS=$'\n\t'
}

# Configure variables
declare_globals(){
    git_repo="git@github.com:ecmatthee/dotfiles"
}

main_menu(){
    echo "Populate dev?"

    choices=( 'Yes' 'Cancel')

    select choice in "${choices[@]}"; do

    [[ -n $choice ]] || { echo "Invalid choice." >&2; continue; }
    case $choice in
    Yes)
        echo "Cloning git repos..."

        dev_clone

        echo "Task Complete"
    ;;
    Cancel)
        echo "Exiting. "
        exit 0
    esac
  break
done
}

dev_clone(){
    cd ~/dev/
    git clone "$git_repo".git/alisa
    git clone "$git_repo".git/delegex
}

