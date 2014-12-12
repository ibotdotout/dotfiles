#!/bin/bash

FILE=".zshrc"
if [ -f "$HOME/.zshrc" ]; then
  mv ~/$FILE ~/$FILE.old
fi
ln -s $PWD/$FILE ~/$FILE
