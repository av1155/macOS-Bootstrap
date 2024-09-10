# <---------------------- .ZSHRC FILE --------------------->

# <-------------------- POWERLEVEL10K -------------------->

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# <-------------------- HOMEBREW DYNAMIC PATH DETECTION -------------------->

if command -v brew >/dev/null 2>&1; then
    HOMEBREW_PATH=$(brew --prefix)
fi


# <-------------------- CONDA (Python) INITIALIZATION -------------------->

# Set the Conda executable path based on HOMEBREW_PATH
CONDA_EXEC_PATH="$HOMEBREW_PATH/Caskroom/miniforge/base/bin/conda"

# Initialize Conda
if [ -f "$CONDA_EXEC_PATH" ]; then
    __conda_setup="$("$CONDA_EXEC_PATH" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        CONDA_SH_PATH="$HOMEBREW_PATH/Caskroom/miniforge/base/etc/profile.d/conda.sh"
        if [ -f "$CONDA_SH_PATH" ]; then
            . "$CONDA_SH_PATH"
        else
            export PATH="$HOMEBREW_PATH/Caskroom/miniforge/base/bin:$PATH"
        fi
    fi
else
    echo "Conda executable not found at $CONDA_EXEC_PATH"
fi

unset __conda_setup

# <<< END CONDA INITIALIZATION


# <------------------ NVIM PYTHON PATH CONFIGURATION ------------------>

# Check if Conda is installed
if command -v conda >/dev/null 2>&1; then
    # Conda-specific configuration

    # Function to set NVIM_PYTHON_PATH
    set_python_path_for_neovim() {
        if [[ -n "$CONDA_PREFIX" ]]; then
            export NVIM_PYTHON_PATH="$CONDA_PREFIX/bin/python"
        else
            # Fallback to system Python (Python 3) if Conda is not active
            local system_python_path=$(which python3)
            if [[ -z "$system_python_path" ]]; then
                echo "Python is not installed. Please install Python to use with Neovim."
            else
                export NVIM_PYTHON_PATH="$system_python_path"
            fi
        fi
    }

    # Initialize NVIM_PYTHON_PATH
    set_python_path_for_neovim

    # Hook into the precmd function
    function precmd_set_python_path() {
        if [[ "$PREV_CONDA_PREFIX" != "$CONDA_PREFIX" ]]; then
            set_python_path_for_neovim
            PREV_CONDA_PREFIX="$CONDA_PREFIX"
        fi
    }

    # Save the initial Conda prefix
    PREV_CONDA_PREFIX="$CONDA_PREFIX"

    # Add the hook to precmd
    autoload -U add-zsh-hook
    add-zsh-hook precmd precmd_set_python_path

else
    # Non-Conda environment: Check if Python is installed
    python_path=$(which python3)
    if [[ -z "$python_path" ]]; then
        echo "Python is not installed. Please install Python to use with Neovim."
    else
        export NVIM_PYTHON_PATH="$python_path"
    fi
fi

# Add the following line in `~/.config/nvim/lua/user/options.lua` to set the dynamic Python executable for pynvim
# python3_host_prog = "$NVIM_PYTHON_PATH",


# <-------------------- NVM INITIALIZATION -------------------->

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Commented out as not needed for Zsh


# <==================== CS50 Library Configuration ====================>

# Setting up environment variables for the CS50 library
export LIBRARY_PATH=~/cs50lib
export C_INCLUDE_PATH=~/cs50lib
export LD_LIBRARY_PATH=~/cs50lib   # For Linux systems
export DYLD_LIBRARY_PATH=~/cs50lib # For macOS systems


# <==================== PRETTIER CONFIGURATION ====================>

export PRETTIERD_DEFAULT_CONFIG=~/.dotfiles/configs/formatting_files/.prettierrc.json


# <-------------------- CUSTOM FUNCTIONS -------------------->

# fcd: A function to interactively navigate directories using find, fzf, and colorls.
# This script allows you to visually search and select directories within a specified depth
# and then directly change to the selected directory. It uses 'find' to list directories,
# 'fzf' for interactive selection, and 'colorls' to preview directories with color coding.

