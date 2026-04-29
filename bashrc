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

export DAQ_LOG_DIR=/sdf/data/lcls/ds/prj/prjdat21/results/appdata/daq_logs.db
export OMPI_MCA_osc=sm  # For MPI.Win.Allocate_shared

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
  sacct -j "$1" --format=JobIDRaw,JobName%12,NodeList%75,Start,End,Elapsed,REQCPUS,ALLOCTRES%25
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

ssh_ipmi_tunnel() {
    # Usage:
    #   ssh_ipmi_tunnel local_port ipmi_host ssh_host

    local local_port="$1"             # e.g. 8787
    local ipmi_host="$2"              # e.g. drp-srcf-cmp005-ipmi
    local ssh_host="$3"               # e.g. psbuildrc

    echo "🔗 Forwarding $local_port → $ipmi_host:80 via $ssh_host"
    ssh -N -L "${local_port}:${ipmi_host}:80" "$ssh_host"
}

# Refresh SSH key on jump host
fix_ssh_key() {
  local key="${1:-$HOME/.ssh/id_ed25519}"
  local pub="${key}.pub"
  local user="monarin"
  local host="jump.slac.stanford.edu"

  if [[ ! -f "$key" || ! -f "$pub" ]]; then
    echo "❌ Key or pubkey not found: $key / $pub"
    return 1
  fi

  echo "🔑 Adding $key to ssh-agent..."
  ssh-add "$key" || return 1

  echo "📤 Copying public key to $user@$host..."
  ssh-copy-id -i "$pub" "$user@$host" || return 1

  echo "✅ SSH key refreshed on $host. Try again with: ssh psbuildrc"
}

grx() {
    if [ -z "$1" ]; then
        echo "Usage: grepexact <pattern> [directory]"
        return 1
    fi
    local pattern="$1"
    local dir="${2:-.}"
    grep -R --exclude-dir={.git,__pycache__} --include='*.py' -n --color=always "\b${pattern}\b" "$dir"
}

use_gpuio311() {
  local base=""
  if [ -x /sdf/home/m/monarin/bin/micromamba ] && [ -d /sdf/home/m/monarin/micromamba ]; then
    base=/sdf/home/m/monarin
  elif [ -x /cds/home/m/monarin/bin/micromamba ] && [ -d /cds/home/m/monarin/micromamba ]; then
    base=/cds/home/m/monarin
  else
    echo "micromamba installation not found under /sdf or /cds"
    return 1
  fi

  export MAMBA_ROOT_PREFIX="$base/micromamba"
  eval "$("$base/bin/micromamba" shell hook -s bash)"
  micromamba activate gpuio311
}

activate_xtcpp() {
    local xtcpp_root="$HOME/sw/xtcpp/install"
    if [ ! -d "$xtcpp_root" ]; then
        echo "xtcpp install not found at $xtcpp_root" >&2
        return 1
    fi

    export PYTHONPATH="$xtcpp_root/lib/python3.9/site-packages${PYTHONPATH:+:$PYTHONPATH}"
    export PATH="$xtcpp_root/bin:$PATH"
}

detnames_all_streams () {
  local exp="$1"
  local run="$2"
  local base="${3:-/sdf/data/lcls/ds}"

  if [[ -z "$exp" || -z "$run" ]]; then
    echo "Usage: detnames_all_streams <exp> <runnum> [basepath]" >&2
    echo "  ex: detnames_all_streams mfx101344525 75" >&2
    return 2
  fi

  # Decode exp like mfx101344525 -> instr=mfx, expdir=mfx/mfx101344525
  local instr="${exp:0:3}"
  local expdir="${instr}/${exp}"

  # Format run rNNNN (4 digits)
  local rtag
  rtag=$(printf "r%04d" "$run") || return 2

  local xtcdir="${base%/}/${expdir}/xtc"
  local prefix="${exp}-${rtag}"

  # Only chunk 0: ...-c000.xtc2
  ls -1 "${xtcdir}/${prefix}-s"*-c000.xtc2 2>/dev/null \
    | sed -n 's/.*-s\([0-9]\+\)-c000\.xtc2$/\1 &/p' \
    | sort -n -k1,1 \
    | cut -d' ' -f2- \
    | while IFS= read -r f; do
        echo "==> $f"
        detnames "$f"
      done
}


srun_alloc() {
  local jobid="$1"
  local node="$2"
  if [[ -z "$jobid" || -z "$node" ]]; then
    echo "usage: srun_alloc <jobid> <nodename>"
    return 1
  fi
  srun --jobid="$jobid" --nodelist="$node" --pty bash -l
}

