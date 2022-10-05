#!/bin/bash

# Removes existing bash zsh ssh and vim dotfiles and sets up links to ~/bin/dotfiles
# Creates .vimtmp directory for Vim swap files

rm -R -f ~/.bash_profile ~/.bash* ~/.profile ~/.zsh* ~/.ssh/config ~/.vim* ~/.gvim* && ln -s ~/bin/dotfiles/zsh/zshrc ~/.zshrc && ln -s ~/bin/dotfiles/zsh/env ~/.zshenv && ln -s ~/bin/dotfiles/ssh/config ~/.ssh/config && ln -s ~/bin/dotfiles/vim/vimrc ~/.vimrc && ln -s ~/bin/dotfiles/vim ~/.vim && ln -s ~/bin/dotfiles/bash/bashrc ~/.bashrc && ln -s ~/bin/dotfiles/vim/gvimrc ~/.gvimrc && mkdir ~/.vimtmp

rm -rf ~/.config/nvim && ln -s ~/bin/dotfiles/nvim ~/.config/nvim

mkdir dotfiles/nvim/lua/user && ln -s dotfiles/nvim_AstroNvim/user/init.lua dotfiles/nvim/lua/user/init.lua
