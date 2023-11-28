#!/bin/zsh

# Define ANSI color escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No color (reset)

# Function to display colored messages
color_echo() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

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

# Attempt to clone using SSH, fallback to HTTPS if SSH fails
git_clone_fallback() {
    local ssh_url="$1"
    local https_url="$2"
    local clone_directory="$3"
    git clone "$ssh_url" "$clone_directory" || git clone "$https_url" "$clone_directory" || { color_echo $RED "Failed to clone repository."; exit 1; }
}

# Script for bootstrapping a new MacBook for development.
# This script installs necessary tools and sets up symlinks for dotfiles.
# Assumptions: macOS with internet access and standard file system structure.
# Usage: Execute this script in a zsh shell.

# Step 1: Install Xcode Command Line Tools
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Xcode Command Line Tools Configuration -------------->"

echo "" # Print a blank line

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

# Step 2: Install Homebrew
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Homebrew Configuration -------------->"

echo "" # Print a blank line

if ! command -v brew &>/dev/null; then
    color_echo $BLUE "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { color_echo $RED "Failed to install Homebrew."; exit 1; }
else
    color_echo $GREEN "Homebrew already installed."
fi

# Step 3: Install Git (if not already installed by Xcode Command Line Tools)
if ! command -v git &>/dev/null; then
    color_echo $BLUE "Installing Git..."
    brew install git || { color_echo $RED "Failed to install Git."; exit 1; }
fi

# Step 4: Clone .dotfiles repository
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Dotfiles + BootStrap Repository Configuration -------------->"

echo "" # Print a blank line

DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    color_echo $BLUE "Cloning .dotfiles repository..."
    git clone "https://github.com/av1155/.dotfiles.git" "$DOTFILES_DIR" || \
        { color_echo $RED "Failed to clone .dotfiles repository."; exit 1; }
else
    color_echo $GREEN "The '.dotfiles' directory already exists. Skipping clone of repository."
fi

# Step 5: Install software from Brewfile
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Brewfile Configuration -------------->"

echo "" # Print a blank line

color_echo $BLUE "Installing software from Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile" || { color_echo $RED "Failed to install software from Brewfile."; exit 1; }

# Validate TMUX_CONFIG_DIR
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- tmux Config Directory Setup -------------->"

echo "" # Print a blank line

TMUX_CONFIG_DIR="$HOME/.config/tmux"
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    color_echo $BLUE "Creating tmux config directory..."
    mkdir -p "$TMUX_CONFIG_DIR"
else
    color_echo $GREEN "The tmux config directory already exists. Skipping configuration."
fi

# Step 6: Create symlinks (Idempotent) ----------------------------------------
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Symlinks Configuration -------------->"

echo "" # Print a blank line

color_echo $BLUE "Creating symlinks..."

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
}

# Symlinks go here:

# create_symlink "$DOTFILES_DIR/configs/.original_file" "$HOME/.linked_file"
create_symlink "$DOTFILES_DIR/configs/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/configs/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/configs/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Installation of of software -----------------------------------------------
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Installation of Software -------------->"

echo "" # Print a blank line

# Install iTerm2
if ! brew list --cask | grep -q iterm2 && [ ! -d "/Applications/iTerm.app" ]; then
    color_echo $BLUE "Installing iTerm2..."
    brew install --cask iterm2 || { color_echo $RED "Failed to install iTerm2."; exit 1; }
else
    color_echo $GREEN "iTerm2 already installed."
fi

# Install Docker
if ! brew list --cask | grep -q docker && [ ! -d "/Applications/Docker.app" ]; then
    color_echo $BLUE "Installing Docker..."
    brew install --cask docker || { color_echo $RED "Failed to install Docker."; exit 1; }
else
    color_echo $GREEN "Docker already installed."
fi

# Install Miniforge3
if [ ! -d "$HOME/miniforge3" ]; then
    color_echo $BLUE "Installing Miniforge3..."
    brew install miniforge || { color_echo $RED "Failed to install Miniforge3."; exit 1; }
else
    color_echo $GREEN "Miniforge3 already installed."
fi

# Install Google Chrome
if ! brew list --cask | grep -q google-chrome && [ ! -d "/Applications/Google Chrome.app" ]; then
    color_echo $BLUE "Installing Google Chrome..."
    brew install --cask google-chrome || { color_echo $RED "Failed to install Google Chrome."; exit 1; }
else
    color_echo $GREEN "Google Chrome already installed."
fi

# Install Visual Studio Code
if ! brew list --cask | grep -q visual-studio-code && [ ! -d "/Applications/Visual Studio Code.app" ]; then
    color_echo $BLUE "Installing Visual Studio Code..."
    brew install --cask visual-studio-code || { color_echo $RED "Failed to install Visual Studio Code."; exit 1; }
