# Dotfiles + BootStrap Repository

Welcome to my dotfiles repository! Here, you'll find the configuration files
(dotfiles) for customizing my development environment. These dotfiles are
tailored to enhance productivity, streamline workflows, and provide a
personalized development experience. Additionally, this repository also has an
installation script called mac_bootstrap.zsh that automates the entire setup of
a new Mac OS device, making it easy to get started with my recommended
configuration files.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)

## Steps to bootstrap a new Mac

1. **Install Apple's Command Line Tools**: These are prerequisites for Git and
   Homebrew. The `mac_bootstrap.zsh` script automates this step.

2. **Clone the Dotfiles Repository**: The script handles cloning the dotfiles
   repository into the `$HOME/.dotfiles` directory. If the repository is already
   cloned, this step is skipped.

   ```zsh
   git clone git@github.com:yourusername/.dotfiles.git ~/.dotfiles
   # or use HTTPS
   git clone https://github.com/yourusername/.dotfiles.git ~/.dotfiles
   ```

3. **Create Symlinks to Configuration Files**: The script creates symlinks in
   the Home directory to the real files located in the `configs` subdirectory
   within the `.dotfiles` repository. This is done in an idempotent manner,
   ensuring that running the script multiple times doesn’t create duplicate
   links.

   ```zsh
   create_symlink "$DOTFILES_DIR/configs/.zshrc" "$HOME/.zshrc"
   create_symlink "$DOTFILES_DIR/configs/.gitconfig" "$HOME/.gitconfig"
   create_symlink "$DOTFILES_DIR/configs/tmux.conf" "$HOME/.config/tmux/tmux.conf"
   ```

4. **Install Homebrew and Software from Brewfile**: The script installs Homebrew
   if it's not already installed. It then uses the `Brewfile` located in the
   repository to install and manage software.

5. **Set Up AstroNvim with User Profile**: The script sets up AstroNvim, an
   extensible Neovim configuration. It integrates AstroNvim with the user
   profile for a seamless development experience in Neovim.

### Usage

Run the `mac_bootstrap.zsh` script to set up your development environment. This
script automates the installation of the necessary tools and configurations
based on the contents of this repository.

```zsh
# Navigate to the cloned .dotfiles directory
cd ~/.dotfiles

# Make the script executable
chmod +x mac_bootstrap.zsh

# Run the script
./mac_bootstrap.zsh
```

### Customization

These dotfiles are designed to be customizable. You can make changes to suit
your specific needs. Feel free to fork this repository and adapt the
configurations to your liking.

### Contributing

Contributions are welcome! If you have improvements, suggestions, or bug fixes,
please submit a Pull Request. Let's make these dotfiles even better together.

### License

This project is licensed under the MIT License - see the `LICENSE` file for
details.

```
```
