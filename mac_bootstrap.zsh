#!/bin/zsh

# Script for bootstrapping a new MacBook for development.
# This script installs necessary tools and sets up symlinks for dotfiles.
# Assumptions: macOS with internet access and standard file system structure.
# Usage: Execute this script in a zsh shell.

# Clone .dotfiles repository if it doesn't exist
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning .dotfiles repository..."
    git clone git@github.com:av1155/.dotfiles.git "$DOTFILES_DIR" || \
        git clone https://github.com/av1155/.dotfiles.git "$DOTFILES_DIR" || \
        { echo "Failed to clone .dotfiles repository."; exit 1; }
else
    echo ".dotfiles directory already exists. Skipping clone."
fi

# Validate TMUX_CONFIG_DIR
TMUX_CONFIG_DIR="$HOME/.config/tmux"
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    echo "Creating tmux config directory..."
    mkdir -p "$TMUX_CONFIG_DIR"
fi

# Step 1: Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || { echo "Failed to install Xcode Command Line Tools."; exit 1; }
else
    echo "Xcode Command Line Tools already installed."
fi

# Step 2: Create symlinks (Idempotent)
echo "Creating symlinks..."
create_symlink() {
    local source_file="$1"
    local target_file="$2"
    if [ -f "$target_file" ]; then
        echo "Backing up existing $(basename "$target_file") to $(basename "$target_file").bak"
        mv "$target_file" "${target_file}.bak" || { echo "Failed to backup $target_file"; exit 1; }
    fi
    ln -sf "$source_file" "$target_file" || { echo "Failed to create symlink for $(basename "$source_file")"; exit 1; }
}
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"

# Step 3: Install Homebrew and software from Brewfile
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Failed to install Homebrew."; exit 1; }
else
    echo "Homebrew already installed."
fi

echo "Installing software from Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile" || { echo "Failed to install software from Brewfile."; exit 1; }

# Conditional installation of iTerm2
if ! brew list --cask | grep -q iterm2; then
    echo "Installing iTerm2..."
    brew install --cask iterm2 || { echo "Failed to install iTerm2."; exit 1; }
else
    echo "iTerm2 already installed."
fi

# Install NVM, Node.js, and tree-sitter-cli
echo "Installing Node Version Manager (nvm), Node.js, and tree-sitter-cli..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash || { echo "Failed to install nvm."; exit 1; }
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install node || { echo "Failed to install Node.js."; exit 1; }
npm install -g tree-sitter-cli || { echo "Failed to install tree-sitter-cli."; exit 1; }
echo "Node.js and tree-sitter-cli installation complete."

# Install JetBrainsMono Nerd Font
echo "Installing JetBrainsMono Nerd Font..."
FONT_DIR="$HOME/Library/Fonts"
if [ ! -d "$FONT_DIR" ]; then
    echo "Creating font directory..."
    mkdir -p "$FONT_DIR"
fi
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip -o "$FONT_DIR/JetBrainsMono.zip" || { echo "Failed to download JetBrainsMono Nerd Font."; exit 1; }
unzip "$FONT_DIR/JetBrainsMono.zip" -d "$FONT_DIR" || { echo "Failed to unzip JetBrainsMono Nerd Font."; exit 1; }
rm "$FONT_DIR/JetBrainsMono.zip"
echo "JetBrainsMono Nerd Font installation complete."

# Install AstroNvim
echo "Installing AstroNvim..."
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
[ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
[ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
[ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"

# Attempt to clone using SSH, fallback to HTTPS if SSH fails
git_clone_fallback() {
    local ssh_url="$1"
    local https_url="$2"
    local clone_directory="$3"
    git clone "$ssh_url" "$clone_directory" || git clone "$https_url" "$clone_directory" || { echo "Failed to clone repository."; exit 1; }
}

git_clone_fallback "git@github.com:av1155/astronvim_config.git" "https://github.com/av1155/astronvim_config.git" "$HOME/.config/nvim/lua/user"
echo "AstroNvim installation complete."
