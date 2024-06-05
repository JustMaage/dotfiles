#!/bin/bash
 
# Check if the user is root
if [ "$EUID" -ne 0 ]; then
  echo "This script needs to be run with sudo"
  exit 1
fi
 
# Function to install packages
install_packages() {
    local packages=("$@")
    local package_manager=""
 
    # Detect the package manager
    if command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v apt &> /dev/null; then
        package_manager="apt"
    else
        echo "Error: Neither pacman nor apt package manager found."
        return 1
    fi
 
    # Install packages based on the detected package manager
    case "$package_manager" in
        "pacman")
            if ! sudo pacman -Sy --noconfirm "${packages[@]}" >/dev/null 2>&1; then
                echo "Error: Unable to install packages using pacman. Exiting."
                exit 1
            fi
            ;;
        "apt")
            if ! sudo apt update >/dev/null 2>&1; then
                echo "Error: Unable to update packages using apt. Exiting."
                exit 1
            fi
            
            if ! sudo apt install -y "${packages[@]}" >/dev/null 2>&1; then
                echo "Error: Unable to install packages using apt. Exiting."
                exit 1
            fi
            ;;
        *)
            echo "Error: Unsupported package manager."
            return 1
            ;;
    esac
}
 
echo "Installing packages..."
install_packages curl git stow zsh
 
echo "Linking dotfiles using stow..."
if ! cd /home/$SUDO_USER/dotfiles; then
    echo "Error: Unable to change directory to dotfiles directory. Exiting."
    exit 1
fi
 
if ! stow . >/dev/null 2>&1; then
    echo "Error: Failed to link dotfiles using stow. Exiting."
    exit 1
fi
 
 
echo "Installing and setting up zoxide..."
if ! sudo -u $SUDO_USER curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sudo -u $SUDO_USER sh >/dev/null; then
    echo "Error: Failed to install zoxide. Exiting."
    exit 1
fi
 
echo "Installing and setting up fzf..."
if ! git clone --quiet --depth 1 https://github.com/junegunn/fzf.git /home/$SUDO_USER/.fzf >/dev/null 2>&1; then
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
 