if command -v fd &>/dev/null && command -v fzf &>/dev/null && command -v colorls &>/dev/null; then
    fcd() {
        local depth="${1:-9}"  # Default depth is 9, but can be overridden by first argument
        local dir
        dir=$(fd --type d --hidden --max-depth "$depth"\
            --exclude '.git' \
            --exclude 'Photos' \
            --exclude '.local' \
            --exclude 'node_modules' \
            --exclude 'venv' \
            --exclude 'env' \
            --exclude '.venv' \
            --exclude 'build' \
            --exclude 'dist' \
            --exclude 'cache' \
            --exclude '.cache' \
            --exclude 'tmp' \
            --exclude '.tmp' \
            --exclude 'temp' \
            --exclude '.temp' \
            --exclude 'Trash' \
            --exclude '.Trash' \
            . 2>/dev/null | fzf --preview 'eza --tree --level 2 --color=always {}' +m) && z "$dir" || return
    }
fi


# list: A versatile function for listing and executing categorized aliases from the .zshrc file.
# This script enables you to choose from different categories of aliases.
# and interactively select an alias to execute. It simplifies the process of remembering and
# typing complex aliases and provides an easy way to browse and use them.

CATEGORY_LIST=("tmux" "colorls" "git" "forecast" "weather")

# Enhanced list function for managing and executing categorized aliases.
list() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is required for this function to work."
        return 1
    fi

    if [[ $# -ne 1 ]] || [[ ! " ${CATEGORY_LIST[*]} " =~ " $1 " ]]; then
        echo "Usage: list [category]"
        echo "Available categories:"
        for category in "${CATEGORY_LIST[@]}"; do
            echo "* $category"
        done
        return 1
    fi

    local selected=$(grep "alias.*$1" ~/.zshrc | fzf +m --height 60% --reverse)
    if [[ -n $selected ]]; then
        local cmd=$(echo "$selected" | sed 's/alias \([^=]*\)="\(.*\)"/\2/')
        eval "$cmd"
    fi
}


# <---------------- OMZ PATH, THEMES, AND ZPLUG ------------------>

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# ZSH THEME -------------------------------------------------------> (ZSH theme configuration: off) -> Default theme = robbyrussell
ZSH_THEME=""
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# POWERLEVEL10K ---------------------------------------------------> (P10K theme configuration: off)
# source ~/powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# STARSHIP --------------------------------------------------------> (Starship theme configuration: off)
# eval "$(starship init zsh)"

# ZPLUG + Pure ----------------------------------------------------> (Pure prompt configuration: on)

# Set ZPLUG_HOME using HOMEBREW_PATH
export ZPLUG_HOME="$HOMEBREW_PATH/opt/zplug"

# Check if Zplug is installed
if [ -d "$ZPLUG_HOME" ]; then

    # Rest of the Zplug configuration
    source $ZPLUG_HOME/init.zsh
    zplug "mafredri/zsh-async", from:github
    # Pure Prompt Configuration
    zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme # Pure prompt configuration: on (comment out line for off)
    # zplug "zdharma/fast-syntax-highlighting", as:plugin, defer:2
    zplug "zsh-users/zsh-autosuggestions", as:plugin, defer:2
    zplug load

    if ! zplug check --verbose; then
        printf "Install? [y/N]: "
        if read -q; then
            echo; zplug install
        fi
    fi

    # Pure prompt Git configurations:
    zstyle :prompt:pure:git:stash show yes                        # Show git stash status in prompt

fi


# <-------------------- ZSH CONFIGURATION -------------------->

# Theme Configuration
# Random theme selection from specified list (only when ZSH_THEME=random)
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Completion Behavior
# Case-sensitive completion
# CASE_SENSITIVE="true"
# Hyphen-insensitive completion (requires CASE_SENSITIVE off)
# HYPHEN_INSENSITIVE="true"

# Auto-update Settings
# zstyle ':omz:update' mode disabled                              # Disable automatic updates
zstyle ':omz:update' mode auto                                    # Enable automatic updates without prompt
# zstyle ':omz:update' mode reminder                              # Reminder for manual updates

# Update Frequency (in days)
# zstyle ':omz:update' frequency 13

# Terminal Functionality
# DISABLE_MAGIC_FUNCTIONS="true"                                  # Fix issues with pasting text
# DISABLE_LS_COLORS="true"                                        # Disable colors in ls
# DISABLE_AUTO_TITLE="true"                                       # Disable auto-setting terminal title
# ENABLE_CORRECTION="true"                                        # Enable command auto-correction
# COMPLETION_WAITING_DOTS="true"                                  # Show red dots during completion

# Repository Status
# DISABLE_UNTRACKED_FILES_DIRTY="true"                            # Speed up repo status in large repositories

# History Timestamps
# HIST_STAMPS="mm/dd/yyyy"                                        # Set history timestamps format

# Custom Folder
# ZSH_CUSTOM=/path/to/new-custom-folder                           # Custom folder for Zsh configurations

# Plugins
plugins=(
    git
    # zsh-autosuggestions
    web-search
    zsh-syntax-highlighting
    kitty
    direnv
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User Configuration
# export MANPATH="/usr/local/man:$MANPATH"
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'                                          # Editor for SSH sessions
# else
#   export EDITOR='mvim'                                         # Default editor for local sessions
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# <-------------------- CUSTOM ALIASES -------------------->

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# source ~/powerlevel10k/powerlevel10k.zsh-theme

# Check if Git is installed
if command -v git &>/dev/null; then

    # Staging and Committing
    alias ga="git add"                                           # Stage all changes
    alias gap="git add -p"                                       # Stage changes interactively
    alias gcm="git commit -m"                                    # Commit with a message
    alias gra="git commit --amend --reset-author --no-edit"      # Amend the last commit without changing its message
    alias unwip="git reset HEAD~"                                # Undo the last commit but keep changes
    alias uncommit="git reset HEAD~ --hard"                      # Undo the last commit and discard changes

    # Branch and Merge
    alias gco="git checkout"                                     # Switch branches or restore working tree files
    alias gpfwl="git push --force-with-lease"                    # Force push with lease for safety
    alias gprune="git branch --merged main | grep -v '^[ *]*main\$' | xargs git branch -d" # Delete branches merged into main

    # Repository Status and Inspection
    alias gs="git status"                                        # Show the working tree status
    alias gl="git lg"                                            # Show commit logs in a graph format
    alias glo="git log --oneline"                                # Show commit logs in a single line each
    alias glt="git describe --tags --abbrev=0"                   # Describe the latest tag

    # Remote Operations
    alias gpr="git pull -r"                                      # Pull with rebase
    alias gup="gco main && gpr && gco -"                         # Update the current branch with changes from main

    # Stashing
    alias hangon="git stash save -u"                             # Stash changes including untracked files
    alias gsp="git stash pop"                                    # Apply stashed changes and remove them from the stash

    # Cleanup
    alias gclean="git clean -df"                                 # Remove untracked files and directories
    alias cleanstate="unwip && git checkout . && git clean -df"  # Undo last commit, revert changes, and clean untracked files

    # Other Aliases
    alias pear="git pair "                                       # Set up git pair for pair programming (requires git-pair gem)
    alias rspec_units="rspec --exclude-pattern \"**/features/*_spec.rb\"" # Run RSpec tests excluding feature specs
    alias awsume=". awsume sso;. awsume"                         # Alias for AWS role assumption

fi

# Check if Tmux is installed
if command -v tmux &>/dev/null; then

    # Tmux Aliases
    alias ta="tmux attach -t"                                    # Attaches tmux to a session (example: ta portal)
    alias tn="tmux new-session -s "                              # Creates a new session
    alias tk="tmux kill-session -t "                             # Kill session
    alias tl="tmux list-sessions"                                # Lists all ongoing sessions
    alias td="tmux detach"                                       # Detach from session
    alias tc="clear; tmux clear-history; clear"                  # Tmux Clear pane

fi


# Check if colorls is installed
if command -v colorls &>/dev/null; then

    alias ls="colorls -A --gs --sd"                              # Lists most files, directories first, with git status.
    alias la="colorls -oA --sd --gs"                             # Full listing of all files, directories first, with git status.
    alias lf="colorls -foa --sd --gs"                            # File-only listing, directories first, with git status.
    alias lt="colorls --tree=3 --sd --gs --hyperlink"            # Tree view of directories with git status and hyperlinks.

fi

# Alias for Neovim
if command -v "$HOMEBREW_PATH/bin/nvim" &>/dev/null; then
    alias vim="nvim"
elif [ -f ~/nvim-macos/bin/nvim ]; then
    alias vim="~/nvim-macos/bin/nvim"
fi

# Fuzzy Finder + Nvim Custom Alias
# Searches files with 'fd', previews with 'bat', and opens in 'nvim' via 'fzf'.
command -v fd &>/dev/null && command -v fzf &>/dev/null && \
    command -v bat &>/dev/null && command -v nvim &>/dev/null && \
    alias f="fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {1}' | xargs nvim"

# Sourced + Aliased Scripts ------------------------------------------------------->
[ -f ~/scripts/scripts/JavaProjectManager/JavaProjectManager.zsh ] && alias jcrt="~/scripts/scripts/JavaProjectManager/JavaProjectManager.zsh"
[ -f ~/scripts/scripts/sqlurl.sh ] && alias sqlurl="~/scripts/scripts/sqlurl.sh"
[ -f ~/scripts/scripts/nvim_surround_usage.sh ] && alias nvs="~/scripts/scripts/nvim_surround_usage.sh"
[ -f ~/scripts/scripts/package_updater.zsh ] && alias upall="~/scripts/scripts/package_updater.zsh"
[ -f ~/scripts/scripts/html-to-text.zsh ] && alias h2t="~/scripts/scripts/html-to-text.zsh"

# GPA Calculator
if [ -d "$HOME/Developer/DevPlayground/GitHubProjects/GPA-Calculator" ] && command -v node >/dev/null 2>&1; then
    alias gpa="node $HOME/Developer/DevPlayground/GitHubProjects/GPA-Calculator/index.js"
elif [ -d "$HOME/Developer/DevPlayground/GitHubProjects/GPA-Calculator" ]; then
    echo "GPA Calculator directory found, but Node.js is not installed."
else
    echo "GPA Calculator directory does not exist."
fi

# End of Sourced + Aliased Scripts ------------------------------------------------>

# Weather
alias wf="curl \"https://wttr.in/Coral+Gables?1&F&Q\""
alias ww="curl \"https://wttr.in/Coral+Gables?format=2\""


# <-------------------- FZF INITIALIZATION -------------------->
# Source fzf if available
[[ -f $HOME/.fzf.zsh ]] && source $HOME/.fzf.zsh

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# --- setup fzf theme ---
fg="#CBE0F0"            # Foreground color
bg="#011628"            # Background color [UNUSED]
bg_highlight="#143652"  # Background highlight color [UNUSED]
purple="#B388FF"        # Purple color for highlights
blue="#06BCE4"          # Blue color for info
cyan="#2CF9ED"          # Cyan color for various elements


# Set default FZF options
export FZF_DEFAULT_OPTS="-m --height 70% --border --extended --layout=reverse --color=fg:${fg},hl:${purple},fg+:${fg},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# https://github.com/junegunn/fzf-git.sh
source ~/fzf-git.sh/fzf-git.sh

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"


# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

# ----- Bat (better cat) -----
export BAT_THEME="Catppuccin Macchiato"

# ---- TheFuck -----

# thefuck alias
eval $(thefuck --alias)
eval $(thefuck --alias fk)

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

alias cd="z"

# ---- Lazygit ----

alias lg="lazygit"


# <-------------------- NEOFETCH INITIALIZATION -------------------->

# command -v neofetch &>/dev/null && neofetch


# <----------------- CUSTOM ENVIRONMENT VARIABLES ------------------>

export EDITOR='nvim'


# <--------------- HEROKU AUTOCOMPLETE INITIALIZATION -------------->

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=/Users/andreaventi/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;


# <-------------------- ITERM2 SHELL INTEGRATION ------------------->

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# <------------------- GH COPILOT INITIALIZATION ------------------->

eval "$(gh copilot alias -- zsh)"


# <-------------------- CUSTOM PATHS -------------------->

PATH=~/.console-ninja/.bin:$PATH


# <-------------------- JAVA CLASSPATH CONFIGURATION -------------------->

# Define the base directory where the jars are stored
CLASSPATH_PREFIX="/Users/andreaventi/.dotfiles/configs/javaClasspath"

# Clear existing java classpath entries
export CLASSPATH=""

# Add each jar file found in the directory and its subdirectories to the CLASSPATH
for jar in $(find "$CLASSPATH_PREFIX" -name '*.jar'); do
  export CLASSPATH="$CLASSPATH:$jar"
done


# <-------------------- END OF .ZSHRC FILE -------------------->
