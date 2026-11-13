import os
import pathlib
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
            self.assertIn("sdfiana", lines[2])
            self.assertIn("renew_remote_access --status --with-nersc", lines[2])
            self.assertIn("psbuildrc", lines[3])
            self.assertIn("renew_remote_access --status", lines[3])

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

    def test_sdf_key_prefers_ed25519_and_calls_agent_before_registration(self):
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
            env.update({
                "HOME": str(home),
                "SSH_AGENT_START_HELPER": str(agent),
                "SDF_SSH_COPY_ID_COMMAND": str(copy_id),
            })

            subprocess.run([ROOT / "bin/renew_sdf_key"], env=env, check=True)
            lines = trace.read_text().splitlines()
            self.assertEqual(lines[0], f"agent:{ssh_dir / 'id_ed25519'}")
            self.assertIn(f"-i {ssh_dir / 'id_ed25519.pub'}", lines[1])

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


if __name__ == "__main__":
    unittest.main()
