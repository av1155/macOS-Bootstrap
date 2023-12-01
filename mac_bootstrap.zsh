#!/bin/zsh

# Script for bootstrapping a new MacBook for development.
# This script installs necessary tools and sets up symlinks for dotfiles.
# Assumptions: macOS with internet access and standard file system structure.
# Usage: Execute this script in a zsh shell.

# Define ANSI color escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No color (reset)
# BEGINNING OF FUNCTIONS ------------------------------------------------------

# Function to display colored messages
color_echo() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Confirmation prompt for starting the script
color_echo $YELLOW "Do you want to proceed with the BootStrap Setup Script? (y/n)"
echo -n "Enter choice: > "
read -r confirmation
if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
    color_echo $RED "BootStrap Setup Script aborted."
    exit 1
fi

# Function to calculate padding for centering text
calculate_padding() {
    local text="$1"
    local terminal_width=$(tput cols)
    local text_width=${#text}
    local padding_length=$(( (terminal_width - text_width) / 2 ))
    printf "%*s" $padding_length ""
}

# Function to display centered colored messages
centered_color_echo() {
    local color="$1"
    local message="$2"
    local padding=$(calculate_padding "$message")
    echo -e "${color}${padding}${message}${padding}${NC}"
}

# Function to attempt to clone using SSH, fallback to HTTPS if SSH fails
git_clone_fallback() {
    local ssh_url="$1"
    local https_url="$2"
    local clone_directory="$3"
    git clone "$ssh_url" "$clone_directory" || git clone "$https_url" "$clone_directory" || { color_echo $RED "Failed to clone repository."; exit 1; }
}

# Function to create a symlink
create_symlink() {
    local source_file="$1"
    local target_file="$2"

    if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        color_echo $GREEN "Symlink for $(basename "$source_file") already exists and is correct."
        return
    fi

    if [ -f "$target_file" ]; then
        color_echo $YELLOW "Existing file found for $(basename "$target_file"). Do you want to overwrite it? (y/n)"
        echo -n "Enter choice: > "
        read -r choice
        case "$choice" in
            y|Y )
                color_echo $BLUE "Backing up existing $(basename "$target_file") to $(basename "$target_file").bak"
                mv "$target_file" "${target_file}.bak" || { color_echo $RED "Failed to backup $target_file"; exit 1; }
                ;;
            n|N )
                color_echo $GREEN "Skipping $(basename "$target_file")."
                return
                ;;
            * )
                color_echo $RED "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi

    ln -sf "$source_file" "$target_file" || { color_echo $RED "Failed to create symlink for $(basename "$source_file")"; exit 1; }

    # Display this message only when a symlink is created.
    color_echo $GREEN "Created symlink for $(basename "$source_file") to $(basename "$target_file")."
}

# Function to prompt and install an app
install_app() {
    local app_name="$1"
    local install_command="$2"
    local check_command="$3"

    if ! eval "$check_command"; then
        color_echo $GREEN "$app_name already installed."
    else
        color_echo $YELLOW "Do you want to install $app_name? (y/n)"
        echo -n "Enter choice: > "
        read -r choice
        if [ "$choice" = "y" ]; then
            color_echo $BLUE "Installing $app_name..."
            eval "$install_command" || { color_echo $RED "Failed to install $app_name."; exit 1; }
        else
            color_echo $BLUE "Skipping $app_name installation."
        fi
    fi
}

