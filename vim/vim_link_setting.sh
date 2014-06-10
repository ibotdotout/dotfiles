#!/usr/bin/ bash

FILE=".vimrc"
if [ -f "$HOME/.vimrc" ]; then
  mv ~/$FILE ~/$FILE.old
fi
ln -s $PWD/$FILE ~/$FILE
