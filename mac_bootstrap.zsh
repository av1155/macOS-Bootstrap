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
	local padding_length=$(((terminal_width - text_width) / 2))
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
	git clone "$ssh_url" "$clone_directory" || git clone "$https_url" "$clone_directory" || {
		color_echo $RED "Failed to clone repository."
		exit 1
	}
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
		y | Y)
			color_echo $BLUE "Backing up existing ${PURPLE}$target_display${BLUE} as ${PURPLE}${target_display}.bak${BLUE}"
			mv "$target_file" "${target_file}.bak" || {
				color_echo $RED "Failed to backup $target_file"
				exit 1
			}
			;;
		n | N)
			color_echo $GREEN "Skipping ${PURPLE}$target_display${GREEN}."
			return
			;;
		*)
			color_echo $RED "Invalid choice. Exiting."
			exit 1
			;;
		esac
	fi

	mkdir -p "$(dirname "$target_file")"

	ln -sf "$source_file" "$target_file" || {
		color_echo $RED "Failed to create symlink for ${PURPLE}$source_display${RED}"
		exit 1
	}

	# Display this message only when a symlink is created.
	color_echo $GREEN "Created symlink for ${PURPLE}$source_display${GREEN} to ${PURPLE}$target_display${GREEN}."
}

# Function to prompt and install an app
# Arguments: app_name, install_command, check_command
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
			eval "$install_command" || {
				color_echo $RED "Failed to install $app_name."
				exit 1
			}
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
			brew install gettext || {
				color_echo $RED "Failed to install dependencies for Neovim."
				exit 1
			}

			# Download Neovim
			color_echo $BLUE "Downloading Neovim..."
			curl -LO $nvim_url || {
				color_echo $RED "Failed to download Neovim."
				exit 1
			}

			# Remove "unknown developer" warning
			color_echo $BLUE "Removing 'unknown developer' warning from Neovim tarball..."
			xattr -c $nvim_tarball

			# Extract Neovim
			color_echo $BLUE "Extracting Neovim..."
			tar xzf $nvim_tarball || {
				color_echo $RED "Failed to extract Neovim."
				exit 1
			}

			# Remove the tarball and extracted directory
			rm -f $nvim_tarball

			color_echo $GREEN "Neovim installed successfully."
		else
			color_echo $BLUE "Skipping Neovim installation."
		fi
	fi

}

# END OF FUNCTIONS ------------------------------------------------------------

# Step 1: Install Homebrew ----------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Homebrew Configuration -------------->"

echo ""

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
	color_echo $BLUE "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
		color_echo $RED "Failed to install Homebrew."
		exit 1
	}

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
	echo "eval \"$($HOMEBREW_BIN shellenv)\"" >>$HOME/.zprofile
	eval "$($HOMEBREW_BIN shellenv)"

	# Homebrew will prompt for Xcode Command Line Tools installation if necessary
else
	color_echo $GREEN "Homebrew already installed, updating..."
	brew update && brew upgrade || {
		color_echo $RED "Failed to update Homebrew."
		exit 1
	}
fi

# Step 2: Install Git (if not already installed by Xcode Command Line Tools) ---
if ! command -v git &>/dev/null; then
	color_echo $BLUE "Installing Git..."
	brew install git || {
		color_echo $RED "Failed to install Git."
		exit 1
	}
fi

# Step 3: Installation of software --------------------------------------------

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
color_echo $YELLOW "Once Oh My Zsh has been installed, rerun the script to finish the setup process."

# Install Oh My Zsh
install_app "Oh My Zsh" "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"" "[ ! -d '$HOME/.oh-my-zsh' ]"

# Check if Oh My Zsh is installed before attempting to install zsh-syntax-highlighting
if [ -d "$HOME/.oh-my-zsh" ]; then
	# Install zsh-syntax-highlighting plugin
	if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
		color_echo $BLUE "Installing zsh-syntax-highlighting plugin..."
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || {
			color_echo $RED "Failed to clone zsh-syntax-highlighting."
			exit 1
		}
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

# Install Java
# Determine the architecture of the macOS system
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
	# Intel architecture (x86_64)
	JDK_URL="https://download.oracle.com/java/22/latest/jdk-22_macos-x64_bin.tar.gz"