# Function to install Neovim on macOS
install_neovim() {
    # URL for Neovim pre-built binary for macOS
    local nvim_url="https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-macos.tar.gz"
    local nvim_tarball="nvim-macos.tar.gz"

    # Check if Neovim is installed
    if ! command -v nvim &>/dev/null || [ -d "$HOME/nvim-macos" ]; then
        color_echo $YELLOW "Do you want to install Neovim? (y/n)"
        echo -n "Enter choice: > "
        read -r choice
        if [ "$choice" = "y" ]; then
            # Install dependencies
            color_echo $BLUE "Installing dependencies for Neovim..."
            brew install gettext || { color_echo $RED "Failed to install dependencies for Neovim."; exit 1; }

            # Download Neovim
            color_echo $BLUE "Downloading Neovim..."
            curl -LO $nvim_url || { color_echo $RED "Failed to download Neovim."; exit 1; }

            # Remove "unknown developer" warning
            color_echo $BLUE "Removing 'unknown developer' warning from Neovim tarball..."
            xattr -c $nvim_tarball

            # Extract Neovim
            color_echo $BLUE "Extracting Neovim..."
            tar xzf $nvim_tarball || { color_echo $RED "Failed to extract Neovim."; exit 1; }

            # Remove the tarball and extracted directory
            rm -f $nvim_tarball

            color_echo $GREEN "Neovim installed successfully."
        else
            color_echo $BLUE "Skipping Neovim installation."
        fi
    else
        color_echo $GREEN "Neovim already installed."
    fi
}

# END OF FUNCTIONS ------------------------------------------------------------

# Step 1: Install Xcode Command Line Tools -------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Xcode Command Line Tools Configuration -------------->"

echo ""

if ! xcode-select -p &>/dev/null; then
    color_echo $RED "Installing Xcode Command Line Tools..."
    xcode-select --install || { color_echo $RED "Failed to install Xcode Command Line Tools."; exit 1; }

    # Wait for Xcode Command Line Tools installation to complete
    until xcode-select -p &>/dev/null; do
        color_echo $YELLOW "Waiting for Xcode Command Line Tools to complete installation..."
        sleep 30
    done

    color_echo $GREEN "Xcode Command Line Tools installation complete."
else
    color_echo $GREEN "Xcode Command Line Tools already installed."
fi

# Step 2: Install Homebrew ----------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Homebrew Configuration -------------->"

echo ""

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    color_echo $BLUE "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { color_echo $RED "Failed to install Homebrew."; exit 1; }

    # Determine the architecture (Intel or Apple Silicon)
    arch_name="$(uname -m)"
    if [ "$arch_name" = "x86_64" ]; then
        # Intel Macs
        HOMEBREW_BIN="/usr/local/bin/brew"
    elif [ "$arch_name" = "arm64" ]; then
        # Apple Silicon Macs
        HOMEBREW_BIN="/opt/homebrew/bin/brew"
    else
        color_echo $RED "Unknown architecture: $arch_name"
        exit 1
    fi

    # Set up Homebrew in the shell only after installation
    echo "eval \"$($HOMEBREW_BIN shellenv)\"" >> $HOME/.zprofile
    eval "$($HOMEBREW_BIN shellenv)"
else
    color_echo $GREEN "Homebrew already installed."
fi

# Step 3: Install Git (if not already installed by Xcode Command Line Tools) ---
if ! command -v git &>/dev/null; then
    color_echo $BLUE "Installing Git..."
    brew install git || { color_echo $RED "Failed to install Git."; exit 1; }
fi

# Step 4: Installation of software --------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Installation of Software -------------->"

echo ""

# app_name: The name of the app.
# install_command: The command to install the app.
# check_command: The command to check if the app is already installed.

# Example:
# install_app "Visual Studio Code" "brew install --cask visual-studio-code" "! brew list --cask | grep -q visual-studio-code && [ ! -d '/Applications/Visual Studio Code.app' ]"

# Install Zplug
install_app "Zplug" "brew install zplug" "! brew list zplug &>/dev/null"

# Install iTerm2
install_app "iTerm2" "brew install --cask iterm2" "! brew list --cask | grep -q iterm2 && [ ! -d '/Applications/iTerm.app' ]"

# Install Docker
install_app "Docker" "brew install --cask docker" "! brew list --cask | grep -q docker && [ ! -d '/Applications/Docker.app' ]"

# Install Google Chrome
install_app "Google Chrome" "brew install --cask google-chrome" "! brew list --cask | grep -q google-chrome && [ ! -d '/Applications/Google Chrome.app' ]"

