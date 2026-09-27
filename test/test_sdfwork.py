import pathlib
import runpy
import subprocess
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class SdfworkTests(unittest.TestCase):
    def test_shell_scripts_parse(self):
        for relative in (
            "bin/sdfwork",
            "bin/renew_s3df_key",
            "bin/install-sdfwork",
            "scripts/verify-s3df-hosts.sh",
        ):
            subprocess.run(["bash", "-n", str(ROOT / relative)], check=True)

    def test_python_scripts_compile(self):
        for relative in ("bin/sdfwork-terminal", "bin/sdfwork-remote"):
            source = (ROOT / relative).read_bytes()
            compile(source, str(ROOT / relative), "exec")

    def test_terminal_command_stays_short(self):
        namespace = runpy.run_path(str(ROOT / "bin/sdfwork-terminal"))
        command = namespace["terminal_command"](
            {"host": "sdfiana", "remote_helper": "~/bin/sdfwork-remote"},
            {"id": "11111111-2222-3333-4444-555555555555"},
        )
        self.assertLess(len(command), 180)
        self.assertIn("--terminal", command)
        self.assertNotIn("worktree", command)

    def test_sources_do_not_embed_home_directories_or_live_ids(self):
        sources = "\n".join(
            (ROOT / relative).read_text()
            for relative in (
                "bin/sdfwork",
                "bin/sdfwork-terminal",
                "bin/sdfwork-remote",
                "bin/install-sdfwork",
            )
        )
        self.assertNotIn("/Users/", sources)
        self.assertNotIn("/sdf/home/", sources)
        self.assertNotIn("01a0e03c", sources)


if __name__ == "__main__":
    unittest.main()
