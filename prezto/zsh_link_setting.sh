#!/bin/bash

FILE=".zshrc"
ln -s $PWD/$FILE ~/$FILE
ln -s $PWD/$FILE.local ~/$FILE.local
ln -s $PWD/.zpreztorc ~/.zpreztorc