# Install Visual Studio Code
install_app "Visual Studio Code" "brew install --cask visual-studio-code" "! brew list --cask | grep -q visual-studio-code && [ ! -d '/Applications/Visual Studio Code.app' ]"

# Install JetBrains Toolbox
install_app "JetBrains Toolbox" "brew install --cask jetbrains-toolbox" "! brew list --cask | grep -q jetbrains-toolbox && [ ! -d '/Applications/JetBrains Toolbox.app' ]"

# Install Ollama
install_app "Ollama" "brew install ollama" "! brew list | grep -q ollama && [ ! -d '/Applications/Ollama.app' ]"

# After Oh My Zsh installation, insert a reminder to run the script again
echo "After Oh My Zsh installation, re-run this script to complete the setup."

# Install Oh My Zsh
install_app "Oh My Zsh" "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"" "[ ! -d '$HOME/.oh-my-zsh' ]"

# Check if Oh My Zsh is installed before attempting to install zsh-syntax-highlighting
if [ -d "$HOME/.oh-my-zsh" ]; then
    # Install zsh-syntax-highlighting plugin
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        color_echo $BLUE "Installing zsh-syntax-highlighting plugin..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || { color_echo $RED "Failed to clone zsh-syntax-highlighting."; exit 1; }
    else
        color_echo $GREEN "zsh-syntax-highlighting plugin already installed."
    fi
else
    color_echo $RED "Oh My Zsh is not installed. Please install Oh My Zsh first."
fi

# # Flag to check if Miniforge3 was not installed
# MINIFORGE_NOT_INSTALLED=$(command -v conda &>/dev/null; echo $?)

# Install Miniforge3
install_app "Miniforge3" "brew install miniforge" "! command -v conda &>/dev/null"

# # If Miniforge3 was not installed and is installed now, initialize conda for zsh
# if [ $MINIFORGE_NOT_INSTALLED -ne 0 ] && command -v conda &>/dev/null; then
#     echo "Initializing conda for zsh..."
#     conda init "$(basename "${SHELL}")"
# fi

# Install Powerlevel10k Theme
install_app "Powerlevel10k" "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k" "[ ! -d '$HOME/powerlevel10k' ]"

# Determine the architecture of the macOS system
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
    # Intel architecture (x86_64)
    JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-x64_bin.tar.gz"
elif [ "$ARCH" = "arm64" ]; then
    # ARM architecture (Apple Silicon)
    JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-aarch64_bin.tar.gz"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Install Java
install_app "Java" \
    "mkdir -p $HOME/Library/Java/JavaVirtualMachines && curl -L $JDK_URL | tar xz -C $HOME/Library/Java/JavaVirtualMachines" \
    "[ ! -d \"$HOME/Library/Java/JavaVirtualMachines/jdk-21.0.1.jdk\" ]"

# Step 5: Clone .dotfiles repository -------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Dotfiles + BootStrap Repository Configuration -------------->"

echo ""

DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    color_echo $BLUE "Cloning .dotfiles repository..."
    git clone "https://github.com/av1155/.dotfiles.git" "$DOTFILES_DIR" || \
        { color_echo $RED "Failed to clone .dotfiles repository."; exit 1; }
else
    color_echo $GREEN "The '.dotfiles' directory already exists. Skipping clone of repository."
    echo ""
fi

# Step 6: Install software from Brewfile ---------------------------------------

# Confirmation prompt for Brewfile installation
color_echo $YELLOW "Do you want to proceed with installing software from Brewfile? (y/n)"
echo -n "Enter choice: > "
read -r brewfile_confirmation
if [ "$brewfile_confirmation" != "y" ] && [ "$brewfile_confirmation" != "Y" ]; then
    color_echo $RED "Brewfile installation aborted."
else
    color_echo $BLUE "Installing software from Brewfile..."
    brew bundle --file "$DOTFILES_DIR/Brewfile" || { color_echo $RED "Failed to install software from Brewfile."; exit 1; }
    color_echo $GREEN "Brewfile installation complete."
fi

echo ""
# Install Neovim if Brewfile installation was unsuccessful
install_neovim

