OSX Dev Developement
=======

### Homebrew by Brewfile
1. Install `brew`

    ```sh
    $ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```

2. Install `brew cask`

    ```sh
    brew tap caskroom/cask
    ```

3. Install `brew bundle`

    ```sh
    $ brew tap Homebrew/bundle
    ```

4. Restore from `Brewfile`

    ```sh
    $ brew bundle
    ```

### Vim by [vim-plug](https://github.com/junegunn/vim-plug)

1. Install `vim-plug`

    ```sh
    $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ```
2. Install vim plugin via `vim-plug` from `.vimrc`

    ```sh
    $ vim -c 'PlugInstall| q! | q!'
    ```

### References
* [Homebrew - The missing package manager for OS X](http://brew.sh)
* [Homebrew Cask - To install, drag this icon…” no more!](https://caskroom.github.io)
* [Brewfile: a Gemfile, but for Homebrew](https://robots.thoughtbot.com/brewfile-a-gemfile-but-for-homebrew)
* [Brew Bundle](https://github.com/Homebrew/homebrew-bundle)
* [vim-plug - A minimalist Vim plugin manager.](https://github.com/junegunn/vim-plug)
