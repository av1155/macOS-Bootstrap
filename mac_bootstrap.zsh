#!/bin/zsh

# Define ANSI color escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No color (reset)

# Function to display colored messages
color_echo() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Script for bootstrapping a new MacBook for development.
# This script installs necessary tools and sets up symlinks for dotfiles.
# Assumptions: macOS with internet access and standard file system structure.
# Usage: Execute this script in a zsh shell.

# Step 1: Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    color_echo $RED "Installing Xcode Command Line Tools..."
    xcode-select --install || { color_echo $RED "Failed to install Xcode Command Line Tools."; exit 1; }
else
    color_echo $GREEN "Xcode Command Line Tools already installed."
fi

# Step 2: Install Homebrew and software from Brewfile
if ! command -v brew &>/dev/null; then
    color_echo $BLUE "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { color_echo $RED "Failed to install Homebrew."; exit 1; }
else
    color_echo $GREEN "Homebrew already installed."
fi

color_echo $BLUE "Installing software from Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile" || { color_echo $RED "Failed to install software from Brewfile."; exit 1; }

# -----------------------------------------------------------------------------

# Clone .dotfiles repository if it doesn't exist
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    color_echo $BLUE "Cloning .dotfiles repository..."
    git_clone_fallback "git@github.com:av1155/.dotfiles.git" "https://github.com/av1155/.dotfiles.git" "$DOTFILES_DIR" || \
        { color_echo $RED "Failed to clone .dotfiles repository."; exit 1; }
else
    color_echo $GREEN ".dotfiles directory already exists. Skipping clone."
fi

# Validate TMUX_CONFIG_DIR
TMUX_CONFIG_DIR="$HOME/.config/tmux"
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    color_echo $BLUE "Creating tmux config directory..."
    mkdir -p "$TMUX_CONFIG_DIR"
fi

# Step 3: Create symlinks (Idempotent) ----------------------------------------
color_echo $BLUE "Creating symlinks..."
create_symlink() {
    local source_file="$1"
    local target_file="$2"
    if [ -f "$target_file" ]; then
        color_echo $BLUE "Backing up existing $(basename "$target_file") to $(basename "$target_file").bak"
        mv "$target_file" "${target_file}.bak" || { color_echo $RED "Failed to backup $target_file"; exit 1; }
    fi
    ln -sf "$source_file" "$target_file" || { color_echo $RED "Failed to create symlink for $(basename "$source_file")"; exit 1; }
}

create_symlink "$DOTFILES_DIR/configs/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/configs/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/configs/tmux.conf" "$HOME/.config/tmux/tmux.conf"

color_echo $GREEN "Symlinks created."

# -----------------------------------------------------------------------------

# Install iTerm2
if ! brew list --cask | grep -q iterm2; then
    color_echo $BLUE "Installing iTerm2..."
    brew install --cask iterm2 || { color_echo $RED "Failed to install iTerm2."; exit 1; }
else
    color_echo $GREEN "iTerm2 already installed."
fi

# Install Docker
if ! command -v docker &>/dev/null; then
    color_echo $BLUE "Installing Docker..."
    brew install --cask docker || { color_echo $RED "Failed to install Docker."; exit 1; }
else
    color_echo $GREEN "Docker already installed."
fi

# Install Miniforge3
if ! command -v conda &>/dev/null; then
    color_echo $BLUE "Installing Miniforge3..."
    brew install miniforge || { color_echo $RED "Failed to install Miniforge3."; exit 1; }
else
    color_echo $GREEN "Miniforge3 already installed."
fi

# Install Google Chrome
if ! brew list --cask | grep -q google-chrome; then
    color_echo $BLUE "Installing Google Chrome..."
    brew install --cask google-chrome || { color_echo $RED "Failed to install Google Chrome."; exit 1; }
else
    color_echo $GREEN "Google Chrome already installed."
fi

# -----------------------------------------------------------------------------

# Install NVM (Node Version Manager)
color_echo $BLUE "Installing Node Version Manager (nvm)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash || { color_echo $RED "Failed to install nvm."; exit 1; }
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js using NVM
color_echo $BLUE "Installing Node.js..."
nvm install node || { color_echo $RED "Failed to install Node.js."; exit 1; }

# Install Global npm Packages:
color_echo $BLUE "Installing global npm packages..."
npm install -g tree-sitter-cli || { color_echo $RED "Failed to install tree-sitter-cli."; exit 1; }
npm install -g live-server || { color_echo $RED "Failed to install live-server."; exit 1; }

# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------

# Install AstroNvim
color_echo $BLUE "Installing AstroNvim..."
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
[ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
[ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
[ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"

# Attempt to clone using SSH, fallback to HTTPS if SSH fails
git_clone_fallback() {
    local ssh_url="$1"
    local https_url="$2"
    local clone_directory="$3"
    git clone "$ssh_url" "$clone_directory" || git clone "$https_url" "$clone_directory" || { color_echo $RED "Failed to clone repository."; exit 1; }
}

# Install AstroNvim user configuration
git_clone_fallback "git@github.com:av1155/astronvim_config.git" "https://github.com/av1155/astronvim_config.git" "$HOME/.config/nvim/lua/user"
color_echo $GREEN "AstroNvim installation complete."

# -----------------------------------------------------------------------------

# Change to the home directory
cd "$HOME"

# Source the Zsh configuration to apply changes
source ~/.zshrc
