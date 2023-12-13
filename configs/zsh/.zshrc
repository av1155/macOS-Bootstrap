# <---------------------- ZSHRC FILE --------------------->

# <-------------------- POWERLEVEL10K -------------------->

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# <-------------------- HOMEBREW PATH DETECTION -------------------->

if command -v brew >/dev/null 2>&1; then
    HOMEBREW_PATH=$(brew --prefix)
fi


# <------------------ PATH CONFIGURATION ------------------>
# Check if Homebrew is installed
if command -v brew >/dev/null 2>&1; then

    # HOMEBREW
    export PATH="$(brew --prefix)/bin:$PATH"

    # GIT
    export PATH="$(brew --prefix git)/bin:$PATH"

    # DOTNET
    export PATH="$(brew --prefix dotnet)/bin:$PATH"

    # RUBY
    export PATH="$(brew --prefix ruby)/bin:$PATH"

    # GO
    export PATH="$(brew --prefix go)/bin:$PATH"

    # JULIA
    export PATH="$(brew --prefix julia)/bin:$PATH"

    # COURSIER (Scala)
    export PATH="$(brew --prefix coursier)/bin:$PATH"

fi

# JAVA
export JAVA_HOME="$(/usr/libexec/java_home)"
export PATH=$JAVA_HOME/bin:$PATH

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


# <-------------------- PERL & RUBY INITIALIZATION -------------------->

# Initialize Perl local::lib environment ------------------------------------->
# To set this up on a new machine:
# 1. Install Perl via Homebrew: `brew install perl`
# 2. Install local::lib, run this command on the terminal: `PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib`
# 3. Add the following line to the shell profile to configure the environment
if [ -d "$HOME/perl5/lib/perl5" ] && command -v perl &>/dev/null; then
    eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
fi
# <<< END PERL INITIALIZATION

# Add Ruby gem user install directory to PATH --------------------------------->
# To set this up on a new machine:
# 1. Install Ruby gems in the user directory: `gem install neovim`
# 2. Find the user gem bin directory, run on the terminal: `gem env gemdir`
# 3. Add the user gem bin directory to PATH in the shell profile

# Dynamically get the user gem bin directory
user_gem_bin=$(ruby -e 'puts Gem.user_dir')/bin

# Dynamically get the Homebrew gem bin directory
homebrew_gem_bin=$(ruby -e 'puts Gem.bindir')

# Check if the directories exist and add them to PATH
if [ -d "$user_gem_bin" ]; then
    export PATH="$user_gem_bin:$PATH"
fi
if [ -d "$homebrew_gem_bin" ]; then
    export PATH="$homebrew_gem_bin:$PATH"
fi
# <<< END RUBY INITIALIZATION


# <-------------------- NVM INITIALIZATION -------------------->

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Commented out as not needed for Zsh


# <-------------------- CUSTOM SCRIPTS -------------------->

# Enhanced fcd function with customizable depth and better performance
if command -v find &>/dev/null && command -v fzf &>/dev/null && command -v colorls &>/dev/null; then
    fcd() {
        local depth="${1:-7}"  # Default depth is 7, but can be overridden by first argument
        local dir
        dir=$(find * -type d -maxdepth "$depth" 2>/dev/null | fzf --preview 'colorls --tree=2 --sd --gs --color=always {}' +m) && cd "$dir" || return
    }
fi


# <---------------- OMZ PATH, THEMES, AND ZPLUG ------------------>

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
# Caution: this setting can cause issues with multi line prompts in zsh < 5.7.1 (see #5765)
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
    # Git Aliases ------------------->
    alias ga='git add'
    alias gap='git add -p'
    alias gs='git status'
    alias gpr='git pull -r'
    alias gl='git lg'
    alias glo='git log --oneline'
    alias gcm='git commit -m'
    alias pear='git pair '
    alias gra='git commit --amend --reset-author --no-edit'
    alias gco='git checkout'
    alias hangon='git stash save -u'
    alias gsp='git stash pop'
    alias grc='git rebase --continue'
    alias gclean='git clean -df'
    alias gup='gco main && gpr && gco -'
    alias unwip='git reset HEAD~'
    alias unroll='git reset HEAD~ --hard'
    alias gpfwl='git push --force-with-lease'
    alias glt='git describe --tags --abbrev=0'
    alias unroll='unwip && git checkout . && git clean -df'
    alias rspec_units='rspec --exclude-pattern "**/features/*_spec.rb"'
    alias awsume='. awsume sso;. awsume'
    alias gprune=$'git branch --merged main | grep -v \'^[ *]*main$\' | xargs git branch -d'
fi

# Check if Tmux is installed
if command -v tmux &>/dev/null; then
    # Tmux Aliases ------------------->
    # Attaches tmux to a session (example: ta portal)
    alias ta='tmux attach -t'
    # Creates a new session
    alias tn='tmux new-session -s '
    # Kill session
    alias tk='tmux kill-session -t '
    # Lists all ongoing sessions
    alias tl='tmux list-sessions'
    # Detach from session
    alias td='tmux detach'
    # Tmux Clear pane
    alias tc='clear; tmux clear-history; clear'
fi

# Check if colorls is installed
if command -v colorls &>/dev/null; then
    # COLORLS ALIASES -------------------->

    # Alias for improved ls with colorls
    # - Lists almost all files (including hidden), sorts directories first, and shows git status.
    alias ls='colorls -A --gs --sd'

    # Alias for long format listing with colorls
    # - Lists all files (including hidden), sorts directories first, and shows git status.
    # - Omits group information in the long listing format.
    alias la='colorls -oA --sd --gs'

    # Alias for file-only long format listing with colorls
    # - Lists only files (including hidden), sorts directories first, and shows git status.
    # - Omits group information in the long listing format.
    alias lf='colorls -foa --sd --gs'

    # Alias for tree view with colorls
    # - Displays a tree view of directories, sorts directories first, shows git status, and enables hyperlinks.
    alias lt='colorls --tree=3 --sd --gs --hyperlink'
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

# Sourced + Aliased Scripts
[ -f ~/scripts/JavaProject.zsh ] && { source ~/scripts/JavaProject.zsh; alias jp="javaproject"; }
[ -f ~/scripts/JavaCompiler/JavaCompiler.zsh ] && source ~/scripts/JavaCompiler/JavaCompiler.zsh

# Weather
alias forecast='curl "https://wttr.in/coral-gables?1&F&q"'
alias weather='curl "https://wttr.in/coral-gables?format=1"'

# <-------------------- FZF INITIALIZATION -------------------->

[[ -f $HOME/.fzf.zsh ]] && source $HOME/.fzf.zsh
export FZF_DEFAULT_OPS="--extended --layout=reverse"
if type rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files'
    export FZF_DEFAULT_OPTS='-m --height 70% --border --layout=reverse'
fi

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
