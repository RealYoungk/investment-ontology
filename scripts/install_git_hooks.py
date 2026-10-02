#!/usr/bin/env python3
"""Enable tracked commit checks without replacing an existing hook setup."""
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
hooks = root / ".githooks"
current = subprocess.run(["git", "config", "--get", "core.hooksPath"], capture_output=True, text=True)
if current.returncode == 0 and Path(current.stdout.strip()).resolve() != hooks:
    raise SystemExit("An existing core.hooksPath is configured; refusing to replace it.")
common = Path(subprocess.check_output(["git", "rev-parse", "--git-common-dir"], text=True).strip())
existing = [common / "hooks" / name for name in ("pre-commit", "pre-push")]
if current.returncode != 0 and any(p.exists() for p in existing):
    raise SystemExit("An existing commit/push hook is present; refusing to replace it.")
subprocess.run(["git", "config", "--local", "core.hooksPath", str(hooks)], check=True)
print("Installed commit and isolated push checks: " + str(hooks))
