#!/bin/bash

# Check if the user is root
if [ "$EUID" -ne 0 ]; then
  echo "This script needs to be run with sudo"
  exit 1
fi

# Function to install packages
install_packages() {
    local packages=("$@")
    local installed=false

    if command -v pacman >/dev/null; then
        pacman -Sy --noconfirm "${packages[@]/#/-S }" >/dev/null || { echo "Error: Failed to install packages with pacman"; exit 1; }
        installed=true
    fi

    if command -v apt-get >/dev/null; then
        apt-get update >/dev/null || { echo "Error: Failed to update package lists with apt-get"; exit 1; }
        apt-get install -y "${packages[@]}" >/dev/null || { echo "Error: Failed to install packages with apt-get"; exit 1; }
        installed=true
    fi

    if ! $installed; then
        echo "Error: Unsupported package manager. Exiting."
        exit 1
    fi
}

echo "Installing packages..."
install_packages curl git stow zsh

echo "Linking dotfiles using stow..."
if ! cd /home/$SUDO_USER/dotfiles; then
    echo "Error: Unable to change directory to dotfiles directory. Exiting."
    exit 1
fi

if ! stow . >/dev/null; then
    echo "Error: Failed to link dotfiles using stow. Exiting."
    exit 1
fi


echo "Installing and setting up zoxide..."
if ! sudo -u $SUDO_USER curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sudo -u $SUDO_USER sh >/dev/null; then
    echo "Error: Failed to install zoxide. Exiting."
    exit 1
fi

echo "Installing and setting up fzf..."
if ! git clone --quiet --depth 1 https://github.com/junegunn/fzf.git /home/$SUDO_USER/.fzf 2>&1 >/dev/null; then
    echo "Error: Failed to clone fzf repository. Exiting."
    exit 1
fi

if ! yes | /home/$SUDO_USER/.fzf/install >/dev/null 2>&1; then
    echo "Error: Failed to install fzf. Exiting."
    exit 1
fi


echo "Changing default shell..."
if ! chsh -s $(which zsh) $SUDO_USER >/dev/null; then
    echo "Error: Failed to change default shell. Exiting."
    exit 1
fi

echo "Finished. Restart your terminal for these changes to take effect. NOTE: You will need to change your font to a nerdfont (like the one given) to make everything work"
