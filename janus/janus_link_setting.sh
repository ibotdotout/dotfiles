#!/bin/bash

FILE=".vimrc"
DIR="$HOME/.janus"
if [ -d $DIR ]; then
  mv $DIR ~/.janus.old
fi
git submodule update --init .
ln -s $PWD/.janus  ~

if [ -f "$HOME/.vimrc.before" ]; then
  mv ~/$FILE.before ~/$FILE.before.old
fi
ln -s $PWD/$FILE.before ~/$FILE.before

if [ -f "$HOME/.vimrc.after" ]; then
  mv ~/$FILE.after ~/$FILE.after.old
fi
ln -s $PWD/$FILE.after ~/$FILE.after

if [ -f "$HOME/.vimrc.local" ]; then
  mv ~/$FILE.local ~/$FILE.local.old
fi
ln -s $PWD/../vim/$FILE.local ~/$FILE.local
