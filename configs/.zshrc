# <---------------------- ZSHRC FILE --------------------->

# <-------------------- POWERLEVEL10K -------------------->

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# <------------------ JAVA_HOME CONFIGURATION ------------------>

# Set JAVA_HOME for Java
export JAVA_HOME="$(/usr/libexec/java_home)"

# <-------------------- CUSTOM SCRIPTS -------------------->

if command -v find &>/dev/null && command -v fzf &>/dev/null; then
    fcd() {
        local dir
        dir=$(find * -type d 2>/dev/null | fzf +m) && cd "$dir" || return
    }
fi

# <-------------------- PATH AND ZPLUG -------------------->

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"

# Commented out to disable Powerlevel10k and use Pure prompt (in other lines of code)
# source ~/powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Detect the architecture (Intel x86_64 or Apple Silicon arm64)
arch_name="$(uname -m)"

if [ "$arch_name" = "x86_64" ]; then
    # If Intel, set ZPLUG_HOME to the Intel Homebrew path
    export ZPLUG_HOME="/usr/local/opt/zplug"
elif [ "$arch_name" = "arm64" ]; then
    # If Apple Silicon, set ZPLUG_HOME to the Apple Silicon Homebrew path
    export ZPLUG_HOME="/opt/homebrew/opt/zplug"
fi

# Check if Zplug is installed
if [ -d "$ZPLUG_HOME" ]; then

    # Rest of the Zplug configuration
    source $ZPLUG_HOME/init.zsh
    zplug "mafredri/zsh-async", from:github
    # Pure Prompt Configuration
    zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
    # zplug "zdharma/fast-syntax-highlighting", as:plugin, defer:2
    zplug "zsh-users/zsh-autosuggestions", as:plugin, defer:2
    zplug load

    if ! zplug check --verbose; then
        printf "Install? [y/N]: "
        if read -q; then
            echo; zplug install
        fi
    fi

    # Pure prompt Git configurations
    zstyle :prompt:pure:git:stash show yes

fi

# <-------------------- ZSH CONFIGURATION -------------------->

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

plugins=(
    git
    # zsh-autosuggestions
    web-search
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# <-------------------- CUSTOM ALIASES -------------------->

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Alias for improved ls with colorls:
if command -v colorls &>/dev/null; then
    alias ls='colorls'
fi

# Alias for Neovim:
if command -v /opt/homebrew/bin/nvim &>/dev/null; then
    alias vim='nvim'  # If Neovim installed via Homebrew on Apple Silicon
elif [ -f ~/nvim-macos/bin/nvim ]; then
    alias vim='~/nvim-macos/bin/nvim'  # If Neovim installed in the home directory
fi

# Fuzzy Finder + Nvim Custom Alias:
if command -v fd &>/dev/null && command -v fzf &>/dev/null && command -v bat &>/dev/null && command -v nvim &>/dev/null; then
    alias f="fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {1}' | xargs nvim"
fi

# SOURCED SCRIPTS + ALIASES:
[ -f ~/scripts/JavaProject.zsh ] && { source ~/scripts/JavaProject.zsh; alias jp="javaproject"; }
[ -f ~/scripts/JavaCompiler.zsh ] && source ~/scripts/JavaCompiler.zsh

# <-------------------- CONDA INITIALIZATION -------------------->

# Determine the architecture of the machine
ARCH=$(uname -m)

# CONDA INITIALIZATION >>>

# For ARM architecture (e.g., Apple M1/M2 chips)
if [ "$ARCH" = "arm64" ]; then
    # ARM-specific Conda initialization
    __conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
        fi
    fi

    # For Intel x86_64 architecture
elif [ "$ARCH" = "x86_64" ]; then
    # Intel-specific Conda initialization
    __conda_setup="$('/usr/local/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/usr/local/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
            . "/usr/local/Caskroom/miniforge/base/etc/profile.d/conda.sh"
        else
            export PATH="/usr/local/Caskroom/miniforge/base/bin:$PATH"
        fi
    fi

    # If architecture is neither arm64 nor x86_64
else
    echo "Unsupported architecture: $ARCH"
fi

unset __conda_setup

# <<< END CONDA INITIALIZATION

# <-------------------- NVM INITIALIZATION -------------------->

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# <-------------------- FZF INITIALIZATION -------------------->

[[ -f $HOME/.fzf.zsh ]] && source $HOME/.fzf.zsh

# <-------------------- AUTOJUMP INITIALIZATION -------------------->

arch_name=$(uname -m)
if [ "$arch_name" = "x86_64" ]; then
    # Intel architecture
    [ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
elif [ "$arch_name" = "arm64" ]; then
    # ARM architecture (Apple Silicon)
    [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
else
    echo "Unknown architecture: $arch_name"
fi

# <-------------------- ITERM2 SHELL INTEGRATION ------------------->

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# <-------------------- END OF ZSHRC FILE -------------------->
