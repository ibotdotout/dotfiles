#!/usr/bin/ bash

FILE=".tmux.conf"
rm ~/$FILE
ln -s $PWD/$FILE ~/$FILE
