import os
import pathlib
import shutil
import socket
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


def write_executable(path, body):
    path.write_text("#!/usr/bin/env bash\nset -eu\n" + body)
    path.chmod(0o755)
    return path


class DailyAccessTests(unittest.TestCase):
    def base_env(self, temp):
        bindir = temp / "bin"
        bindir.mkdir()
        trace = temp / "trace"
        env = os.environ.copy()
        env.update({"PATH": f"{bindir}:{env['PATH']}", "TRACE": str(trace)})
        return bindir, trace, env

    def test_mac_status_orders_all_independent_stages(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            write_executable(bindir / "uname", '[[ "${1-}" == "-s" ]] && echo Darwin || /usr/bin/uname "$@"\n')
            s3df = write_executable(bindir / "s3df", 'echo "s3df:$*" >> "$TRACE"\n')
            nersc = write_executable(bindir / "nersc", 'echo "nersc:$*" >> "$TRACE"\n')
            ssh = write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\n')
            env.update({
                "DAILY_ACCESS_S3DF_VERIFY_HELPER": str(s3df),
                "DAILY_ACCESS_NERSC_HELPER": str(nersc),
                "DAILY_ACCESS_SSH": str(ssh),
            })

            subprocess.run([ROOT / "bin/renew_daily_access", "--status"], env=env, check=True)
            lines = trace.read_text().splitlines()
            self.assertEqual(lines[0], "s3df:")
            self.assertEqual(lines[1], "nersc:--status")
            self.assertTrue(lines[2].startswith("ssh:-tt "))
            self.assertIn("sdfiana", lines[2])
            self.assertIn("renew_remote_access --status --with-nersc", lines[2])
            self.assertIn("psbuildrc", lines[3])
            self.assertIn("renew_remote_access --status", lines[3])

    def test_installed_mac_copy_finds_verifier_under_goodstuffs(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            home = temp / "home"
            installed_bin = home / "bin"
            verifier_dir = home / "goodstuffs/scripts"
            installed_bin.mkdir(parents=True)
            verifier_dir.mkdir(parents=True)
            installed = installed_bin / "renew_daily_access"
            shutil.copy2(ROOT / "bin/renew_daily_access", installed)
            write_executable(bindir / "uname", '[[ "${1-}" == "-s" ]] && echo Darwin || /usr/bin/uname "$@"\n')
            write_executable(verifier_dir / "verify-s3df-hosts.sh", 'echo "verified:$0" >> "$TRACE"\n')
            nersc = write_executable(bindir / "nersc", 'echo "nersc:$*" >> "$TRACE"\n')
            ssh = write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\n')
            env.update({
                "HOME": str(home),
                "DAILY_ACCESS_NERSC_HELPER": str(nersc),
                "DAILY_ACCESS_SSH": str(ssh),
            })

            subprocess.run([installed, "--status"], env=env, check=True)
            self.assertEqual(
                trace.read_text().splitlines()[0],
                f"verified:{verifier_dir / 'verify-s3df-hosts.sh'}",
            )

    def test_mac_failure_is_aggregated_without_skipping_later_stages(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            write_executable(bindir / "uname", '[[ "${1-}" == "-s" ]] && echo Darwin || /usr/bin/uname "$@"\n')
            s3df = write_executable(bindir / "s3df", 'echo "s3df" >> "$TRACE"\nexit 9\n')
            nersc = write_executable(bindir / "nersc", 'echo "nersc:$*" >> "$TRACE"\n')
            ssh = write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\n')
            env.update({
                "DAILY_ACCESS_S3DF_HELPER": str(s3df),
                "DAILY_ACCESS_NERSC_HELPER": str(nersc),
                "DAILY_ACCESS_SSH": str(ssh),
            })

            result = subprocess.run([ROOT / "bin/renew_daily_access"], env=env)
            self.assertEqual(result.returncode, 1)
            lines = trace.read_text().splitlines()
            self.assertEqual(len(lines), 4)
            self.assertEqual(lines[1], "nersc:--fedid")
            self.assertIn("sdfiana", lines[2])
            self.assertIn("psbuildrc", lines[3])

    def test_remote_workflow_passes_interactive_nersc_flags(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            key = write_executable(bindir / "key", 'echo "key:$*" >> "$TRACE"\n')
            krb = write_executable(bindir / "krb", 'echo "krb:$*" >> "$TRACE"\n')
            nersc = write_executable(bindir / "nersc", 'echo "nersc:$*" >> "$TRACE"\n')
            env.update({
                "REMOTE_ACCESS_SDF_KEY_HELPER": str(key),
                "REMOTE_ACCESS_KRB_HELPER": str(krb),
                "REMOTE_ACCESS_NERSC_HELPER": str(nersc),
            })

            subprocess.run([ROOT / "bin/renew_remote_access", "--with-nersc"], env=env, check=True)
            self.assertEqual(
                trace.read_text().splitlines(),
                ["key:", "krb:", "nersc:--fedid --no-browser"],
            )

    def test_remote_status_is_read_only_and_aggregates_failure(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            key = write_executable(bindir / "key", 'echo "key:$*" >> "$TRACE"\nexit 4\n')
            krb = write_executable(bindir / "krb", 'echo "krb:$*" >> "$TRACE"\n')
            nersc = write_executable(bindir / "nersc", 'echo "nersc:$*" >> "$TRACE"\n')
            env.update({
                "REMOTE_ACCESS_SDF_KEY_HELPER": str(key),
                "REMOTE_ACCESS_KRB_HELPER": str(krb),
                "REMOTE_ACCESS_NERSC_HELPER": str(nersc),
            })

            result = subprocess.run(
                [ROOT / "bin/renew_remote_access", "--status", "--with-nersc"], env=env
            )
            self.assertEqual(result.returncode, 1)
            self.assertEqual(
                trace.read_text().splitlines(),
                ["key:--status", "krb:--status", "nersc:--status"],
            )

    def test_encrypted_sdf_key_calls_agent_before_registration(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            home = temp / "home"
            ssh_dir = home / ".ssh"
            ssh_dir.mkdir(parents=True)
            for name in ("id_ed25519", "id_ed25519.pub", "id_rsa", "id_rsa.pub"):
                (ssh_dir / name).write_text("test\n")
            agent = write_executable(bindir / "agent", 'echo "agent:$*" >> "$TRACE"\n')
            copy_id = write_executable(bindir / "copy-id", 'echo "copy:$*" >> "$TRACE"\n')
            ssh = write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\n')
            keygen = write_executable(bindir / "keygen", 'exit 1\n')
            env.update({
                "HOME": str(home),
                "SSH_AGENT_START_HELPER": str(agent),
                "SDF_SSH_COPY_ID_COMMAND": str(copy_id),
                "SDF_SSH_COMMAND": str(ssh),
                "SDF_SSH_KEYGEN_COMMAND": str(keygen),
            })

            subprocess.run([ROOT / "bin/renew_sdf_key"], env=env, check=True)
            lines = trace.read_text().splitlines()
            self.assertEqual(lines[0], f"agent:{ssh_dir / 'id_ed25519'}")
            self.assertIn(f"-i {ssh_dir / 'id_ed25519.pub'}", lines[1])
            self.assertIn("-o ControlMaster=no", lines[1])
            self.assertIn("-o ControlPath=none", lines[1])

            trace.write_text("")
            subprocess.run([ROOT / "bin/renew_sdf_key", "--status"], env=env, check=True)
            lines = trace.read_text().splitlines()
            self.assertEqual(lines[0], f"agent:--status {ssh_dir / 'id_ed25519'}")
            self.assertIn("-o ControlMaster=no", lines[1])
            self.assertIn("-o ControlPath=none", lines[1])

    def test_unencrypted_rsa_key_skips_agent(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            home = temp / "home"
            ssh_dir = home / ".ssh"
            ssh_dir.mkdir(parents=True)
            key = ssh_dir / "id_rsa"
            key.write_text("private-placeholder\n")
            (ssh_dir / "id_rsa.pub").write_text("public-placeholder\n")
            agent = write_executable(bindir / "agent", 'echo "agent:$*" >> "$TRACE"\n')
            copy_id = write_executable(bindir / "copy-id", 'echo "copy:$*" >> "$TRACE"\n')
            ssh = write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\n')
            keygen = write_executable(bindir / "keygen", 'exit 0\n')
            env.update({
                "HOME": str(home),
                "SSH_AGENT_START_HELPER": str(agent),
                "SDF_SSH_COPY_ID_COMMAND": str(copy_id),
                "SDF_SSH_COMMAND": str(ssh),
                "SDF_SSH_KEYGEN_COMMAND": str(keygen),
            })

            result = subprocess.run(
                [ROOT / "bin/renew_sdf_key"], env=env, text=True, capture_output=True, check=True
            )
            lines = trace.read_text().splitlines()
            self.assertEqual(len(lines), 1)
            self.assertTrue(lines[0].startswith("copy:"))
            self.assertIn("no agent is required", result.stdout)

            trace.write_text("")
            subprocess.run([ROOT / "bin/renew_sdf_key", "--status"], env=env, check=True)
            lines = trace.read_text().splitlines()
            self.assertEqual(len(lines), 1)
            self.assertTrue(lines[0].startswith("ssh:"))

    def test_agent_status_accepts_loaded_selected_key(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, _trace, env = self.base_env(temp)
            home = temp / "home"
            ssh_dir = home / ".ssh"
            runtime = temp / "runtime"
            ssh_dir.mkdir(parents=True)
            runtime.mkdir()
            key = ssh_dir / "id_rsa"
            key.write_text("private-placeholder\n")
            (ssh_dir / "id_rsa.pub").write_text("public-placeholder\n")
            write_executable(bindir / "uname", 'echo Linux\n')
            write_executable(bindir / "systemctl", "exit 0\n")
            write_executable(bindir / "ssh-keygen", 'echo "256 FP test"\n')
            write_executable(bindir / "ssh-add", 'echo "256 FP test"\n')
            env.update({"HOME": str(home), "XDG_RUNTIME_DIR": str(runtime)})

            sock = socket.socket(socket.AF_UNIX)
            try:
                sock.bind(str(runtime / "ssh-agent.socket"))
                result = subprocess.run(
                    [ROOT / "bin/ssh_agent_start", "--status"],
                    env=env,
                    text=True,
                    capture_output=True,
                )
            finally:
                sock.close()
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"SSH key loaded: {key}", result.stdout)

    def test_agent_renew_installs_unit_and_adds_key_with_lifetime(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            home = temp / "home"
            ssh_dir = home / ".ssh"
            runtime = temp / "runtime"
            ssh_dir.mkdir(parents=True)
            runtime.mkdir()
            key = ssh_dir / "id_ed25519"
            key.write_text("private-placeholder\n")
            (ssh_dir / "id_ed25519.pub").write_text("public-placeholder\n")
            write_executable(bindir / "uname", 'echo Linux\n')
            write_executable(bindir / "ssh-keygen", 'echo "256 FP test"\n')
            write_executable(bindir / "systemctl", 'echo "systemctl:$*" >> "$TRACE"\n')
            write_executable(
                bindir / "ssh-add",
                'if [[ "${1-}" == "-l" ]]; then exit 1; fi\necho "ssh-add:$*" >> "$TRACE"\n',
            )
            env.update({"HOME": str(home), "XDG_RUNTIME_DIR": str(runtime)})

            sock = socket.socket(socket.AF_UNIX)
            try:
                sock.bind(str(runtime / "ssh-agent.socket"))
                subprocess.run([ROOT / "bin/ssh_agent_start"], env=env, check=True)
            finally:
                sock.close()
            lines = trace.read_text().splitlines()
            self.assertIn("systemctl:--user daemon-reload", lines)
            self.assertIn("systemctl:--user enable --now ssh-agent.service", lines)
            self.assertIn(f"ssh-add:-t 24h {key}", lines)

    def test_kerberos_renew_falls_back_and_status_never_calls_kinit(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            write_executable(bindir / "hostname", 'echo test-host\n')
            write_executable(bindir / "date", 'echo test-date\n')
            write_executable(
                bindir / "kinit",
                'echo "kinit:$*" >> "$TRACE"\n[[ "${1-}" != "-R" ]]\n',
            )
            write_executable(bindir / "klist", 'echo "klist:$*" >> "$TRACE"\n')

            subprocess.run([ROOT / "bin/renew_sdf_krb"], env=env, check=True)
            self.assertEqual(
                trace.read_text().splitlines(),
                ["kinit:-R", "kinit:-r 7d monarin@SLAC.STANFORD.EDU", "klist:-f"],
            )

            trace.write_text("")
            subprocess.run([ROOT / "bin/renew_sdf_krb", "--status"], env=env, check=True)
            self.assertEqual(trace.read_text().splitlines(), ["klist:-s", "klist:-f"])

    def test_mac_kerberos_wrapper_continues_after_one_host_fails(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            write_executable(bindir / "uname", 'echo Darwin\n')
            write_executable(
                bindir / "ssh",
                'host=""\nfor arg in "$@"; do\n'
                '  case "$arg" in sdfiana|psbuildrc) host="$arg" ;; esac\n'
                'done\necho "ssh:$host" >> "$TRACE"\n[[ "$host" != "sdfiana" ]]\n',
            )

            result = subprocess.run([ROOT / "bin/renew_s3df_krb", "--status"], env=env)
            self.assertEqual(result.returncode, 1)
            lines = trace.read_text().splitlines()
            self.assertEqual(len(lines), 2)
            self.assertIn("sdfiana", lines[0])
            self.assertIn("psbuildrc", lines[1])

    def test_nersc_fedid_no_browser_and_status_arguments(self):
        with tempfile.TemporaryDirectory() as raw:
            temp = pathlib.Path(raw)
            bindir, trace, env = self.base_env(temp)
            home = temp / "home"
            (home / ".ssh").mkdir(parents=True)
            write_executable(
                bindir / "sshproxy",
                'echo "sshproxy:$*" >> "$TRACE"\n: > "$HOME/.ssh/nersc"\n',
            )
            write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\n')
            env["HOME"] = str(home)

            subprocess.run(
                [ROOT / "bin/renew_nersc_key", "--fedid", "--no-browser"],
                env=env,
                check=True,
            )
            lines = trace.read_text().splitlines()
            self.assertEqual(lines[0], "sshproxy:-f -b -o nersc")
            self.assertIn("perlmutter true", lines[1])

            trace.write_text("")
            subprocess.run([ROOT / "bin/renew_nersc_key", "--status"], env=env, check=True)
            lines = trace.read_text().splitlines()
            self.assertEqual(len(lines), 1)
            self.assertTrue(lines[0].startswith("ssh:"))

            trace.write_text("")
            result = subprocess.run(
                [ROOT / "bin/renew_nersc_key", "--status", "--no-verify"], env=env
            )
            self.assertEqual(result.returncode, 2)
            self.assertEqual(trace.read_text(), "")

            write_executable(bindir / "ssh", 'echo "ssh:$*" >> "$TRACE"\nexit 7\n')
            result = subprocess.run(
                [ROOT / "bin/renew_nersc_key", "--status"],
                env=env,
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 7)
            self.assertIn("FAILED (exit 7)", result.stderr)


if __name__ == "__main__":
    unittest.main()
