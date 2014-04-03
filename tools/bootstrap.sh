#!/usr/bin/env sh
# install personal dev dependencies and sets up dev environment

# install some dependencies
sudo apt-get install mc htop ctags
# install Python packages in local user location
pip install --user -r personal-requirements.txt
cp ack-2.12-single-file ~/.local/bin/ack
cp tig-precise_x64 ~/.local/bin/tig
hash -r
# prepare Vundle to later install ViM plugins
mkdir -p ~/.vim/bundle
git clone git://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

DOTFILES='~/dotfiles'
git clone git@github.com:pshchelo/dotfiles.git $DOTFILES

ln -s $DOTFILES/ack/ackrc ~/.ackrc
ln -s $DOTFILES/colors/dircolors-solarized ~/.dircolors
ln -s $DOTFILES/colors/mc-solarized ~/.config/mc/mc-solarized
ln -s $DOTFILES/git/gitignore_global ~/.gitignore_global
ln -s $DOTFILES/git/tigrc ~/.tigrc
ln -s $DOTFILES/powerline ~/.config/powerline
ln -s $DOTFILES/vim/vimrc ~/.vimrc
ln -s $DOTFILES/shell/tmux.conf ~/.tmux.conf
ln -s $DOTFILES/shell/bash_aliases ~/.bash_aliases

mv ~/.profile ~/.profile-original
mv ~/.bashrc ~/.bashrc-original
ln -s $DOTFILES/shell/bashrc ~/.bashrc
ln -s $DOTFILES/environment/profile ~/.profile

# create and edit gitconfig
cp $DOTFILES/git/gitconfig ~/.gitconfig
sed -i 's/shchelokovskyy@gmail/pshchelokovskyy@mirantis/' ~/.gitconfig 
# following two are for the config to work on older git
sed -i 's/default = simple//' ~/.gitconfig

# create ipython profile to hold custom settings
ipython profile create
rm ~/.ipython/profile_default/ipython_config.py
ln -s $DOTFILES/ipython/ipython_config.py ~/.ipython/profile_default/ipython_config.py

# setup all ViM plugins (requires input)
vim -c BundleInstall
