#!/usr/bin/ bash

FILE=".tmux.conf"
if [ -f "$HOME/.tmux.conf" ]; then
  mv ~/$FILE ~/$FILE.old
fi
ln -s $PWD/$FILE ~/$FILE

FILE=".tmux-panes"
if [ -f "$HOME/.tmux.panes" ]; then
  mv ~/$FILE ~/$FILE.old
fi
ln -s $PWD/$FILE ~/$FILE