# Validate TMUX_CONFIG_DIR ----------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- tmux Config Directory Setup -------------->"

echo ""

TMUX_CONFIG_DIR="$HOME/.config/tmux"
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    color_echo $BLUE "Creating tmux config directory..."
    mkdir -p "$TMUX_CONFIG_DIR"
else
    color_echo $GREEN "The tmux config directory already exists. Skipping configuration."
fi

# Step 7: Create symlinks (Idempotent) ----------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Symlinks Configuration -------------->"

echo ""

color_echo $BLUE "Creating symlinks..."

# Symlinks go here:
# create_symlink "$DOTFILES_DIR/configs/.original_file" "$HOME/.linked_file"
create_symlink "$DOTFILES_DIR/configs/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/configs/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/configs/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# -----------------------------------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Configuration of NVM, NODE, & NPM -------------->"

echo ""

# Check if NVM (Node Version Manager) is installed ----------------------------
if [ ! -d "$HOME/.nvm" ]; then
    # Install NVM if it's not installed
    color_echo $BLUE "Installing Node Version Manager (nvm)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash || { color_echo $RED "Failed to install nvm."; exit 1; }

    # Run the following to use it in the same shell session:
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    # For Zsh completion, you would need a Zsh-specific completion script
    # [ -s "path/to/zsh-completion-script" ] && . "path/to/zsh-completion-script" # Optional: This loads nvm Zsh completion

else
    color_echo $GREEN "NVM already installed."
fi

echo ""

# Check if Node is installed --------------------------------------------------
if ! command -v node &>/dev/null; then
    # Install Node.js using NVM if it's not installed
    color_echo $BLUE "Installing Node.js..."
    nvm install node || { color_echo $RED "Failed to install Node.js."; exit 1; }
else
    color_echo $GREEN "Node.js already installed."
fi

echo ""

# Install Global npm Packages: ------------------------------------------------
color_echo $BLUE "Installing global npm packages..."

# Check and install tree-sitter-cli
if ! npm list -g tree-sitter-cli &>/dev/null; then
    color_echo $BLUE " * tree-sitter-cli: "
    npm install -g tree-sitter-cli || { color_echo $RED "Failed to install tree-sitter-cli."; exit 1; }
else
    color_echo $GREEN " * tree-sitter-cli already installed."
fi

# Check and install live-server
if ! npm list -g live-server &>/dev/null; then
    color_echo $BLUE " * live-server: "
    npm install -g live-server || { color_echo $RED "Failed to install live-server."; exit 1; }
else
    color_echo $GREEN " * live-server already installed."
fi

# Install JetBrainsMono Nerd Font ---------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Configuration of Nerd Fonts -------------->"

echo ""

# Confirmation prompt for font installation
color_echo $YELLOW "Do you want to proceed installing JetBrainsMono Nerd Font? (y/n)"
echo -n "Enter choice: > "
read -r font_confirmation
if [ "$font_confirmation" != "y" ] && [ "$font_confirmation" != "Y" ]; then
    color_echo $RED "Font installation aborted."
else
    color_echo $BLUE "Installing JetBrainsMono Nerd Font..."
    FONT_DIR="$HOME/Library/Fonts"
    if [ ! -d "$FONT_DIR" ]; then
        color_echo $BLUE "Creating font directory..."
        mkdir -p "$FONT_DIR"
    fi
    curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip -o "$FONT_DIR/JetBrainsMono.zip" || { color_echo $RED "Failed to download JetBrainsMono Nerd Font."; exit 1; }
    unzip "$FONT_DIR/JetBrainsMono.zip" -d "$FONT_DIR" || { color_echo $RED "Failed to unzip JetBrainsMono Nerd Font."; exit 1; }
    rm "$FONT_DIR/JetBrainsMono.zip"
    color_echo $GREEN "JetBrainsMono Nerd Font installation complete."
fi

# AstroNvim Installation ------------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- AstroNvim Configuration -------------->"

echo ""

