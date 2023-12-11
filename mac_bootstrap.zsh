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

    # Function to extract file and its immediate parent directory
    get_file_and_parent() {
        local full_path=$1
        echo "$(basename "$(dirname "$full_path")")/$(basename "$full_path")"
    }

    local source_display="$(get_file_and_parent "$source_file")"
    local target_display="$(get_file_and_parent "$target_file")"

    if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        color_echo $GREEN "Symlink for ${PURPLE}$source_display${GREEN} already exists and is correct."
        return
    fi

    if [ -f "$target_file" ]; then
        color_echo $YELLOW "Existing file found for ${PURPLE}$target_display${YELLOW}. Do you want to overwrite it? (y/n)"
        echo -n "Enter choice: > "
        read -r choice
        case "$choice" in
            y|Y )
                color_echo $BLUE "Backing up existing ${PURPLE}$target_display${BLUE} as ${PURPLE}${target_display}.bak${BLUE}"
                mv "$target_file" "${target_file}.bak" || { color_echo $RED "Failed to backup $target_file"; exit 1; }
                ;;
            n|N )
                color_echo $GREEN "Skipping ${PURPLE}$target_display${GREEN}."
                return
                ;;
            * )
                color_echo $RED "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi

    mkdir -p "$(dirname "$target_file")"

    ln -sf "$source_file" "$target_file" || { color_echo $RED "Failed to create symlink for ${PURPLE}$source_display${RED}"; exit 1; }

    # Display this message only when a symlink is created.
    color_echo $GREEN "Created symlink for ${PURPLE}$source_display${GREEN} to ${PURPLE}$target_display${GREEN}."
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


    # Check if Neovim is installed or the directory exists
    if command -v nvim &>/dev/null || [ -d "$HOME/nvim-macos" ]; then
        color_echo $GREEN "Neovim already installed."
    else
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

# Install Rectangle
install_app "Rectangle" "brew install --cask rectangle" "! brew list rectangle &>/dev/null"

# Install Zplug
install_app "Zplug" "brew install zplug" "! brew list zplug &>/dev/null"

# Install iTerm2
install_app "iTerm2" "brew install --cask iterm2" "! brew list --cask | grep -q iterm2 && [ ! -d '/Applications/iTerm.app' ]"

# Install Google Chrome
install_app "Google Chrome" "brew install --cask google-chrome" "! brew list --cask | grep -q google-chrome && [ ! -d '/Applications/Google Chrome.app' ]"

# Install Visual Studio Code
install_app "Visual Studio Code" "brew install --cask visual-studio-code" "! brew list --cask | grep -q visual-studio-code && [ ! -d '/Applications/Visual Studio Code.app' ]"

# Install JetBrains Toolbox
install_app "JetBrains Toolbox" "brew install --cask jetbrains-toolbox" "! brew list --cask | grep -q jetbrains-toolbox && [ ! -d '/Applications/JetBrains Toolbox.app' ]"

# After Oh My Zsh installation, insert a reminder to run the script again
echo "Once Oh My Zsh has been installed, rerun the script to finish the setup process."

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

# Step 5: Clone scripts repository -------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Scripts Repository Configuration -------------->"

echo ""

# Check if the "scripts" repository already exists in the specified directory
SCRIPTS_REPO_DIRECTORY="$HOME/scripts"
if [ -d "$SCRIPTS_REPO_DIRECTORY" ]; then
    color_echo $GREEN "The scripts repository already exists in '$SCRIPTS_REPO_DIRECTORY'."
else
    # Ask the user if they want to clone the "scripts" repository
    color_echo $YELLOW "The scripts repository does not exist in '$SCRIPTS_REPO_DIRECTORY'."
    color_echo $YELLOW "Do you want to clone the scripts repository? (y/n)"
    echo -n "Enter choice: > "
    read -r scripts_clone_choice
    if [ "$scripts_clone_choice" = "y" ] || [ "$scripts_clone_choice" = "Y" ]; then
        git_clone_fallback "git@github.com:av1155/scripts.git" "https://github.com/av1155/scripts.git" "$SCRIPTS_REPO_DIRECTORY"
    else
        color_echo $GREEN "Skipping scripts repository cloning."
    fi
fi

# Step 6: Clone .dotfiles repository -------------------------------------------

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

# Step 7: Install software from Brewfile ---------------------------------------

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

