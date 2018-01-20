# goodstuffs
bashrc, vimrc, etc.

After cloning goodstuffs to your $HOME, 
  - in ~/.bashrc, add 
    [ -f "$HOME/goodstuffs/bashrc" ] && . "$HOME/goodstuffs/bashrc"
  - Create a softlink for to vimrc:
    ln -s $HOME/.vimrc $HOME/goodstuffs/vimrc

