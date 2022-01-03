OSX Dev Developement
=======

Fist `clone` and `cd` to dotfiles

```sh
$ git clone git@github.com:ibotdotout/dotfiles.git .dotfiles
$ cd .dotfiles
```

# Automate Install packages & Link all dotfiles

* Run all setup by install script

```sh
$ ./install
```

# Manual
### Install packages & app via Homebrew by Brewfile
1. Install `brew`

    ```sh
    $ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```

2. Install `brew bundle`

    ```sh
    $ brew tap Homebrew/bundle
    ```

3. Install all packages & app from `Brewfile`

    ```sh
    $ brew bundle
	# To install work related packages
	$ brew bundle --file Brewfile.work
    ```

### Link dotfiles by [dotbot](https://github.com/anishathalye/dotbot/)

1. Link `dotfiles`

    ```sh
    $ ./dotup
    ```

### Install Vim plugins by [vim-plug](https://github.com/junegunn/vim-plug)

1. Install `vim-plug`

    ```sh
    $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ```
2. Install vim plugin via `vim-plug` from `.vimrc`

    ```sh
    $ vim +PlugInstall +qall
    ```

### Install [fzf](https://github.com/junegunn/fzf) useful key bindings and fuzzy completion

    ```sh
    brew install fzf

    # To install useful key bindings and fuzzy completion:
    $(brew --prefix)/opt/fzf/install
    ```

### References
* [Homebrew - The missing package manager for OS X](http://brew.sh)
* [Homebrew Cask - To install, drag this icon…” no more!](https://caskroom.github.io)
* [Brewfile: a Gemfile, but for Homebrew](https://robots.thoughtbot.com/brewfile-a-gemfile-but-for-homebrew)
* [Brew Bundle](https://github.com/Homebrew/homebrew-bundle)
* [vim-plug - A minimalist Vim plugin manager.](https://github.com/junegunn/vim-plug)
* [mildronize/dotfiles](https://github.com/mildronize/dotfiles#quick-setup)