else
    color_echo $GREEN "Visual Studio Code already installed."
fi

# Install JetBrains Toolbox
if ! brew list --cask | grep -q jetbrains-toolbox && [ ! -d "/Applications/JetBrains Toolbox.app" ]; then
    color_echo $BLUE "Installing JetBrains Toolbox..."
    brew install --cask jetbrains-toolbox || { color_echo $RED "Failed to install JetBrains Toolbox."; exit 1; }
else
    color_echo $GREEN "JetBrains Toolbox already installed."
fi

# Install Ollama
if ! brew list | grep -q ollama && [ ! -d "/Applications/Ollama.app" ]; then
    color_echo $BLUE "Installing Ollama..."
    brew install ollama || { color_echo $RED "Failed to install Ollama."; exit 1; }
else
    color_echo $GREEN "Ollama already installed."
fi

# -----------------------------------------------------------------------------
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Configuration of NVM, NODE, & NPM -------------->"

echo "" # Print a blank line

# Check if NVM (Node Version Manager) is installed
if ! command -v nvm &>/dev/null; then
    # Install NVM if it's not installed
    color_echo $BLUE "Installing Node Version Manager (nvm)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash || { color_echo $RED "Failed to install nvm."; exit 1; }
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    color_echo $GREEN "NVM already installed."
fi

echo "" # Print a blank line

# Check if Node is installed
if ! command -v node &>/dev/null; then
    # Install Node.js using NVM if it's not installed
    color_echo $BLUE "Installing Node.js..."
    nvm install node || { color_echo $RED "Failed to install Node.js."; exit 1; }
else
    color_echo $GREEN "Node.js already installed."
fi

echo "" # Print a blank line

# Install Global npm Packages:
color_echo $BLUE "Installing global npm packages..."

color_echo $BLUE "tree-sitter-cli: "
npm install -g tree-sitter-cli || { color_echo $RED "Failed to install tree-sitter-cli."; exit 1; }

color_echo $BLUE "live-server: "
npm install -g live-server || { color_echo $RED "Failed to install live-server."; exit 1; }

# -----------------------------------------------------------------------------
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Configuration of Nerd Fonts -------------->"

echo "" # Print a blank line

# Install JetBrainsMono Nerd Font
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

# AstroNvim Installation ------------------------------------------------------
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- AstroNvim Configuration -------------->"

echo "" # Print a blank line

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

echo "" # Print a blank line

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
echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- TODO List of Apps to Download -------------->"

echo "" # Print a blank line

# Define the list of apps
app_list=(
    "zoom.us.app"
    "WhatsApp.app"
    "Warp.app"
    "TickTick.app"
    "The Unarchiver.app"
    "Spotify.app"
    "Shottr.app"
    "Ryujinx.app"
    "PS Remote Play.app"
    "OnyX.app"
    "OneMenu.app"
    "Ollama.app"
    "Notion.app"
    "MonitorControl.app"
    "MiddleClick.app"
    "Microsoft Word.app"
    "Microsoft Teams classic.app"
    "Microsoft PowerPoint.app"
    "Microsoft Outlook.app"
    "Microsoft OneNote.app"
    "Microsoft Excel.app"
    "Microsoft Edge.app"
    "Mathpix Snipping Tool.app"
    "Magnet.app"
    "Maccy.app"
    "LockDown Browser.app"
    "Latest.app"
    "IINA.app"
    "Grammarly for Safari.app"
    "Grammarly Desktop.app"
    "Goodnotes.app"
    "Flycut.app"
    "Encrypto.app"
    "Dropover.app"
    "Discord.app"
    "Color Picker.app"
    "CleanMyMac X.app"
    "Cinebench.app"
    "CheatSheet.app"
    "CalcBar.app"
    "BetterDisplay.app"
    "Bartender 5.app"
    "AppCleaner.app"
    "Anki.app"
    "AltTab.app"
    "Alfred 5.app"
    "AlDente.app"
    "1Password.app"
    "1Password for Safari.app"
    "1Blocker.app"
    "Adobe Creative Cloud"
)

# Create a text file on the desktop with the app list
desktop_path="$HOME/Desktop/apps_to_download.txt"
printf "%s\n" "${app_list[@]}" > "$desktop_path"

# Print a message to inform the user
color_echo $BLUE "A TODO list of apps to download has been created on your desktop: $desktop_path"

echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Thank You! -------------->"

echo "" # Print a blank line

color_echo $PURPLE "🚀 Installation successful! Your development environment is now supercharged and ready for lift-off. Please restart your computer to finalize the setup. Happy coding! 🚀"

# -----------------------------------------------------------------------------
