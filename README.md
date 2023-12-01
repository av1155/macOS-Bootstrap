# Dotfiles + BootStrap Repository

Welcome to my dotfiles repository! Here, you'll find configuration files
(dotfiles) for customizing my development environment and a robust script,
`mac_bootstrap.zsh`, designed to automate the entire setup of a new macOS
device. This script covers everything from installing Xcode Command Line Tools
to setting up your favorite apps, ensuring a streamlined and personalized
development experience.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This repository serves as a one-stop solution for setting up and customizing
your macOS development environment. It includes my personal dotfiles and the
`mac_bootstrap.zsh` script, which simplifies the setup process.

## Features

The `mac_bootstrap.zsh` script automates various setup tasks:

1. **Xcode Command Line Tools Installation**: Essential for development on
   macOS, this step ensures that compilers and Git are available on your
   machine.

2. **Repository Cloning**: Utilizes a smart cloning mechanism with SSH and HTTPS
   fallback, ensuring seamless repository access.

3. **Symlink Creation**: Sets up symbolic links for essential configuration
   files, linking them from the repository to your home directory for easy
   access and management.

4. **Homebrew Management**: Installs Homebrew if not already present and uses a
   Brewfile to manage software installations, keeping your environment
   consistent and up-to-date.

5. **AstroNvim Setup**: Integrates AstroNvim, a highly configurable Neovim
   distribution, with your user profile for an enhanced coding experience.

6. **User Interface Enhancements**: The script includes functions for displaying
   colorful and centered messages, adding a touch of personality to your
   terminal.

7. **To-Do List for App Downloads**: Generates a list of recommended
   applications to download, saved as a text file on your desktop for easy
   reference.

## Installation

Before running the script, ensure you have a stable internet connection and
administrative access on your macOS device.

### Usage

#### Option 1: Clone and Run

1. Clone this repository to your desired location by opening the terminal and
   running the following command:

   ```shell
   git clone https://github.com/av1155/.dotfiles.git
   ```

2. Navigate to the cloned directory:

   `cd .dotfiles`

3. Make the script executable:

   `chmod +x mac_bootstrap.zsh`

4. Execute the script:

   `./mac_bootstrap.zsh`

5. Follow any on-screen instructions to complete setup.

#### Option 2: Download and Run

1. Download the `mac_bootstrap.zsh` script from this repository.

2. Move the downloaded script to your home directory (~), you can use the mv
   command for this:

   ```shell
   mv ~/Downloads/mac_bootstrap.zsh ~/mac_bootstrap.zsh
   ```

3. Make the script executable:

   `chmod +x mac_bootstrap.zsh`

4. Execute the script:

   `./mac_bootstrap.zsh`

5. Follow any on-screen instructions to complete setup.

## Customization

Feel free to fork this repository and customize the dotfiles and script to match
your personal preferences and workflow.

## Troubleshooting

Encounter an issue? Here are some common problems and their solutions:

- **Script Fails to Clone Repositories**: Ensure your SSH keys are set up
  correctly or use HTTPS as a fallback.
- **Xcode Command Line Tools Installation Issues**: Check your internet
  connection and retry, or install manually from the Apple Developer website.

## Contributing

Contributions are welcome! If you have improvements, suggestions, or bug fixes,
please submit a Pull Request.

## License

This project is licensed under the MIT License - see the `LICENSE` file for
details. testingssh