# Step 8: Create symlinks (Idempotent) ----------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Symlinks Configuration -------------->"

echo ""

color_echo $BLUE "Creating symlinks..."

# Symlinks go here:
# create_symlink "$DOTFILES_DIR/configs/.original_file" "$HOME/.linked_file"
create_symlink "$DOTFILES_DIR/configs/formatting_files/.clang-format" "$HOME/.clang-format"
create_symlink "$DOTFILES_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/configs/git/.gitignore_global" "$HOME/.gitignore_global"
create_symlink "$DOTFILES_DIR/configs/intelliJ_IDEA/.ideavimrc" "$HOME/.ideavimrc"
create_symlink "$DOTFILES_DIR/configs/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
create_symlink "$DOTFILES_DIR/configs/neofetch/config.conf" "$HOME/.config/neofetch/config.conf"
create_symlink "$DOTFILES_DIR/configs/ssh/config" "$HOME/.ssh/config"
create_symlink "$DOTFILES_DIR/configs/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
create_symlink "$DOTFILES_DIR/configs/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
create_symlink "$DOTFILES_DIR/configs/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
create_symlink "$DOTFILES_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/configs/zsh/starship.toml" "$HOME/.config/starship.toml"
create_symlink "/opt/homebrew/bin/gdu-go" "/opt/homebrew/bin/gdu"

# Step 9: Install NVM, Node.js, & npm -----------------------------------------

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

# Check and install neovim
if ! npm list -g neovim &>/dev/null; then
    color_echo $BLUE " * neovim: "
    npm install -g neovim || { color_echo $RED "Failed to install neovim."; exit 1; }
else
    color_echo $GREEN " * neovim already installed."
fi

# Step 10: Install JetBrainsMono Nerd Font ------------------------------------

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

# Step 11: Configure Neovim with AstroNvim -----------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- AstroNvim Configuration -------------->"

echo ""

color_echo $BLUE "Installing AstroNvim..."
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

color_echo $BLUE "Installing AstroNvim user configuration..."
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

# Step 12: Install AstroNvim Dependencies ------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- AstroNvim Dependencies Configuration -------------->"

echo ""

# PYNVIM SETUP -------------------------------->

# Determine the architecture (Intel or Apple Silicon)
arch_name="$(uname -m)"
if [ "$arch_name" = "x86_64" ]; then
    # Intel Macs
    PYTHON_PATH="/usr/local/miniforge3/bin/python3"
elif [ "$arch_name" = "arm64" ]; then
    # Apple Silicon Macs
    PYTHON_PATH="/opt/homebrew/Caskroom/miniforge/base/bin/python3"
else
    color_echo $RED "Unknown architecture: $arch_name"
    exit 1
fi

# Python AstroNvim dependencies
if ! $PYTHON_PATH -c "import pynvim" &>/dev/null; then
    color_echo $YELLOW " * pynvim not installed, installing..."
    $PYTHON_PATH -m pip install pynvim || { color_echo $RED "Failed to install pynvim."; exit 1; }
else
    color_echo $GREEN " * pynvim already installed."
fi

# END OF PYNVIM SETUP <<<

# PERL NEONVIM EXTENSION SETUP -------------------------------->

# Check if Perl is installed via Homebrew and install if necessary
if brew list perl &>/dev/null; then
    color_echo $GREEN " * Perl is already installed."
else
    color_echo $YELLOW " * Installing Perl..."
    brew install perl || { color_echo $RED "Failed to install Perl."; exit 1; }
fi

# Check and Configure local::lib
if [ -d "$HOME/perl5/lib/perl5" ] && grep -q 'perl5' <<< "$PERL5LIB"; then
    color_echo $GREEN " * local::lib is already configured."
else
    color_echo $YELLOW " * Configuring local::lib..."
    PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib || { color_echo $RED "Failed to configure local::lib."; exit 1; }
fi

# Check if cpanm is installed via Homebrew and install if necessary
if brew list cpanminus &>/dev/null; then
    color_echo $GREEN " * cpanm is already installed."
else
    color_echo $YELLOW " * Installing cpanm..."
    brew install cpanminus || { color_echo $RED "Failed to install cpanminus."; exit 1; }
fi

# Check if Neovim::Ext is installed and install if necessary
if perl -MNeovim::Ext -e 1 &>/dev/null; then
    color_echo $GREEN " * Neovim::Ext is already installed."
