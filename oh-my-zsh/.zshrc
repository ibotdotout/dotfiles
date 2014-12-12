# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Customize to your needs...

# suport thai in terminal
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#add local bin pah
export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH

# enalbe nosetests color by rednose
export NOSE_REDNOSE=1

# set virtualenv path for virutalwrapper
export WORKON_HOME=$HOME/develop/.env_python
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python
source "/usr/local/bin/virtualenvwrapper.sh"

# tmuxinator
export EDITOR='vim'

# short cmd to call nosetests --with-coverage and filter Third-party Librarie
alias nosecoverage="nosetests --with-coverage  --cover-erase --cover-package=\$(ls | grep '.py$' | sed 's/[.]py$//' | xargs | sed 's/[\ ]/,/g')"

# short pdflatex with output in folder
alias pdflatex="pdflatex -output-directory=output"

# make rm prompt before delete
alias rm="/bin/rm -i"

# use clear without keep it in history
alias clear=" clear"

# Docker: remove all Exited containers by Filippo Valsorda - https://coderwall.com/p/zguz_w
alias dockerclean="docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm"

# Open Google Chrome
alias chrome="open -a /Applications/Google\ Chrome.app"

# Show Hidden in Finder OSX
alias showHiddenFinder="defaults write com.apple.finder AppleShowAllFiles YES"
alias hideHiddenFinder="defaults write com.apple.finder AppleShowAllFiles NO"

# less color manpages
# http://www.cyberciti.biz/faq/linux-unix-colored-man-pages-with-less-command/
man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

# load boot2docker env
$(boot2docker shellinit 2> /dev/null)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)

# https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins
# plugins=(git osx python pip tmux vi-mode brew terminalapp sublime history)
plugins=(git osx python pip brew terminalapp docker sublime tmuxinator history)

# blind key in vi-mode
# bindkey -v "jk" vi-cmd-mode
# bindkey -v "kj" vi-cmd-mode
# bindkey -a  '^R' history-incremental-search-backward

# run zsh
source $ZSH/oh-my-zsh.sh
