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

2. Install `brew cask`

    ```sh
    $ brew tap caskroom/cask
    ```

3. Install `brew bundle`

    ```sh
    $ brew tap Homebrew/bundle
    ```

4. Install all packages & app from `Brewfile`

    ```sh
    $ brew bundle
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

### Install Tmux plugins by [TPM](https://github.com/tmux-plugins/tpm)

1. Install `tpm`

	```sh
	$ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	```

2. Install tmux plugin via from `.tmux.conf`

	```sh
	$ ~/.tmux/plugins/tpm/bin/install_plugins
	```

### References
* [Homebrew - The missing package manager for OS X](http://brew.sh)
* [Homebrew Cask - To install, drag this icon…” no more!](https://caskroom.github.io)
* [Brewfile: a Gemfile, but for Homebrew](https://robots.thoughtbot.com/brewfile-a-gemfile-but-for-homebrew)
* [Brew Bundle](https://github.com/Homebrew/homebrew-bundle)
* [vim-plug - A minimalist Vim plugin manager.](https://github.com/junegunn/vim-plug)
* [mildronize/dotfiles](https://github.com/mildronize/dotfiles#quick-setup)
