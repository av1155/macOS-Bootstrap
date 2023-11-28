# Dotfiles Repository

Welcome to my dotfiles repository! Here, you'll find the configuration files
(dotfiles) for customizing my development environment. These dotfiles are
tailored to enhance productivity, streamline workflows, and provide a
personalized development experience.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)

## Steps to bootstrap a new Mac

1. Install Apple's Command Line Tools, which are prerequisites for Git and
   Homebrew.

```zsh
xcode-select --install
```

2. Clone repo into new hidden directory.

```zsh
# Use SSH (if set up)...
git clone git@github.com:av1155/.dotfiles.git ~/.dotfiles

# ...or use HTTPS and switch remotes later.
git clone https://github.com/av1155/.dotfiles.git ~/.dotfiles
```

3. Create symlinks in the Home directory to the real files in the repo.

```zsh
# Navigate to the .dotfiles directory
cd ~/.dotfiles

# Make the script executable
chmod +x setup_mac.sh

# Run the script
./setup_mac.sh
```

### Usage

Once the dotfiles are installed, you can start using them in your development
environment. Feel free to explore and modify the configurations based on your
preferences.

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
