#!/usr/bin/ bash

FILE=".tmux.conf"
if [ -f "$HOME/.tmux.conf" ]; then
  mv ~/$FILE ~/$FILE.old
fi
ln -s $PWD/$FILE ~/$FILE
