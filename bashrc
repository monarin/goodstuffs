# [ -f "$HOME/goodstuffs/bashrc" ] && . "$HOME/goodstuffs/bashrc"

alias viper="ssh -YAC mu238@viper.lbl.gov"
alias dials="ssh -YAC mu238@dials.lbl.gov"
alias pslogin="ssh -YAC monarin@pslogin.slac.stanford.edu"
alias psdev="ssh -YAC monarin@psdev.slac.stanford.edu"
alias atbfs3="ssh monarin@atbfs3.stanford.edu"
alias moje="ssh mojeprot@mojeprotocol.com"
alias cori="ssh -Y monarin@cori.nersc.gov"

alias ll='ls -l'
alias delpyc="find . -name \"*. pyc\" -delete"

alias now='date "+%Y-%m-%d+%H%M%S"'

vman() {
    man "$@" | col -b | vi -R -
}

sve() {
    DESTPATH="${HOME}/Save/$@_`now`"
    echo "Saved to $DESTPATH"
    cp -a $@ $DESTPATH
}

gdbpy() {
    gdb `which python`
}

setuppsana() {
    mypath $1
    cd "$MYPATH/lcls2/psana"
    INSTDIR="$MYPATH/lcls2/install"
    python setup.py install --xtcdata=$INSTDIR --prefix=$INSTDIR
    cd -
}

mypath() {
    MYPATH=$HOME
    if [ "$1" != '' ]; then
        MYPATH=$@
    fi
}

genpsdata() {
    mypath $1
    $MYPATH/lcls2/install/bin/xtcwriter
    $MYPATH/lcls2/install/bin/smdwriter -f data.xtc
}

gccthis() {
    gcc -pthread -B /reg/g/psdm/sw/conda2/inst/envs/ps-0.0.6/compiler_compat -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall -Wstrict-prototypes -fPIC -I/reg/g/psdm/sw/conda2/inst/envs/ps-0.0.6/lib/python3.5/site-packages/numpy/core/include -I/reg/neh/home/monarin/lcls2/install/include -I/reg/g/psdm/sw/conda2/inst/envs/ps-0.0.6/include/python3.5m -c ringbuf.cc -o ringbuf -std=c++11
}

prof_py() {
    python -m cProfile -s tottime $1
}

prof_strace_py() {
    strace -ttt -f -o $$.log python $1
}

prof_perf_py() {
    perf record python $1
    echo "run perf report to see results"
}

pyver() {
    pyver=$(python -c "import sys; print(str(sys.version_info.major)+'.'+str(sys.version_info.minor))")
    echo $pyver
}

slac_proxy(){
    export http_proxy="http://psproxy:3128"
    export https_proxy="https://psproxy:3128"
}

export EDITOR=vim
export GIT_EDITOR=vim

# Enable tab completion
source $HOME/goodstuffs/git-completion.bash

# colors!
green="\[\033[0;32m\]"
blue="\[\033[0;34m\]"
purple="\[\033[0;35m\]"
cyan="\[\033[0;36m\]"
reset="\[\033[0m\]"

# Change command prompt
source $HOME/goodstuffs/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
# '\u' adds the name of the current user to the prompt
# '\$(__git_ps1)' adds git-related stuff
# '\W' adds the name of the current directory
export PS1="$purple\u$cyan@\h$green\$(__git_ps1)$blue \W $ $reset"

alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"

# The next line updates PATH for the Google Cloud SDK.
if [ -f /Users/monarin/Documents/google-cloud-sdk/path.bash.inc ]; then
  source '/Users/monarin/Documents/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f /Users/monarin/Documents/google-cloud-sdk/completion.bash.inc ]; then
  source '/Users/monarin/Documents/google-cloud-sdk/completion.bash.inc'
fi

# added by Anaconda2 4.2.0 installer
if [ -d "/Users/monarin/anaconda/bin" ]; then
  export PATH="/Users/monarin/anaconda/bin:$PATH"
fi
