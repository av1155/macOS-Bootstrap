# <---------------------- ZSHRC FILE --------------------->

# <-------------------- POWERLEVEL10K -------------------->

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# <-------------------- ARCHITECTURE DETECTION -------------------->

# Determine the architecture and set the Homebrew path accordingly
ARCH=$(uname -m)

if [ "$ARCH" = "arm64" ]; then
    # ARM architecture (Apple Silicon)
    HOMEBREW_PATH="/opt/homebrew"
elif [ "$ARCH" = "x86_64" ]; then
    # Intel architecture
    HOMEBREW_PATH="/usr/local"
else
    echo "Unknown architecture: $ARCH"
    # Set a default or exit
    HOMEBREW_PATH="/usr/local" # default for unknown architecture
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

# <----------------- PATH, THEMES, AND ZPLUG ------------------->


# PATH --------------->

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# ZSH THEME ---------------> (ZSH theme configuration: off)
ZSH_THEME=""
# Default theme = robbyrussell

# POWERLEVEL10K ---------------> (P10K theme configuration: off)
# source ~/powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# STARSHIP ---------------> (Starship theme configuration: off)
# eval "$(starship init zsh)"

# ZPLUG + Pure ---------------> (Pure prompt configuration: on)

# Set ZPLUG_HOME using HOMEBREW_PATH
export ZPLUG_HOME="$HOMEBREW_PATH/opt/zplug"

# Check if Zplug is installed
if [ -d "$ZPLUG_HOME" ]; then

    # Rest of the Zplug configuration
    source $ZPLUG_HOME/init.zsh
    zplug "mafredri/zsh-async", from:github
    # Pure Prompt Configuration
    zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme # Pure prompt configuration: on
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

# Alias for improved ls with colorls
command -v colorls &>/dev/null && alias ls='colorls'

# Initialize Perl local::lib environment
# To set this up on a new machine:
# 1. Install Perl via Homebrew: `brew install perl`
# 2. Install local::lib, run this command on the terminal: `PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib`
# 3. Add the following line to the shell profile to configure the environment
if [ -d "$HOME/perl5/lib/perl5" ] && command -v perl &>/dev/null; then
    eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
fi

# Add Ruby gem user install directory to PATH
# To set this up on a new machine:
# 1. Install Ruby gems in the user directory: `gem install --user-install <gem_name>`
# 2. Find the user gem bin directory, run on the terminal: `gem env | grep USER`
# 3. Add the user gem bin directory to PATH in the shell profile
if [ -d "$HOME/.gem/ruby/2.6.0/bin" ]; then
    export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
fi

# Alias for Neovim
if command -v "$HOMEBREW_PATH/bin/nvim" &>/dev/null; then
    alias vim='nvim'
elif [ -f ~/nvim-macos/bin/nvim ]; then
    alias vim='~/nvim-macos/bin/nvim'
fi

# Fuzzy Finder + Nvim Custom Alias
command -v fd &>/dev/null && command -v fzf &>/dev/null && \
    command -v bat &>/dev/null && command -v nvim &>/dev/null && \
    alias f="fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {1}' | xargs nvim"

# Sourced Scripts
[ -f ~/scripts/JavaProject.zsh ] && { source ~/scripts/JavaProject.zsh; alias jp="javaproject"; }
[ -f ~/scripts/JavaCompiler/JavaCompiler.zsh ] && source ~/scripts/JavaCompiler/JavaCompiler.zsh

# <-------------------- CONDA INITIALIZATION -------------------->

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

# <-------------------- NVM INITIALIZATION -------------------->

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Commented out as not needed for Zsh

# <-------------------- FZF INITIALIZATION -------------------->

[[ -f $HOME/.fzf.zsh ]] && source $HOME/.fzf.zsh

# <-------------------- AUTOJUMP INITIALIZATION -------------------->

# Initialize Autojump using HOMEBREW_PATH
if [ -f "$HOMEBREW_PATH/etc/profile.d/autojump.sh" ]; then
    . "$HOMEBREW_PATH/etc/profile.d/autojump.sh"
else
    echo "Autojump initialization file not found"
fi

# <-------------------- NEOFETCH INITIALIZATION -------------------->

command -v neofetch &>/dev/null && neofetch

# <-------------------- ITERM2 SHELL INTEGRATION ------------------->

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# <-------------------- END OF ZSHRC FILE -------------------->
