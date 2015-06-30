# debian
# sudo apt-get install fabric

# osx
# pip install fabric

# usage
# run with "fab -H <host> <func>"

from fabric.api import sudo, run, cd


def _wget(url):
    sudo("wget -N %s" % url)


def intall_git():
    sudo("apt-get update && apt-get install git-core -y")


def install_oh_my_zsh():
    sudo("apt-get update && apt-get install zsh git-core -y")
    run("wget https://raw.github.com/robbyrussell/oh-my-zsh/"
        "master/tools/install.sh -O install-oh-my-zsh.sh")
    run("sed -i \"/chsh/ s/$/ `whoami`/\" install-oh-my-zsh.sh")
    sudo("cat ./install-oh-my-zsh.sh | bash")
    run("rm ./install-oh-my-zsh.sh")
    # sudo("shutdown -l")  # logout


def download_zshrc():
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/oh-my-zsh/.zshrc"
    url_local = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/oh-my-zsh/.zshrc.local"
    _wget(url)
    _wget(url_local)


def install_vim():
    sudo("apt-get update && apt-get install vim -y")


def download_vimrc():
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/vim/.vimrc"
    _wget(url)
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/vim/.vimrc.local"
    _wget(url)


def install_janus_vim():
    sudo("apt-get install ruby-dev rake exuberant-ctags ack-grep git-core -y")
    run("wget https://bit.ly/janus-bootstrap -O - | bash")


def download_janus_vim_conf():
    sudo("pip install flake8 pylint")  # To support python syntastic
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/janus/.vimrc.after"
    _wget(url)
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/janus/.vimrc.before"
    _wget(url)
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/vim/.vimrc.local"
    _wget(url)
    run("mkdir -p ~/.janus")
    with cd('~/.janus'):
        run("git clone"
            " https://github.com/altercation/vim-colors-solarized.git")
        run("git clone https://github.com/Lokaltog/vim-powerline.git")


def install_tmux():
    sudo("apt-get update && apt-get install tmux -y")


def download_tmux_conf():
    sudo("apt-get update && apt-get install xclip -y")
    url = "https://raw.githubusercontent.com/" \
        "ibotdotout/.devenv/master/tmux/.tmux.conf"
    _wget(url)


def install_python_pip():
    sudo("apt-get update && apt-get install python-pip -y")


def install_python_virtualenv():
    bashrc = '.bash_profile'
    sudo("pip install virtualenv")
    sudo("pip install virtualenvwrapper")
    run('echo "WORKON_HOME=~/Envs" >> %s' % bashrc)
    run('mkdir ~/Envs -p')
    run('echo "source /usr/local/bin/virtualenvwrapper.sh" >> %s' % bashrc)


def install_docker_io():
    sudo("apt-get update && apt-get install docker.io -y")
    sudo("gpasswd -a ${USER} docker")
    sudo("service docker restart")


def install_wemux():
    sudo("git clone git://github.com/zolrath/wemux.git /usr/local/share/wemux")
    sudo("ln -s /usr/local/share/wemux/wemux /usr/local/bin/wemux")
    sudo("cp /usr/local/share/wemux/wemux.conf.example "
         "/usr/local/etc/wemux.conf")
    sudo("sh -c 'echo \"host_list=(`cut -d: -f1 /etc/passwd | tail -1`)\""
         " >> /usr/local/etc/wemux.conf'")


def set_devenv():
    intall_git()
    install_tmux()
    install_vim()
    download_vimrc()
    download_tmux_conf()
    install_python_pip()
    install_python_virtualenv()


def set_koding():
    # set enviorment for koding.io
    install_oh_my_zsh()
    download_zshrc()
    install_wemux()
    install_python_pip()
    install_janus_vim()
    download_janus_vim_conf()
    download_tmux_conf()
