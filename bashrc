# ***DO THIS ON NEW MACHINE***
# cd $HOME
# git clone https://github.com/monarin/goodstuffs
# In system bashrc, add
# [ -f "$HOME/goodstuffs/bashrc" ] && . "$HOME/goodstuffs/bashrc"
# [ -f "$HOME/goodstuffs/bashrc_history" ] && . "$HOME/goodstuffs/bashrc_history"

alias viper="ssh -YAC mu238@viper.lbl.gov"
alias dials="ssh -YAC mu238@dials.lbl.gov"
alias pslogin="ssh -YAC monarin@pslogin.slac.stanford.edu"
alias psdev="ssh -YAC monarin@psdev.slac.stanford.edu"
alias atbfs3="ssh monarin@atbfs3.stanford.edu"
alias moje="ssh mojeprot@mojeprotocol.com"
alias cori="ssh -Y monarin@cori.nersc.gov"
alias oakr="ssh -YAC monarin@home.ccs.ornl.gov"
alias smdev="ssh monarin@summitdev.ccs.ornl.gov"
alias s3df="ssh s3dflogin.slac.stanford.edu"
alias frontier="ssh monarin@frontier.olcf.ornl.gov"
alias crusher="ssh monarin@crusher.olcf.ornl.gov"
alias ascent="ssh monarin@login1.ascent.olcf.ornl.gov"
alias perlmutter="ssh monarin@perlmutter-p1.nersc.gov"
alias tmodaq="ssh -YC tmo-daq -l tmoopr"
alias rixdaq="ssh -YC rix-daq -l rixopr"
alias mcclogin="ssh mcclogin.slac.stanford.edu"
alias lclssrv="ssh acclegr@lcls-srv01"

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

mypath() {
    MYPATH=$HOME
    if [ "$1" != '' ]; then
        MYPATH=$@
    fi
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
myprompt=""
export PS1="$purple\u$cyan@\h$green\$(__git_ps1)$blue \W $myprompt$reset"

grr() {
    # -I ignores binary files
    grep -I --exclude \*.class --exclude \*.pyc --exclude-dir .git --exclude-dir .svn -r "$@"
}

cutniq() {
    grep -v 'Binary file' | cut -d: -f1 | uniq
}

see_disk_quota() {
    df -h | grep monarin
} 

see_disk_quota2() {
    fs lq
}

see_kerberos_cred() {
    klist
}

see_dir_total() {
    du -shc ./*
}

git_aa() {
    mod_files=($(git status | grep modified: | gawk '{ print $2}'))
    length=${#mod_files[@]}
    for ((i=0; i<length; i++))
    do
        echo "adding $i: '${mod_files[i]}'"
        git add ${mod_files[i]}
    done
}

git_set_remote_ssh() {
    git remote set-url origin git@github.com:monarin/$1.git
}

docker_clean() {
    arr=( $(docker images | grep "<none>" | gawk '{ print $3 }') )
    for imgid in ${arr[*]}
    do
        printf "remove   %s\n" $imgid
        docker rmi -f $imgid
    done
}

rm_swp() {
    arr=( $(find . -name "*.swp") )
    for fname in ${arr[*]}
    do
        printf "remove %s\n" $fname
        rm $fname
    done
}

sve_git_aa() {
    mod_files=($(git status | grep modified: | gawk '{ print $3}'))
    length=${#mod_files[@]}
    for ((i=0; i<length; i++))
    do
        f_basename="$(basename "${mod_files[i]}")"
        f_dirname="$(dirname "${mod_files[i]}")"
        echo "saving $i: '${mod_files[i]}' to ~/Save"
        pushd $f_dirname
            sve $f_basename
        popd 
    done
}

lstoday() {
    ls "$@" -al --time-style=+%D | grep $(date +%D)
}

sacctj() {
    sacct -j $1 --format=JobIDRaw,JobName%12,NodeList,Start,End,Elapsed,REQCPUS,ALLOCTRES%25
}

