"""Exercise isolation, conflict rejection, and rollback with real temporary Git repos."""

import contextlib
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest


loader = importlib.machinery.SourceFileLoader("updater", str(Path.home() / ".local/bin/opencode-custom-update"))
spec = importlib.util.spec_from_loader(loader.name, loader)
updater = importlib.util.module_from_spec(spec)
loader.exec_module(updater)


class UpdaterTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="opencode-updater-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.env = os.environ.copy()
        self.env.update(GIT_AUTHOR_NAME="Updater test", GIT_AUTHOR_EMAIL="test@example.invalid", GIT_COMMITTER_NAME="Updater test", GIT_COMMITTER_EMAIL="test@example.invalid")
        self.remote = self.root / "upstream"
        self.git(self.root, "init", "-b", "dev", str(self.remote))
        (self.remote / "restart.txt").write_text("baseline\n")
        (self.remote / "upstream.txt").write_text("baseline\n")
        self.commit(self.remote)
        self.source = self.root / "source"
        self.git(self.root, "clone", str(self.remote), str(self.source))
        self.git(self.source, "checkout", "-b", "custom-tui")
        (self.source / "custom.txt").write_text("committed custom feature\n")
        self.commit(self.source)
        self.state = self.root / "state"
        self.state.mkdir()
        self.data = self.root / "bin"
        self.data.mkdir()
        updater.SOURCE = self.source
        updater.STATE = self.state
        updater.DATA = self.data
        updater.WORK = self.state / "worktree"
        updater.ARGS = SimpleNamespace(check=True, force=False, no_notify=True)
        updater.LOG = None
        # Git's merge process still requires an identity without making a commit.
        original = {key: os.environ.get(key) for key in self.env if key.startswith("GIT_")}
        for key in original:
            os.environ[key] = self.env[key]
        self.addCleanup(self.restore_environment, original)
        self.output = contextlib.redirect_stdout(io.StringIO())
        self.output.__enter__()
        self.addCleanup(self.output.__exit__, None, None, None)

    @staticmethod
    def restore_environment(original):
        for key, value in original.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    def git(self, directory, *arguments):
        return subprocess.check_output(["git", "-C", str(directory), *arguments], env=self.env, stderr=subprocess.DEVNULL).decode()

    def commit(self, directory):
        self.git(directory, "add", ".")
        self.git(directory, "-c", "core.hooksPath=/dev/null", "commit", "-m", "test fixture")

    def signature(self):
        return (self.git(self.source, "rev-parse", "HEAD"), self.git(self.source, "status", "--porcelain"), self.git(self.source, "diff", "--binary", "HEAD"), self.git(self.source, "diff", "--cached", "--binary"))

    def test_preserves_staged_and_unstaged_customizations_and_original_checkout(self):
        (self.source / "restart.txt").write_text("staged restart feature\n")
        self.git(self.source, "add", "restart.txt")
        (self.source / "custom.txt").write_text("unstaged sidebar feature\n")
        (self.remote / "upstream.txt").write_text("new upstream feature\n")
        self.commit(self.remote)
        before = self.signature()
        updater.update()
        self.assertEqual(before, self.signature())
        self.assertEqual((updater.WORK / "restart.txt").read_text(), "staged restart feature\n")
        self.assertEqual((updater.WORK / "custom.txt").read_text(), "unstaged sidebar feature\n")
        self.assertEqual((updater.WORK / "upstream.txt").read_text(), "new upstream feature\n")
        # Reusing the worktree must also preserve the source index and HEAD.
        updater.update()
        self.assertEqual(before, self.signature())

    def test_conflicting_local_patch_leaves_installed_binary_and_source_untouched(self):
        (self.source / "restart.txt").write_text("local restart feature\n")
        (self.remote / "restart.txt").write_text("upstream incompatible feature\n")
        self.commit(self.remote)
        binary = self.data / "opencode"
        binary.write_bytes(b"working executable")
        before = self.signature()
        with self.assertRaises(RuntimeError):
            updater.update()
        self.assertEqual(binary.read_bytes(), b"working executable")
        self.assertEqual(before, self.signature())
        self.assertTrue(self.git(updater.WORK, "diff", "--name-only", "--diff-filter=U").strip())

    def test_untracked_source_is_rejected(self):
        (self.source / "untracked-feature.ts").write_text("custom feature")
        with self.assertRaisesRegex(RuntimeError, "untracked"):
            updater.snapshot()

    def test_unrecognized_worktree_is_never_reset(self):
        updater.WORK.mkdir()
        sentinel = updater.WORK / "user-work.txt"
        sentinel.write_text("keep this")
        head, patch = updater.snapshot()
        with self.assertRaisesRegex(RuntimeError, "unrecognized"):
            updater.prepare(head, patch, head)
        self.assertEqual(sentinel.read_text(), "keep this")

    def test_install_is_atomic_for_existing_readers_and_rollback_holds_rejected_input(self):
        binary = self.data / "opencode"
        binary.write_bytes(b"old executable")
        updater.write_json(self.data / "installed.json", {"fingerprint": "old", "version": "old"})
        candidate = self.root / "candidate"
        candidate.write_bytes(b"new executable")
        with binary.open("rb") as running:
            updater.install(candidate, {"fingerprint": "new", "version": "new"})
            self.assertEqual(running.read(), b"old executable")
        self.assertEqual(binary.read_bytes(), b"new executable")
        self.assertEqual((self.data / "opencode.previous").read_bytes(), b"old executable")
        updater.rollback()
        self.assertEqual(binary.read_bytes(), b"old executable")
        self.assertEqual(updater.read_json(self.data / "installed.json")["version"], "old")
        self.assertEqual(updater.read_json(self.state / "rollback.json")["fingerprint"], "new")


if __name__ == "__main__":
    unittest.main()
