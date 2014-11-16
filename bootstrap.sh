#!/usr/bin/env sh
# install personal dev dependencies and sets up dev environment

# install some goodies and dependencies
DOTFILES="$HOME/dotfiles"
git clone git@github.com:pshchelo/dotfiles.git $DOTFILES

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
sudo apt-get install mc htop ctags
# create links to config files
ln -s "$DOTFILES/ack/ackrc" "$HOME/.ackrc"
ln -s "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"
ln -s "$DOTFILES/git/tigrc" "$HOME/.tigrc"
ln -s "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
ln -s "$DOTFILES/shell/tmux.conf" "$HOME/.tmux.conf"
ln -s "$DOTFILES/shell/bash_aliases" "$HOME/.bash_aliases"
ln -s "$DOTFILES/colors/dircolors-solarized" "$HOME/.dircolors"
mv "$HOME/.profile" "$HOME/.profile-original"
mv "$HOME/.bashrc" "$HOME/.bashrc-original"
ln -s "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
ln -s "$DOTFILES/environment/profile" "$HOME/.profile"
ln -s "$DOTFILES/powerline" "$HOME/.config/powerline"
#source $HOME/.bashrc

# create and edit gitconfig
cp "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
sed -i 's/shchelokovskyy@gmail/pshchelokovskyy@mirantis/' "$HOME/.gitconfig"

# install Python packages in local user location
pip install --user -r dev-requirements.txt

Make links to scripts/binaries
ln -s "$DOTFILES/bin/tig-2.0.3_x64" "$HOME/.local/bin/tig"
ln -s "$DOTFILES/scripts/ack" "$HOME/.local/bin/ack"
ln -s "$DOTFILES/scripts/ppclean" "$HOME/.local/bin/ppclean"
ln -s "$DOTFILES/scripts/dtestr" "$HOME/.local/bin/dtestr"

# create ipython profile to hold custom settings
#"$HOME/.local/bin/ipython" profile create
#rm "$HOME/.ipython/profile_default/ipython_config.py"
#ln -s "$DOTFILES/ipython/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"

# prepare Vundle to later install ViM plugins
mkdir -p "$HOME/.vim/bundle"
git clone https://github.com/gmarik/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
# setup all ViM plugins (requires input)
vim -c BundleInstall
