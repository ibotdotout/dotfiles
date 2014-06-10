#!/usr/bin/ bash

FILE=".zshrc"
rm ~/$FILE
ln -s $PWD/$FILE ~/$FILE
