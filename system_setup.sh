#!/usr/bin/env bash

# Establish run order
main() {
    shell_settings
    declare_globals
    heredoc_create
    main_menu
    finish

    ## TODO
    # Firefox setup still needs solution --> Bookmarks are important, the rest are useless
}

shell_settings(){
    set -euo pipefail
    trap finish EXIT
    IFS=$'\n\t'
}

# Configure variables
declare_globals(){
    git_repo="git@github.com:ecmatthee/dotfiles"

    #Tmp folder
    script_tmp=$(mktemp -q -d)

    ## Heredocs Paths
    # Package Lists
    package_list="$script_tmp/package-list.txt"
    aur_list="$script_tmp/aur-package-list.txt"
    # Setting files
    sudo_custom="$script_tmp/sudo-custom"
    pacman_custom="$script_tmp/pacman-custom"
}

heredoc_create(){

    (
cat << EOF
# Programming
gcc
git
go
gvim
jre-openjdk
make
python
shellcheck

# Terminal
fzf
konsole
tmux
grml-zsh-config
zsh
zsh-autosuggestions
zsh-completions
zsh-history-substring-search
zsh-syntax-highlighting
zsh-theme-powerlevel10k

# System
base-devel
gnupg
keychain
ntfs-3g
openssh
pacman-contrib
reflector
rsync
sudo

# System Tools
hardinfo
rclone
syncthing
syncthing-gtk

# Tools
audacity
calcurse
handbrake
kdenlive
keepassxc
mupdf
mupdf-tools
qbittorrent
youtube-dl
zotero

# Virtual Box
virtualbox
virtualbox-guest-iso
virtualbox-guest-utils
virtualbox-host-modules-arch

# Media
audacious
calibre
mupdf
mupdf-tools
nomacs
libretro
vlc

# Browser
firefox

# Login
sddm
sddm-kcm

# X Server
xorg

# Kde Plasma
ark
dolphin
dolphin-plugins
filelight
kdeconnect
plasma-meta
spectacle

# Deps
libdvdcss    # VLC - read dvd
libdvdnav    # VLC - read dvd
libdvdread   # VLC - read dvd
sshfs        # KdeConnect - browse phone files

# Compression deps
bzip2        # zsh function
gzip         # zsh function
lrzip        # Ark - file support
lzop         # Ark - file support
p7zip        # Ark - file support | zsh function
tar          # Core | zsh function
unarchiver   # Ark - file support
unrar        # Ark - file support | zsh function
zip
unzip        # zsh function
xz           # Core | zsh function
EOF
    ) > "$package_list"

    (
cat << EOF
android-studio
aseprite
drawio-desktop-bin
godot
google-chrome
nerd-fonts-dejavu-complete
visual-studio-code-bin
zotero
EOF
    ) > "$aur_list"


# Sudo config
    (
cat << EOF
##Custom Sudo Config
# sudo authentication lasts 1h (60 mins)
Defaults   timestamp_timeout=60
# sudo session accross terminals
Defaults !tty_tickets
EOF
) > "$sudo_custom"

# Pacman config
(
cat << EOF
# Misc
Color
ILoveCandy

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
) > "$pacman_custom"
}

main_menu(){
    echo "Continue new system setup?"

    choices=( 'Yes' 'Cancel')

    select choice in "${choices[@]}"; do

        [[ -n $choice ]] || { echo "Invalid choice." >&2; continue; }
        case $choice in
            Yes)
                echo "System setup starting..."

                folder_system_create
                package_download
                git_dotfiles
                system_setup

                echo "System setup complete"
                ;;
            Cancel)
                echo "Exiting. "
                exit 0
        esac
        break
    done
}

folder_system_create(){
    mkdir ~/.config

    mkdir ~/bin          # Self explanatory
    mkdir ~/.dotfiles    # Git dotfile clone location
    mkdir ~/.ssh         # SSH key storage
    mkdir ~/.private     # Secret directory

    mkdir ~/proj         # Non coding projects
    mkdir ~/dev          # Project directory

    mkdir ~/cloud_mount  # Mount point for rclone
    mkdir ~/tmp          # Dump folder --> feel free to rm -rf

    mkdir ~/root        # Personal files directory
}

package_download(){
    # pacman setup
    echo 'include = /etc/pacman.d/pacman-custom' >> /etc/pacman.conf
    sudo cp "$pacman_custom" /etc/pacman.d/

    # System update
    sudo pacman -Syu

    # Get packages
    sed -e "/^#/d" -e "s/#.*//" "$package_list" | pacman -S --needed -

    # Yay setup
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -sirc

    # AUR get packages
    yay -Syyu --needed - < "$aur_list"
    # Set Yay setting
    yay -Syu --sudoloop --cleanafter --save

    # Mirror list
    sudo reflector --verbose --latest 100 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # Flutter
    cd ~/bin
    git clone https://github.com/flutter/flutter.git
    cd
}

# Clone dotfile repo
git_dotfiles(){
    alias dotfiles="/usr/bin/git --git-dir=\$HOME/.dotfiles.git/ --work-tree=\$HOME"
    echo ".dotfiles" >> .gitignore

    git clone --bare "$git_repo".git "$HOME"/.dotfiles

    dotfiles checkout -f

    dotfiles config --local status.showUntrackedFiles no
}

# Setup dotfiles on system
system_setup(){
    # sudo setup
    # (nb -> $sudo_custom has been checked for errors by visudo, do not edit unless you know what your doing)
    sudo cp "$sudo_custom" /etc/sudoers.d/

    # Change shell to zsh
    chsh -s /bin/zsh
}

finish(){
    rm -rf "$script_tmp"
}

main
