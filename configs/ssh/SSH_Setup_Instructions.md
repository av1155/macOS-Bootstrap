# SSH Setup Instructions

This document provides step-by-step instructions for setting up SSH keys and
configuring SSH for new devices using the .dotfiles repository.

## Step 1: Import the SSH Private Key

1. Securely transfer the `id_ed25519` file to the new computer.
2. Place the file in the ~/.ssh directory.

## Step 2: Set Correct Permissions for the SSH Key

Set the file permissions for the private key to ensure security:

```bash
chmod 600 ~/.ssh/id_ed25519
```

## Step 3: Run Setup Scripts from .dotfiles

Execute `mac_bootstrap.zsh` from the .dotfiles repository to configure your
environment and create a symbolic link for the SSH config file.

## Step 4: Start SSH Agent and Add Your SSH Key

Start the SSH agent and add your SSH key:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

You will be prompted to enter the passphrase for your SSH key.

```bash
ssh-add -l
```

## Step 5: Test SSH Connection

Test your SSH setup, for example, with GitHub:

```bash
ssh -T git@github.com
```

You should receive a message confirming successful authentication.

## Step 6: Update SSH Key in Services

If necessary, update your SSH public key (id_ed25519.pub) in services like
GitHub or GitLab.

## Step 7: Final Testing

Perform operations that require SSH (e.g., Git operations) to ensure everything
is configured correctly.

### Notes:

- These instructions assume a Unix-like environment (Linux, macOS).
