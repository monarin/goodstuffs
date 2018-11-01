filetype plugin indent on
" show existing tab with 4 spaces width 
set tabstop=4
" when indenting with '>', use 4 spaces width 
set shiftwidth=4
" On pressing tab, insert 4 spaces 
set expandtab
" No indent when paste
set pastetoggle=<F3>
" don't insert comment automatically
" with sticky setting see
" https://superuser.com/questions/271023/can-i-disable-continuation-of-comments-to-the-next-line-in-vim
autocmd BufNewFile,BufRead * setlocal formatoptions-=cro
