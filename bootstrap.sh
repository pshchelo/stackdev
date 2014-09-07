#!/usr/bin/env sh
# install personal dev dependencies and sets up dev environment

# install some dependencies
sudo apt-get install mc htop ctags git
DOTFILES="$HOME/dotfiles"
git clone git@github.com:pshchelo/dotfiles.git $DOTFILES

# create links
ln -s "$DOTFILES/ack/ackrc" "$HOME/.ackrc"
ln -s "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"
ln -s "$DOTFILES/git/tigrc" "$HOME/.tigrc"
ln -s "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
ln -s "$DOTFILES/shell/tmux.conf" "$HOME/.tmux.conf"
ln -s "$DOTFILES/shell/bash_aliases" "$HOME/.bash_aliases"
ln -s "$DOTFILES/colors/dircolors-solarized" "$HOME/.dircolors"
ln -s "$DOTFILES/powerline" "$HOME/.config/powerline"
mv "$HOME/.profile" "$HOME/.profile-original"
mv "$HOME/.bashrc" "$HOME/.bashrc-original"
ln -s "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
ln -s "$DOTFILES/environment/profile" "$HOME/.profile"
source $HOME/.bashrc

ack_bin = "$HOME/.local/bin/ack"
wget http://beyondgrep.com/ack-2.14-single-file -O $ack_bin && chmod 0755 $ack_bin
ln -s "$DOTFILES/tig-2.0.3_x64" "$HOME/.local/bin/tig"

# create and edit gitconfig
cp "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
sed -i 's/shchelokovskyy@gmail/pshchelokovskyy@mirantis/' "$HOME/.gitconfig"
# following one is for the config to work on older git
#sed -i 's/default = simple//' "$HOME/.gitconfig"

#mkdir -p "$HOME/.config/mc"
#ln -s "$DOTFILES/colors/mc-solarized" "$HOME/.config/mc/mc-solarized"

# install Python packages in local user location
pip install --user -r dev-requirements.txt

# create ipython profile to hold custom settings
"$HOME/.local/bin/ipython" profile create
rm "$HOME/.ipython/profile_default/ipython_config.py"
ln -s "$DOTFILES/ipython/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"

# prepare Vundle to later install ViM plugins
mkdir -p "$HOME/.vim/bundle"
git clone https://github.com/gmarik/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
# setup all ViM plugins (requires input)
vim -c BundleInstall
