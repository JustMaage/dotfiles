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
        pacman -Sy --noconfirm "${packages[@]/#/-S }" || { echo "Error: Failed to install packages with pacman"; exit 1; }
        installed=true
    fi

    if command -v apt-get >/dev/null; then
        apt-get update || { echo "Error: Failed to update package lists with apt-get"; exit 1; }
        apt-get install -y "${packages[@]}" || { echo "Error: Failed to install packages with apt-get"; exit 1; }
        installed=true
    fi

    if ! $installed; then
        echo "Error: Unsupported package manager. Exiting."
        exit 1
    fi
}

echo "Copying dotfiles..."
cp .zshrc ~/
cp .p10k.zsh ~/

echo "Installing dependencies..."
install_packages curl git

echo "Installing and setting up zsh..."
install_packages zsh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && yes | ~/.fzf/install

echo "Changing default shell..."
chsh -s $(which zsh)

echo "Finished. Restart your terminal for these changes to take effect. NOTE: You will need to change your font to a nerdfont (like the one given) to make everything work"