else
    color_echo $YELLOW " * Installing Neovim::Ext..."
    cpanm Neovim::Ext || { color_echo $RED "Failed to install Neovim::Ext."; exit 1; }
fi

# END OF PERL NEONVIM EXTENSION SETUP <<<

# RUBY ASTRONVIM SETUP -------------------------------->

color_echo $YELLOW " * Checking Ruby installation..."

# Determine the architecture (Intel or Apple Silicon)
arch_name="$(uname -m)"

# Determine the path of the current Ruby executable
current_ruby_path=$(which ruby)

# Determine the path of the gem executable
gem_executable=$(which gem)

if [ "$arch_name" = "arm64" ]; then
    # Apple Silicon Macs
    expected_ruby_path="/opt/homebrew/opt/ruby/bin/ruby"
elif [ "$arch_name" = "x86_64" ]; then
    # Intel Macs
    expected_ruby_path="/usr/local/opt/ruby/bin/ruby"
else
    color_echo $RED "Unknown architecture: $arch_name"
    exit 1
fi

# Check if the current Ruby is the expected Ruby based on architecture
if [[ "$current_ruby_path" == "$expected_ruby_path" ]]; then
    color_echo $YELLOW " * Ruby installed via Homebrew, installing neovim gem..."
    # Check if the neovim gem is already installed
    if gem list -i neovim > /dev/null 2>&1; then
        color_echo $GREEN " * Neovim gem already installed."
    else
        color_echo $YELLOW " * Installing neovim gem..."
        $gem_executable install neovim || { color_echo $RED "Failed to install neovim gem."; exit 1; }
    fi
else
    color_echo $GREEN " * Non-Homebrew Ruby detected. Please ensure Ruby from Homebrew is correctly set up."
fi

# END OF RUBY ASTRONVIM SETUP <<<

echo ""
echo -n " ${GREEN}*${NC} "
# Install colorls
install_app "colorls" "gem install colorls" "! gem list colorls -i &>/dev/null"

# Install Composer for PHP development ---------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Composer Installation for PHP Development -------------->"

echo ""

# Verify if Composer is already installed
if command -v composer >/dev/null 2>&1; then
    color_echo $GREEN " * Composer is already installed."
else
    # Download and verify Composer
    color_echo $YELLOW " * Downloading and verifying Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"

    # Move Composer to a global directory
    color_echo $YELLOW " * Moving Composer to global directory..."
    sudo mv composer.phar /usr/local/bin/composer || { color_echo $RED "Failed to move Composer."; exit 1; }

    # Verify Composer installation
    color_echo $YELLOW " * Verifying Composer installation..."
    composer --version || { color_echo $RED "Composer installation failed."; exit 1; }

    color_echo $GREEN " * Composer installed successfully."
fi

# Step 13: Create TODO List of Apps to Download -------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- TODO List of Apps to Download -------------->"

echo ""

# Define the list of apps
app_list=(
    "Bartender 5.app"
    "CalcBar.app"
    "CleanMyMac X.app"
    "Color Picker.app"
    "Dropover.app"
    "Encrypto.app"
    "Goodnotes.app"
    "Grammarly for Safari.app"
    "1Blocker.app"
    "1Password for Safari.app"
    "LockDown Browser.app"
    "Magnet.app"
    "OneMenu.app"
    "Ryujinx.app"
)

# Define the path of the text file
desktop_path="$HOME/Desktop/apps_to_download.txt"

# Check if the file already exists
if [ ! -f "$desktop_path" ]; then
    # File does not exist, create the file and write the app list
    printf "%s\n" "${app_list[@]}" > "$desktop_path"
    # Print a message to inform the user
    color_echo $BLUE "A TODO list of apps to download has been created on your desktop: $desktop_path"
else
    # File already exists, print a different message
    color_echo $RED "The file already exists on your desktop: $desktop_path"
fi

# -----------------------------------------------------------------------------

echo "" # Print a blank line

centered_color_echo $ORANGE "<-------------- Thank You! -------------->"

echo "" # Print a blank line

color_echo $PURPLE "🚀 Installation successful! Your development environment is now supercharged and ready for lift-off. Please restart your computer to finalize the setup. Happy coding! 🚀"

# -----------------------------------------------------------------------------
