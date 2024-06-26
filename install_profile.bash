#!/bin/bash

# Removes existing bash zsh ssh and vim dotfiles and sets up links to ~/bin/dotfiles

rm -R -f ~/.bash_profile ~/.bash* ~/.profile ~/.zsh* ~/.ssh/config ~/.vim* ~/.gvim* && ln -s ~/bin/dotfiles/zsh/zshrc ~/.zshrc && ln -s ~/bin/dotfiles/zsh/env ~/.zshenv && ln -s ~/bin/dotfiles/ssh/config ~/.ssh/config

rm -rf ~/.config/nvim && ln -s ~/bin/dotfiles/nvim ~/.config/nvim
