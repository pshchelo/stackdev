#!/usr/bin/env sh
# install personal dev dependencies and sets up dev environment

# install some goodies and dependencies
DOTFILES="$HOME/dotfiles"
git clone git@github.com:pshchelo/dotfiles.git $DOTFILES

cd $DOTFILES
sh bootstrap-main.sh

# create and edit gitconfig
cp "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
sed -i 's/shchelokovskyy@gmail/pshchelokovskyy@mirantis/' "$HOME/.gitconfig"
