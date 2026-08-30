#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This bootstrap is intended for macOS." >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
expected_repo_root="${HOME}/goodstuffs"
skills_repo="${CODEX_SKILLS_REPO:-${HOME}/codex-skills}"
skills_url="${CODEX_SKILLS_URL:-git@github.com:monarin/codex-skills.git}"
skills_dir="${CODEX_SKILLS_DIR:-${HOME}/.codex/skills}"
stamp="$(date '+%Y%m%d-%H%M%S')"

if [[ "$repo_root" != "$expected_repo_root" ]]; then
    echo "Expected this repository at ${expected_repo_root}; found ${repo_root}." >&2
    echo "Clone or move it to ${expected_repo_root}, then rerun." >&2
    exit 1
fi

backup_once() {
    local path="$1"
    if [[ -e "$path" && ! -e "${path}.before-goodstuffs-${stamp}" ]]; then
        cp -p "$path" "${path}.before-goodstuffs-${stamp}"
        echo "Backed up ${path}"
    fi
}

append_line_once() {
    local path="$1"
    local line="$2"

    mkdir -p "$(dirname "$path")"
    touch "$path"
    if ! grep -Fqx "$line" "$path"; then
        backup_once "$path"
        printf '\n%s\n' "$line" >> "$path"
    fi
}

prepend_ssh_includes() {
    local ssh_config="${HOME}/.ssh/config"
    local s3df_include='Include ~/.ssh/s3df/s3df.conf'
    local personal_include='Include ~/.ssh/config.d/*.conf'
    local need_s3df=0
    local need_personal=0
    local tmp

    touch "$ssh_config"
    grep -Fqx "$s3df_include" "$ssh_config" || need_s3df=1
    grep -Fqx "$personal_include" "$ssh_config" || need_personal=1

    if [[ "$need_s3df" -eq 0 && "$need_personal" -eq 0 ]]; then
        return 0
    fi

    backup_once "$ssh_config"
    tmp="${ssh_config}.goodstuffs.$$"
    {
        [[ "$need_s3df" -eq 0 ]] || printf '%s\n' "$s3df_include"
        [[ "$need_personal" -eq 0 ]] || printf '%s\n' "$personal_include"
        printf '\n'
        cat "$ssh_config"
    } > "$tmp"
    chmod 600 "$tmp"
    mv "$tmp" "$ssh_config"
}

install_shell_setup() {
    append_line_once "${HOME}/.bashrc" '[ -f "$HOME/goodstuffs/bashrc" ] && . "$HOME/goodstuffs/bashrc"'
    append_line_once "${HOME}/.bash_profile" '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
}

install_ssh_setup() {
    mkdir -p "${HOME}/.ssh/config.d" "${HOME}/.ssh/controlmasters" "${HOME}/.ssh/s3df"
    chmod 700 "${HOME}/.ssh" "${HOME}/.ssh/config.d" "${HOME}/.ssh/controlmasters" "${HOME}/.ssh/s3df"
    cp "$repo_root/ssh_config" "${HOME}/.ssh/config.d/goodstuffs.conf"
    chmod 600 "${HOME}/.ssh/config.d/goodstuffs.conf"
    prepend_ssh_includes
    chmod 600 "${HOME}/.ssh/config"
}

install_node_dependencies() {
    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        echo "Node.js and npm are required for the S3DF browser helper." >&2
        echo "Install Node.js, then rerun this bootstrap." >&2
        exit 1
    fi
    npm --prefix "$repo_root" ci
}

install_skills() {
    if [[ -d "$skills_repo/.git" ]]; then
        git -C "$skills_repo" pull --ff-only
    elif [[ -e "$skills_repo" ]]; then
        echo "${skills_repo} exists but is not a Git repository." >&2
        exit 1
    else
        git clone "$skills_url" "$skills_repo"
    fi

    mkdir -p "$skills_dir"

    local skill_path skill_name target
    for skill_path in "$skills_repo"/*; do
        [[ -f "$skill_path/SKILL.md" ]] || continue
        skill_name="$(basename "$skill_path")"
        target="${skills_dir}/${skill_name}"

        if [[ -e "$target" && ! -L "$target" ]]; then
            echo "Refusing to replace existing non-symlink skill: ${target}" >&2
            exit 1
        fi
        ln -sfn "$skill_path" "$target"
        echo "Linked ${skill_name}"
    done
}

install_shell_setup
install_ssh_setup
install_node_dependencies
install_skills
"${repo_root}/bin/s3df-key-refresh.sh" --write-config

echo
echo "Portable Mac setup installed."
if command -v sshproxy >/dev/null 2>&1; then
    echo "sshproxy: $(command -v sshproxy)"
else
    echo "sshproxy is not installed. Get the macOS universal package from:"
    echo "  https://portal.nersc.gov/cfs/mfa/"
fi
echo "Start a new Bash shell, then run: renew_s3df_key"
