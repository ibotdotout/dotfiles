#!/bin/bash

FILE=".zshrc"
ln -s $PWD/$FILE ~/$FILE
ln -s $PWD/$FILE.local ~/$FILE.local