# Check if ~/.config/nvim exists
if [ -d "$HOME/.config/nvim" ]; then
    color_echo $YELLOW "AstroNvim configuration already exists. Do you want to proceed with the AstroNvim installation? (y/n)"
    echo -n "> "
    read -r choice
    case "$choice" in
        y|Y )
            color_echo $BLUE "Proceeding with AstroNvim installation..."
            # Install AstroNvim
            color_echo $BLUE "Installing AstroNvim..."
            [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
            [ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
            [ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
            [ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"
            git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
            ;;
        n|N )
            color_echo $GREEN "Skipping AstroNvim installation."
            ;;
        * )
            color_echo $RED "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    # If ~/.config/nvim doesn't exist, proceed with cloning
    git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
fi

echo ""

# Check if ~/.config/nvim/lua/user exists
if [ -d "$HOME/.config/nvim/lua/user" ]; then
    color_echo $YELLOW "AstroNvim user configuration directory already exists. Do you want to replace it with a new configuration? (y/n)"
    echo -n "> "
    read -r choice
    case "$choice" in
        y|Y )
            color_echo $BLUE "Replacing existing user configuration..."
            rm -rf "$HOME/.config/nvim/lua/user"
            git_clone_fallback "git@github.com:av1155/astronvim_config.git" "https://github.com/av1155/astronvim_config.git" "$HOME/.config/nvim/lua/user"
            ;;
        n|N )
            color_echo $GREEN "Keeping existing user configuration."
            ;;
        * )
            color_echo $RED "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    # If ~/.config/nvim/lua/user doesn't exist, proceed with cloning
    git_clone_fallback "git@github.com:av1155/astronvim_config.git" "https://github.com/av1155/astronvim_config.git" "$HOME/.config/nvim/lua/user"
fi

# -----------------------------------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- TODO List of Apps to Download -------------->"

echo ""

# Define the list of apps
app_list=(
    "1Blocker.app"
    "1Password.app"
    "1Password for Safari.app"
    "Adobe Creative Cloud"
    "AlDente.app"
    "Alfred 5.app"
    "AltTab.app"
    "Anki.app"
    "AppCleaner.app"
    "Bartender 5.app"
    "BetterDisplay.app"
    "CalcBar.app"
    "CheatSheet.app"
    "Cinebench.app"
    "CleanMyMac X.app"
    "Color Picker.app"
    "Discord.app"
    "Dropover.app"
    "Encrypto.app"
    "Flycut.app"
    "Goodnotes.app"
    "Grammarly Desktop.app"
    "Grammarly for Safari.app"
    "IINA.app"
    "Latest.app"
    "LockDown Browser.app"
    "Maccy.app"
    "Magnet.app"
    "Mathpix Snipping Tool.app"
    "Microsoft Edge.app"
    "Microsoft Excel.app"
    "Microsoft OneNote.app"
    "Microsoft Outlook.app"
    "Microsoft PowerPoint.app"
    "Microsoft Teams classic.app"
    "Microsoft Word.app"
    "MiddleClick.app"
    "MonitorControl.app"
    "Notion.app"
    "Ollama.app"
    "OneMenu.app"
    "OnyX.app"
    "PS Remote Play.app"
    "Ryujinx.app"
    "Shottr.app"
    "Spotify.app"
    "The Unarchiver.app"
    "TickTick.app"
    "Warp.app"
    "WhatsApp.app"
    "zoom.us.app"
)

# Create a text file on the desktop with the app list
desktop_path="$HOME/Desktop/apps_to_download.txt"
printf "%s\n" "${app_list[@]}" > "$desktop_path"

# Print a message to inform the user
color_echo $BLUE "A TODO list of apps to download has been created on your desktop: $desktop_path"

# -----------------------------------------------------------------------------

echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Thank You! -------------->"

echo "" # Print a blank line

color_echo $PURPLE "🚀 Installation successful! Your development environment is now supercharged and ready for lift-off. Please restart your computer to finalize the setup. Happy coding! 🚀"

# -----------------------------------------------------------------------------
