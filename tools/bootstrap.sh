#!/usr/bin/env sh
# install personal dev dependencies and sets up dev environment

# install some dependencies
sudo apt-get install mc htop ctags
# install Python packages in local user location
pip install --user -r personal-requirements.txt
cp ack-2.12-single-file "$HOME/.local/bin/ack"
cp tig-precise_x64 "$HOME/.local/bin/tig"
# prepare Vundle to later install ViM plugins
mkdir -p "$HOME/.vim/bundle"
git clone https://github.com/gmarik/vundle.git "$HOME/.vim/bundle/vundle"

DOTFILES="$HOME/dotfiles"
git clone git@github.com:pshchelo/dotfiles.git $DOTFILES

# create and edit gitconfig
cp "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
sed -i 's/shchelokovskyy@gmail/pshchelokovskyy@mirantis/' "$HOME/.gitconfig" 
# following one is for the config to work on older git
#sed -i 's/default = simple//' "$HOME/.gitconfig"

# create links
ln -s "$DOTFILES/ack/ackrc" "$HOME/.ackrc"
ln -s "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"
ln -s "$DOTFILES/git/tigrc" "$HOME/.tigrc"
ln -s "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
ln -s "$DOTFILES/shell/tmux.conf" "$HOME/.tmux.conf"
ln -s "$DOTFILES/shell/bash_aliases" "$HOME/.bash_aliases"
ln -s "$DOTFILES/colors/dircolors-solarized" "$HOME/.dircolors"

mkdir -p "$HOME/.config/mc"
ln -s "$DOTFILES/colors/mc-solarized" "$HOME/.config/mc/mc-solarized"
ln -s "$DOTFILES/powerline" "$HOME/.config/powerline"

mv "$HOME/.profile" "$HOME/.profile-original"
mv "$HOME/.bashrc" "$HOME/.bashrc-original"
ln -s "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
ln -s "$DOTFILES/environment/profile" "$HOME/.profile"

# create ipython profile to hold custom settings
"$HOME/.local/bin/ipython" profile create
rm "$HOME/.ipython/profile_default/ipython_config.py"
ln -s "$DOTFILES/ipython/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"

# setup all ViM plugins (requires input)
vim -c BundleInstall