weka_tier() {
  if [ $# -lt 1 ]; then
    echo "Usage: weka_tier <path>" >&2
    return 1
  fi
  weka fs tier location "$@"
}

opencode ()
{
    local bin_dir="/sdf/group/lcls/ds/dm/apps/dev/code/.opencode/bin";
    local config_dir="/sdf/group/lcls/ds/dm/apps/dev/opencode";
    if [[ "$1" == "--local" ]]; then
        shift;
        bin_dir="$HOME/.opencode/bin";
        config_dir="$HOME/.config/opencode";
    fi;
    OPENCODE_CONFIG_DIR="$config_dir" PATH="$bin_dir:$PATH" command opencode "$@"
}

sq() {
    if [ $# -eq 0 ]; then
        squeue -u "$USER"
    else
        squeue "$@"
    fi
}

nsys_report_screen() {
  # Usage: nsys_report_screen <report.nsys-rep>
  local rep="$1"
  if [[ -z "$rep" ]]; then
    echo "Usage: nsys_report_screen <report.nsys-rep>" >&2
    return 2
  fi
  if [[ ! -f "$rep" ]]; then
    echo "Report not found: $rep" >&2
    return 1
  fi

  local nsys_bin="${NSYS_BIN:-}"
  if [[ -z "$nsys_bin" ]] && command -v nsys >/dev/null 2>&1; then
    nsys_bin="$(command -v nsys)"
  fi

  local cand
  for cand in \
    "$nsys_bin" \
    "$HOME/tools/nsight-systems/2026.1.1/pkg/bin/nsys" \
    "$HOME/nsight-systems-2026.1.1/bin/nsys" \
    /usr/local/cuda/bin/nsys \
    /usr/local/nsight-systems/bin/nsys \
    /opt/nvidia/nsight-systems/bin/nsys; do
    if [[ -n "$cand" && -x "$cand" ]]; then
      nsys_bin="$cand"
      break
    fi
  done

  if [[ -z "$nsys_bin" || ! -x "$nsys_bin" ]]; then
    echo "nsys not found. Set NSYS_BIN or install Nsight Systems." >&2
    return 127
  fi

  echo "[nsys_report_screen] nsys : $nsys_bin"
  echo "[nsys_report_screen] file : $rep"
  echo

  echo "===== CUDA API Summary (cuda_api_sum) ====="
  "$nsys_bin" stats --force-export=true --report cuda_api_sum "$rep"
  echo

  echo "===== CUDA GPU MemOps by Time (cuda_gpu_mem_time_sum) ====="
  "$nsys_bin" stats --force-export=true --report cuda_gpu_mem_time_sum "$rep"
  echo

  echo "===== OS Runtime Summary (osrt_sum) ====="
  "$nsys_bin" stats --force-export=true --report osrt_sum "$rep"
  echo

  echo "===== GPU Memory Usage (CUDA_GPU_MEMORY_USAGE_EVENTS) ====="
  if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "sqlite3 not found; skipping GPU memory usage summary."
    return 0
  fi

  local db="${rep%.nsys-rep}.sqlite"
  if [[ ! -f "$db" ]]; then
    echo "SQLite export not found: $db"
    echo "Run nsys stats once to generate it."
    return 0
  fi

  local has_tbl
  has_tbl="$(sqlite3 "$db" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='CUDA_GPU_MEMORY_USAGE_EVENTS';" 2>/dev/null || echo 0)"
  if [[ "$has_tbl" != "1" ]]; then
    echo "No CUDA_GPU_MEMORY_USAGE_EVENTS table in this report."
    return 0
  fi

  local n_events
  n_events="$(sqlite3 "$db" "SELECT count(*) FROM CUDA_GPU_MEMORY_USAGE_EVENTS;" 2>/dev/null || echo 0)"
  echo "events: $n_events"
  if [[ "$n_events" -eq 0 ]]; then
    return 0
  fi

  local peak_device_mib
  peak_device_mib="$(sqlite3 "$db" "WITH ev AS (SELECT start, rowid AS rid, CASE memoryOperationType WHEN 0 THEN bytes ELSE -bytes END AS delta FROM CUDA_GPU_MEMORY_USAGE_EVENTS WHERE memKind=2), run AS (SELECT sum(delta) OVER (ORDER BY start, rid ROWS UNBOUNDED PRECEDING) AS cur FROM ev) SELECT printf('%.2f', COALESCE(max(cur),0)/1024.0/1024.0) FROM run;" 2>/dev/null)"
  echo "peak_device_alloc_mib: ${peak_device_mib:-0.00}"

  echo "by_kind_and_op (count, total_mib):"
  sqlite3 -header -column "$db" "SELECT COALESCE(k.label, CAST(e.memKind AS TEXT)) AS mem_kind, COALESCE(o.label, CAST(e.memoryOperationType AS TEXT)) AS op, COUNT(*) AS n_events, printf('%.2f', SUM(e.bytes)/1024.0/1024.0) AS total_mib FROM CUDA_GPU_MEMORY_USAGE_EVENTS e LEFT JOIN ENUM_CUDA_MEM_KIND k ON k.id = e.memKind LEFT JOIN ENUM_CUDA_DEV_MEM_EVENT_OPER o ON o.id = e.memoryOperationType GROUP BY mem_kind, op ORDER BY n_events DESC, total_mib DESC;"
}

activate_psana2_gpu_cupy() {
    export CUDA_PATH="$HOME/.local/share/psana2-gpu/cuda12shim"
    export LD_LIBRARY_PATH="$CUDA_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
}

show_slurm_gpu_resources() {
    echo "$SLURM_JOB_ID"
    echo "$SLURM_CPUS_ON_NODE"
    echo "$CUDA_VISIBLE_DEVICES"
    nvidia-smi -L
    python - <<'PY'
import cupy as cp

print("deviceCount =", cp.cuda.runtime.getDeviceCount())
for i in range(cp.cuda.runtime.getDeviceCount()):
    p = cp.cuda.runtime.getDeviceProperties(i)
    print(i, p["name"].decode())
PY
}

alias masked="QT_AUTO_SCREEN_SCALE_FACTOR=0 QT_SCALE_FACTOR=1 QT_FONT_DPI=96 masked"
