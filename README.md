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

1. Install Apple's Command Line Tools, which are prerequisites for Git and
   Homebrew. The `mac_bootstrap.zsh` script automates this step.
2. Clone the repo into a new hidden directory. The script also handles cloning
   the dotfiles repository into the `$HOME/.dotfiles` directory. It will either
   clone the repository or skip ahead if it has already been cloned.
3. Create symlinks in the Home directory to the real files in the repo. The
   script manages the creation of symlinks in an idempotent manner.
4. Install Homebrew and software from Brewfile. The script will install Homebrew
   if it is not already installed and then use a Brewfile to manage software
   installation.
5. Set Up AstroNvim with User Profile. The script sets up AstroNvim, a modern
   and extensible Neovim configuration, and integrates it with my user profile,
   ensuring a seamless development experience in Neovim..

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
