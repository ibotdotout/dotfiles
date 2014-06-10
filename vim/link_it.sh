#!/usr/bin/ bash

FILE=".vimrc"
rm ~/$FILE
ln -s $PWD/$FILE ~/$FILE
