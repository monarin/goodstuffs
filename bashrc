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
    df -h $HOME
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

activate_pytorch(){
    export PYTHONPATH=$PYTHONPATH:/sdf/scratch/users/m/monarin/sw
}

psf() {
    ps -p $1 -o pid,vsz=MEMORY -o user,group=GROUP -o cls,pri,rtprio -o comm,args=ARGS | cat
}

sinfof() {
    sinfo -o "%30N  %10c  %10m  %35f  %10G "
}

sqf() {
    squeue $@ -o "%.18i %15j %.8u %.8T %20S %.10M %.6D %R" 
}

prc(){
    isort "$@"
    black "$@"
    ruff check "$@"
    #flake8 "$@"
}

open_latest() {
    local file
    prefix=${1}
    file=$(ls -t ${prefix} 2>/dev/null | head -n 1)
    echo "open_latest $file"
    if [[ -n "$file" ]]; then
        vim "$file"
    else
        echo "No ${prefix} files found." >&2
    fi
}

tail_latest() {
    local file
    prefix=${1}
    file=$(ls -t ${prefix} 2>/dev/null | head -n 1)
    echo "tail_latest $file"
    if [[ -n "$file" ]]; then
        tail -f "$file"
    else
        echo "No ${prefix} files found." >&2
    fi
}

pip_who_needs() {
    if [ -z "$1" ]; then
        echo "Usage: pip_who_needs <package-name>"
        return 1
    fi

    local target="$1"
    echo "🔍 Checking which user-installed packages require '$target'..."
    
    pip list --user --format=freeze | cut -d= -f1 | while read pkg; do
        deps=$(pip show "$pkg" | awk -F': ' '/Requires:/ {print $2}')
        if echo "$deps" | grep -wq "$target"; then
            echo "📦 $pkg depends on $target"
        fi
    done
}

# Function to enable pyenv only when needed
use_pyenv() {
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"

  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    echo "pyenv initialized."
    echo "Available versions:"
    pyenv versions
  else
    echo "pyenv not found in $PYENV_ROOT. Please install it first."
  fi
}

suspend_proc() {
    if [ -z "$1" ]; then
        echo "Usage: suspend_proc <keyword>"
        return 1
    fi
    local pid
    pid=$(ps aux | grep "$1" | grep -v grep | awk '{print $2}')
    if [ -z "$pid" ]; then
        echo "No matching process found for '$1'."
        return 1
    fi
    kill -STOP "$pid"
    echo "Suspended process $pid matching keyword '$1'."
}

resume_proc() {
    if [ -z "$1" ]; then
        echo "Usage: resume_proc <keyword>"
        return 1
    fi
    local pid
    pid=$(ps aux | grep "$1" | grep -v grep | awk '{print $2}')
    if [ -z "$pid" ]; then
        echo "No matching process found for '$1'."
        return 1
    fi
    kill -CONT "$pid"
    echo "Resumed process $pid matching keyword '$1'."

kill_matching_procs() {
    local keyword=$1
    if [[ -z "$keyword" ]]; then
        echo "Usage: kill_matching_procs <keyword>"
        return 1
    fi

    local pids
    pids=$(pgrep -f "$keyword")

    if [[ -z "$pids" ]]; then
        echo "No matching processes found for: $keyword"
        return 0
    fi

    echo "Killing the following processes matching '$keyword':"
    ps -fp $pids
    kill $pids
}

