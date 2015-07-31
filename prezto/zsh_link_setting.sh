#!/bin/bash

FILE=".zshrc"
ln -sf $PWD/$FILE ~/$FILE
ln -sf $PWD/../oh-my-zsh/$FILE.local ~/$FILE.local
ln -sf $PWD/.zpreztorc ~/.zpreztorc