elif [ "$ARCH" = "arm64" ]; then
	# ARM architecture (Apple Silicon)
	JDK_URL="https://download.oracle.com/java/22/latest/jdk-22_macos-aarch64_bin.tar.gz"
else
	color_echo $RED "Unsupported architecture: $ARCH"
	exit 1
fi

# Define the download and extraction location
DOWNLOAD_LOCATION="$HOME/Downloads"
EXTRACT_LOCATION="$DOWNLOAD_LOCATION/jdk_extract"

# Create a directory to extract the tarball
mkdir -p "$EXTRACT_LOCATION"

# Download the tar.gz file to the extraction directory
color_echo $YELLOW "Downloading and extracting JDK..."
curl -L $JDK_URL | tar -xz -C "$EXTRACT_LOCATION"

# Determine the name of the top-level directory in the extracted location
JDK_DIR_NAME=$(ls "$EXTRACT_LOCATION" | grep 'jdk')

# Check if this directory already exists in the target directory
if [ ! -d "$HOME/Library/Java/JavaVirtualMachines/$JDK_DIR_NAME" ]; then
	color_echo $GREEN "Installing Java..."
	# Move the JDK directory to the Java Virtual Machines directory
	mv "$EXTRACT_LOCATION/$JDK_DIR_NAME" "$HOME/Library/Java/JavaVirtualMachines/"
	color_echo $GREEN "Java installed successfully."
else
	color_echo $BLUE "Java is already installed. No action taken."
	# Remove the extracted JDK if already installed
	rm -rf "$EXTRACT_LOCATION/$JDK_DIR_NAME"
fi

# Remove the extraction directory if empty
rmdir "$EXTRACT_LOCATION"

# Step 4: Clone scripts repository -------------------------------------------

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

# Step 5: Clone .dotfiles repository -------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Dotfiles + BootStrap Repository Configuration -------------->"

echo ""

DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
	color_echo $BLUE "Cloning .dotfiles repository..."
	git clone "https://github.com/av1155/.dotfiles.git" "$DOTFILES_DIR" ||
		{
			color_echo $RED "Failed to clone .dotfiles repository."
			exit 1
		}
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
	brew bundle --file "$DOTFILES_DIR/Brewfile" || {
		color_echo $RED "Failed to install software from Brewfile."
		exit 1
	}
	color_echo $GREEN "Brewfile installation complete."
fi

echo ""
# Install Neovim if Brewfile installation was unsuccessful
install_neovim

# Step 7: Create symlinks (Idempotent) ----------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Symlinks Configuration -------------->"

echo ""

color_echo $BLUE "Creating symlinks..."

# Symlinks go here:
# create_symlink "$DOTFILES_DIR/configs/.original_file" "$HOME/.linked_file"
create_symlink "$DOTFILES_DIR/configs/colorls" "$HOME/.config/colorls"
create_symlink "$DOTFILES_DIR/configs/cs50lib" "$HOME/cs50lib"
create_symlink "$DOTFILES_DIR/configs/formatting_files/.clang-format" "$HOME/.clang-format"
create_symlink "$DOTFILES_DIR/configs/formatting_files/.prettierrc.json" "$HOME/.config/.prettierrc.json"
create_symlink "$DOTFILES_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/configs/git/.gitignore_global" "$HOME/.gitignore_global"
create_symlink "$DOTFILES_DIR/configs/intelliJ_IDEA/.ideavimrc" "$HOME/.ideavimrc"
create_symlink "$DOTFILES_DIR/configs/kitty" "$HOME/.config/kitty"
create_symlink "$DOTFILES_DIR/configs/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
create_symlink "$DOTFILES_DIR/configs/neofetch/config.conf" "$HOME/.config/neofetch/config.conf"
create_symlink "$DOTFILES_DIR/configs/ssh/config" "$HOME/.ssh/config"
create_symlink "$DOTFILES_DIR/configs/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
create_symlink "$DOTFILES_DIR/configs/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
create_symlink "$DOTFILES_DIR/configs/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
create_symlink "$DOTFILES_DIR/configs/zsh/.zprofile" "$HOME/.zprofile"
create_symlink "$DOTFILES_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/configs/zsh/starship.toml" "$HOME/.config/starship.toml"
create_symlink "$DOTFILES_DIR/configs/zsh/fzf-git.sh" "$HOME/fzf-git.sh"
create_symlink "$DOTFILES_DIR/configs/zsh/bat-themes" "$HOME/.config/bat/themes"
create_symlink "/opt/homebrew/bin/gdu-go" "/opt/homebrew/bin/gdu"

