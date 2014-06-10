#!/usr/bin/ bash

FILE=".vimrc"
mv ~/.vim ~/.vim.old
ln -s $PWD/.janus ~/.janus
mv ~/$FILE.before ~/$FILE.before.old
ln -s $PWD/$FILE.before ~/$FILE.before
mv ~/$FILE.after ~/$FILE.after.old
ln -s $PWD/$FILE.after ~/$FILE.after
