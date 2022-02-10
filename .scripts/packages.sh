#!/bin/bash

HELP="Usage: sudo ./packages.sh <operation> [...]
Automatically install Arch Linux packages

operations:
    -a              install all packages
    -m              installs AUR packages
    -t <options>    installs packages of GUI or CLI
<options>:
    gui             installs packages of GUI
    cli             installs packages of CLI


Examples:
$ sudo ./packages.sh -mt gui
$ sudo ./packages.sh -m -t cli
$ sudo ./packages.sh -a"

if [ -z "$SUDO_USER" ]; then
    echo "$HELP"
    exit 1
fi

allFlag=
aurFlag=
typeFlag=
while getopts amt: name
do
    case $name in
        a) allFlag=1;;
        m) aurFlag=1;;
        t) typeFlag=1
           typeVal=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]');;
        *) echo "$HELP"
           exit 2;;
    esac

done

if [ $OPTIND -eq 1 ]; then
    echo "$HELP"
    exit 1
fi

CLI_PACKAGES=(
    'archlinux-keyring'
    'bat'
    'fzf'
    'htop'
    'git'
    'lsd'
    'neofetch'
    'neovim'
    'nnn'
    'ripgrep'
    'ttf-fira-code'
    'zsh'
)

GUI_PACKAGES=(
    'dolphin'
    'flameshot'
    'kitty'
    'sway'
    'wayland'
    'waybar'
    'wofi'
)

AUR_PACKAGES=(
    'beautyline'
    'ibus-bamboo'
    'google-chrome'
    'sweet-cursor-theme-git'
    'sweet-gtk-theme-dark'
    'sweet-kde-git'
    'visual-studio-code-bin'

)

function banner() {
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    TEXT=$CYAN
    BORDER=$YELLOW
    EDGE=$(echo "  $1  " | sed 's/./~/g')

    if [ "$2" == "warn" ]; then
        TEXT=$YELLOW
        BORDER=$RED
    fi

    MSG="${BORDER}~ ${TEXT}$1 ${BORDER}~${NC}"
    echo -e "${BORDER}$EDGE${NC}"
    echo -e "$MSG"
    echo -e "${BORDER}$EDGE${NC}"
}

function packageIterator() {
    local MANAGER="$1"
    shift
    local PACKAGES=("$@")

    for i in "${PACKAGES[@]}";
    do
        if pacman -Qq "$i" > /dev/null ; then
            continue
        fi

        if [ "$MANAGER" == paru ]; then
            if ! sudo -u "$SUDO_USER" paru -S "$i" -q --noconfirm; then
                banner "I was unable to install the package $i" "warn"
                exit 1
            fi
            continue
        fi

        if ! pacman -S "$i" --quiet --noconfirm; then
            banner "I was unable to install the package $i" "warn"
            exit 1
        fi
    done
}

function installAurPackages() {
    if [ -z "$aurFlag" ]; then
        return 0
    fi
    banner "I will install the AUR packages"
    packageIterator "paru" "${AUR_PACKAGES[@]}"
}

function installParu() {
    if pacman -Qs paru > /dev/null ; then
        return 0
    fi
    
    sudo -u "$SUDO_USER" -- sh -c "
    git clone https://aur.archlinux.org/paru.git;
    cd paru || return;
    makepkg -si --noconfirm"
}


function configurePacman() {
    sed -i 's/#Color/Color\nILoveCandy/g' /etc/pacman.conf
}

function installPackages() {
    banner "I Love Candy"
    configurePacman

    if [ "$typeVal" == 'cli' ]; then
        banner "Installing the CLI packages..."
        packageIterator "pacman" "${CLI_PACKAGES[@]}"
    elif [ "$typeVal" == 'gui' ]; then
        banner "Installing the GUI packages..."
        packageIterator "pacman" "${GUI_PACKAGES[@]}"
    fi

    installParu
}

if [ $allFlag == 1 ]; then
    typeVal='cli'
    installPackages
    installAurPackages
    typeVal='gui'
    aurFlag=1
    installPackages
    installAurPackages
    banner "All done! :)"
    exit 0
fi

if [ -z "$typeFlag" ]; then
    banner "Packages can't be blank" "warn"
    exit 1
fi

if [ "$typeVal" != 'cli' ] && [ "$typeVal" != 'gui' ]; then
    banner "Invalid packages" "warn"
    exit 1
fi

installPackages
installAurPackages

banner "Done :)"