# Step 8: Install NVM, Node.js, & npm -----------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Configuration of NVM, NODE, & NPM -------------->"

echo ""

# Check if NVM (Node Version Manager) is installed ----------------------------
if [ ! -d "$HOME/.nvm" ]; then
	# Install NVM if it's not installed
	color_echo $BLUE "Installing Node Version Manager (nvm)..."
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || {
		color_echo $RED "Failed to install nvm."
		exit 1
	}

	# Run the following to use it in the same shell session:
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

else
	color_echo $GREEN "NVM already installed, visit 'https://github.com/nvm-sh/nvm#installing-and-updating' to update to the latest version."

	# Run the following to use it in the same shell session:
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

fi

echo ""

# Check if Node is installed --------------------------------------------------
if ! command -v node &>/dev/null; then
	# Install Node.js using NVM if it's not installed
	color_echo $BLUE "Installing Node.js..."
	nvm install node || {
		color_echo $RED "Failed to install Node.js."
		exit 1
	}
else
	color_echo $GREEN "Node.js already installed, checking for updates..."

	# Get the current version of Node.js
	CURRENT_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

	# Get the latest LTS Node.js version and strip ANSI escape codes
	LATEST_LTS_VERSION=$(nvm ls-remote --lts | tail -1 | awk '{ print $2 }' | sed 's/\x1b\[[0-9;]*m//g')

	# Debug: Print versions for checking
	echo "Current Node version:${PURPLE} ${CURRENT_NODE_VERSION} ${NC}"
	echo "Latest LTS version:${PURPLE} ${LATEST_LTS_VERSION} ${NC}"

	if [ "$CURRENT_NODE_VERSION" != "$LATEST_LTS_VERSION" ]; then
		# Install the latest LTS Node.js version and reinstall packages from the current version
		nvm install --lts --reinstall-packages-from="$CURRENT_NODE_VERSION" || {
			color_echo $RED "Failed to update Node.js."
			exit 1
		}

		# Switch to the latest Node.js version
		nvm use --lts || {
			color_echo $RED "Failed to switch to the latest Node.js version."
			exit 1
		}

		# Check the new current version after update
		NEW_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

		# Uninstall the old version if it's different from the new version
		if [ "$NEW_NODE_VERSION" != "$CURRENT_NODE_VERSION" ]; then
			color_echo $BLUE "Uninstalling the old version of Node.js ${PURPLE}${CURRENT_NODE_VERSION}${NC}..."
			nvm uninstall "$CURRENT_NODE_VERSION" || {
				color_echo $RED "Failed to uninstall the old version of Node.js."
				exit 1
			}
		fi

	else
		color_echo $YELLOW "Already on the latest LTS version of Node.js."
	fi

	# Prompt for updating global npm packages
	color_echo $YELLOW "Do you want to update global npm packages? (y/n)"
	echo -n "Enter choice: > "
	read -r update_choice
	if [ "$update_choice" = "y" ]; then
		color_echo $GREEN "Updating global npm packages..."
		npm update -g || {
			color_echo $RED "Failed to update global npm packages."
			exit 1
		}
	else
		color_echo $BLUE "Skipping global npm package updates."
	fi

	color_echo $GREEN "Node.js is up to date."
fi

echo ""

# Install Global npm Packages: ------------------------------------------------
color_echo $BLUE "Installing global npm packages..."

# Check and install tree-sitter-cli
if ! npm list -g tree-sitter-cli &>/dev/null; then
	color_echo $BLUE " * Installing tree-sitter-cli..."
	npm install -g tree-sitter-cli || {
		color_echo $YELLOW "Regular installation failed. Attempting with --force..."
		npm install -g tree-sitter-cli --force || {
			color_echo $RED "Failed to install tree-sitter-cli."
			exit 1
		}
	}
else
	color_echo $GREEN " * tree-sitter-cli already installed."
fi

