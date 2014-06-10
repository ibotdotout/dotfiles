#!/usr/bin/ bash

FILE=".zshrc"
rm ~/$FILE
if [ -f "$HOME/.zshrc" ]; then
  mv ~/$FILE ~/$FILE.old
fi
ln -s $PWD/$FILE ~/$FILE
