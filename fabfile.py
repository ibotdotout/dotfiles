# pip install fabric
# run with "fab -H <host> <func>"

from fabric.api import sudo, run


def install_vim():
    sudo("apt-get update & apt-get install vim -y")


def download_vimrc():
    url = "https://raw.githubusercontent.com/" \
          "ibotdotout/.devenv/master/vim/.vimrc"
    run("wget %s" % url)


def install_tmux():
    sudo("apt-get update & apt-get install tmux -y")


def download_tmux_conf():
    url = "https://raw.githubusercontent.com/" \
          "ibotdotout/.devenv/master/tmux/.tmux.conf"
    run("wget %s" % url)


def install_python_pip():
    sudo("apt-get update & apt-get install python-pip -y")


def install_python_virtualenv():
    bashrc = '.bash_profile'
    sudo("pip install virtualenv")
    sudo("pip install virtualenvwrapper")
    run('echo "WORKON_HOME=~/Envs" >> %s' % bashrc)
    run('mkdir ~/Envs -p')
    run('echo "source /usr/local/bin/virtualenvwrapper.sh" >> %s' % bashrc)


def intall_git():
    sudo("apt-get update & apt-get install git-core -y")
    

def install_janus_vim():
    sudo("apt-get install ruby-dev rake exuberant-ctags ack-grep -y")
    run("wget https://bit.ly/janus-bootstrap -O - | bash")
    

def install_docker_io():
    sudo("apt-get update & apt-get install docker.io -y")
    sudo("gpasswd -a ${USER} docker")
    sudo("service docker.io restart")
    
def install_oh_my_zsh():
    sudo("apt-get update & apt-get install zsh git-core -y")
    run("wget --no-check-certificate http://install.ohmyz.sh -O - | sh")
    run("chsh -s `which zsh`")
    sudo("shutdown -l") #logout


def set_devenv():
    install_vim()
    download_vimrc()
    install_tmux()
    download_tmux_conf()
    install_python_pip()
    install_python_virtualenv()
    intall_git()