# Check and install live-server
if ! npm list -g live-server &>/dev/null; then
	color_echo $BLUE " * Installing live-server..."
	npm install -g live-server || {
		color_echo $YELLOW "Regular installation failed. Attempting with --force..."
		npm install -g live-server --force || {
			color_echo $RED "Failed to install live-server."
			exit 1
		}
	}
else
	color_echo $GREEN " * live-server already installed."
fi

# Check and install neovim
if ! npm list -g neovim &>/dev/null; then
	color_echo $BLUE " * Installing neovim..."
	npm install -g neovim || {
		color_echo $YELLOW "Regular installation failed. Attempting with --force..."
		npm install -g neovim --force || {
			color_echo $RED "Failed to install neovim."
			exit 1
		}
	}
else
	color_echo $GREEN " * neovim already installed."
fi

# Check and install TypeScript
if ! npm list -g typescript &>/dev/null; then
	color_echo $BLUE " * Installing TypeScript..."
	npm install -g typescript || {
		color_echo $YELLOW "Regular installation failed. Attempting with --force..."
		npm install -g typescript --force || {
			color_echo $RED "Failed to install TypeScript."
			exit 1
		}
	}
else
	color_echo $GREEN " * TypeScript already installed."
fi

# Step 9: Install Nerd Font --------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Configuration of Nerd Fonts -------------->"

echo ""

# JetBrainsMonoNerdFont-Regular.ttf
# FiraCodeNerdFont-Regular.ttf

FONT_NAME="JetBrainsMono"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$FONT_NAME.zip"
FONT_DIR="$HOME/Library/Fonts"
FONT_FILE="$FONT_DIR/${FONT_NAME}NerdFont-Regular.ttf"

# Check if the font is already installed
if [ -f "$FONT_FILE" ]; then
	color_echo $GREEN "$FONT_NAME Nerd Font is already installed."
else
	# Confirmation prompt for font installation
	color_echo $YELLOW "Do you want to proceed installing $FONT_NAME Nerd Font? (y/n)"
	echo -n "Enter choice: > "
	read -r font_confirmation
	if [ "$font_confirmation" != "y" ] && [ "$font_confirmation" != "Y" ]; then
		color_echo $RED "Font installation aborted."
	else
		color_echo $BLUE "Installing $FONT_NAME Nerd Font..."
		if [ ! -d "$FONT_DIR" ]; then
			color_echo $BLUE "Creating font directory..."
			mkdir -p "$FONT_DIR"
		fi
		curl -L $FONT_URL -o "$FONT_DIR/$FONT_NAME.zip" || {
			color_echo $RED "Failed to download $FONT_NAME Nerd Font."
			exit 1
		}
		unzip "$FONT_DIR/$FONT_NAME.zip" -d "$FONT_DIR" || {
			color_echo $RED "Failed to unzip $FONT_NAME Nerd Font."
			exit 1
		}
		rm "$FONT_DIR/$FONT_NAME.zip"
		color_echo $GREEN "$FONT_NAME Nerd Font installation complete."
	fi
fi

# Step 10: Install AstroNvim Dependencies ------------------------------------

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
	$PYTHON_PATH -m pip install pynvim || {
		color_echo $RED "Failed to install pynvim."
		exit 1
	}
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
	brew install perl || {
		color_echo $RED "Failed to install Perl."
		exit 1
	}
fi

# Check and Configure local::lib
if [ -d "$HOME/perl5/lib/perl5" ] && grep -q 'perl5' <<<"$PERL5LIB"; then
	color_echo $GREEN " * local::lib is already configured."
else
	color_echo $YELLOW " * Configuring local::lib..."
	PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib || {
		color_echo $RED "Failed to configure local::lib."
		exit 1
	}
fi

# Check if cpanm is installed via Homebrew and install if necessary
if brew list cpanminus &>/dev/null; then
	color_echo $GREEN " * cpanm is already installed."
else
	color_echo $YELLOW " * Installing cpanm..."
	brew install cpanminus || {
		color_echo $RED "Failed to install cpanminus."
		exit 1
	}
fi

# Check if Neovim::Ext is installed and install if necessary
if perl -MNeovim::Ext -e 1 &>/dev/null; then
	color_echo $GREEN " * Neovim::Ext is already installed."
