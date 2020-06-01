# [ -f "$HOME/goodstuffs/bashrc" ] && . "$HOME/goodstuffs/bashrc"

alias viper="ssh -YAC mu238@viper.lbl.gov"
alias dials="ssh -YAC mu238@dials.lbl.gov"
alias pslogin="ssh -YAC monarin@pslogin.slac.stanford.edu"
alias psdev="ssh -YAC monarin@psdev.slac.stanford.edu"
alias atbfs3="ssh monarin@atbfs3.stanford.edu"
alias moje="ssh mojeprot@mojeprotocol.com"
alias cori="ssh -Y monarin@cori.nersc.gov"
alias oakr="ssh -YAC monarin@home.ccs.ornl.gov"
alias smdev="ssh monarin@summitdev.ccs.ornl.gov"

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

smdev_its() {
    bsub -P CHM137 -XF -nnodes 1 -W ${1} -Is $SHELL
}

ns_init() {
    mkdir ~/NERSC-MFA
    scp monarin@dtn01.nersc.gov:/project/projectdirs/mfa/NERSC-MFA/sshproxy.sh ~/NERSC-MFA
}

ns_gen24() {
    cd ~/NERSC-MFA
    ./sshproxy.sh
    ssh -i ~/.ssh/nersc cori.nersc.gov
}

ns_chk24() {
    ssh-keygen -L -f ~/.ssh/nersc-cert.pub | grep Valid
}

ns_mfa() {
    ssh -i ~/.ssh/nersc cori.nersc.gov
}

grr() {
    # -I ignores binary files
    grep -I --exclude \*.class --exclude \*.pyc --exclude-dir .git --exclude-dir .svn -r "$@"
}

cutniq() {
    grep -v 'Binary file' | cut -d: -f1 | uniq
}

mpirunfull() {
    /reg/common/package/openmpi/4.0.0-rhel7/bin/mpirun --mca btl_openib_allow_ib 1 $@
}

sl() {
    ~/.auto_pslogin.sh
}

sb() {
    ssh psbuild-rhel7
}

sd() {
    ssh psdev
}

oss() {
  source $HOME/lcls2/setup_env.sh
  export PATH=/opt/openspeedshop/bin:$PATH
  export LD_LIBRARY_PATH=/opt/openspeedshop/lib64:$LD_LIBRARY_PATH
}

set_tau() {
  #export TAU_MAKEFILE=/reg/neh/home/monarin/tau-2.28/x86_64/lib/Makefile.tau-mpi
  export TAU_MAKEFILE=/reg/neh/home/monarin/tau-2.28/x86_64/lib/Makefile.tau-ompt-mpi-pdt-openmp
  export PATH=/reg/neh/home/monarin/tau-2.28/x86_64/bin:$PATH
}

set_proxy() {
export http_proxy="http://psproxy:3128"
export https_proxy="https://psproxy:3128"
export ftp_proxy="http://psproxy:3128"
}

see_disk_quota() {
    df -h | grep monarin
} 

see_kerberos_cred() {
    klist
}

git_aa() {
    mod_files=($(git status | grep modified: | awk '{ print $3}'))
    length=${#mod_files[@]}
    for ((i=0; i<length; i++))
    do
        echo "adding $i: '${mod_files[i]}'"
        git add ${mod_files[i]}
    done
}

docker_clean() {
    arr=( $(docker images | grep "<none>" | gawk '{ print $3 }') )
    for imgid in ${arr[*]}
    do
        printf "remove   %s\n" $imgid
        docker rmi -f $imgid
    done
}