else
	color_echo $YELLOW " * Installing Neovim::Ext..."
	cpanm Neovim::Ext || {
		color_echo $RED "Failed to install Neovim::Ext."
		exit 1
	}
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
	if gem list -i neovim >/dev/null 2>&1; then
		color_echo $GREEN " * Neovim gem already installed."
	else
		color_echo $YELLOW " * Installing neovim gem..."
		$gem_executable install neovim || {
			color_echo $RED "Failed to install neovim gem."
			exit 1
		}
	fi
else
	color_echo $GREEN " * Non-Homebrew Ruby detected. Please ensure Ruby from Homebrew is correctly set up."
fi

echo -n " ${GREEN}*${NC} "
# Install colorls
install_app "colorls" "gem install colorls" "gem list colorls -i &>/dev/null"

# Verify Lua 5.1 and LuaRocks are installed
if command -v lua5.1 &>/dev/null && command -v luarocks &>/dev/null; then
	color_echo $GREEN " * Lua 5.1 and LuaRocks are installed."

	# Install Magick LuaRock
	color_echo $YELLOW " * Installing Magick LuaRock..."
	luarocks --local --lua-version=5.1 install magick || {
		color_echo $RED "Failed to install Magick LuaRock."
		exit 1
	}

	color_echo $GREEN " * Magick LuaRock installed successfully."
else
	color_echo $RED " * Lua 5.1 or LuaRocks is not installed. Please install Lua 5.1 and LuaRocks first."
fi

# END OF RUBY ASTRONVIM SETUP <<<

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
	sudo mv composer.phar /usr/local/bin/composer || {
		color_echo $RED "Failed to move Composer."
		exit 1
	}

	# Verify Composer installation
	color_echo $YELLOW " * Verifying Composer installation..."
	composer --version || {
		color_echo $RED "Composer installation failed."
		exit 1
	}

	color_echo $GREEN " * Composer installed successfully."
fi

# NeoVim-Configuration ---------------------------------------------------------

echo ""

centered_color_echo $ORANGE "<-------------- Setting Up AstroNvim v4+ -------------->"

echo ""

# Check if the Neovim configuration directory exists
if [ -d "$HOME/.config/nvim" ]; then
	color_echo $YELLOW "An existing Neovim configuration has been detected."
	color_echo $YELLOW "Do you want to replace the current Neovim configuration? (y/n)${NC}"
	echo -n "Enter choice: > "
	read -r keep_conf

	if [ "$keep_conf" != "y" ] || [ "$keep_conf" != "Y" ]; then
		color_echo $GREEN "Keeping the existing configuration. No changes made."

	else
		# Backing up existing Neovim configurations
		color_echo $BLUE "Backing up existing Neovim configurations..."
		mv ~/.config/nvim ~/.config/nvim.bak
		mv ~/.local/share/nvim ~/.local/share/nvim.bak
		mv ~/.local/state/nvim ~/.local/state/nvim.bak
		mv ~/.cache/nvim ~/.cache/nvim.bak
		color_echo $GREEN "Backup completed."

		# Cloning the new configuration repository
		color_echo $BLUE "Cloning the new AstroNvim configuration..."
		git clone git@github.com:av1155/NeoVim-Configuration.git ~/.config/nvim
		color_echo $GREEN "Clone completed."
	fi
else
	color_echo $GREEN "No existing Neovim configuration found. Proceeding with setup..."

	# Cloning the new configuration repository
	color_echo $BLUE "Cloning the new AstroNvim configuration..."
	git clone git@github.com:av1155/NeoVim-Configuration.git ~/.config/nvim
	color_echo $GREEN "Clone completed."
fi

# Check if Neovim is installed
if command -v nvim &>/dev/null; then
	color_echo $GREEN "Neovim is installed. Running Neovim in headless mode to initialize..."

	# Start Neovim in headless mode and then exit
	nvim --headless -c 'quitall'
	color_echo $GREEN "Neovim has been initialized in headless mode."
else
	color_echo $YELLOW "Neovim is not installed. Please install Neovim to proceed."
fi

# Step 12: Create TODO List of Apps to Download -------------------------------

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
	printf "%s\n" "${app_list[@]}" >"$desktop_path"
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
