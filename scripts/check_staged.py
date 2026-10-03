#!/usr/bin/env python3
"""Fast commit gate: check the index without changing the working tree."""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def main():
    run("git", "diff", "--cached", "--check")
    paths = subprocess.check_output([
        "git", "diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z"
    ]).decode().split("\0")
    excluded = (
        "investment_ontology_serverpod_client/",
        "investment_ontology_serverpod_server/lib/src/generated/",
        "investment_ontology_serverpod_server/test/integration/test_tools/",
    )
    dart_paths = [p for p in paths if p.endswith(".dart") and not p.startswith(excluded)]
    if not dart_paths:
        return
    if not shutil.which("dart"):
        raise SystemExit("Commit check requires Dart on PATH.")
    with tempfile.TemporaryDirectory(prefix="alfinder-staged-") as temporary:
        snapshot = Path(temporary)
        # Preserve tracked formatter settings and package language constraints.
        tracked = subprocess.check_output("git ls-files -z".split()).decode().split("\0")
        settings = [p for p in tracked if p.endswith(("analysis_options.yaml", "pubspec.yaml"))]
        for name in dict.fromkeys(settings + dart_paths):
            content = subprocess.run(["git", "show", ":" + name], capture_output=True)
            if content.returncode:
                continue  # A config file may be deleted in this commit.
            destination = snapshot / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(content.stdout)
        # Resolve imported formatter settings exactly as the real checkout does.
        repository = Path(subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True).strip())
        config_path = repository / ".dart_tool/package_config.json"
        if not config_path.exists():
            raise SystemExit("Run flutter pub get before the commit format gate.")
        config = json.loads(config_path.read_text())
        for package in config["packages"]:
            uri = package["rootUri"]
            if ":" not in uri:
                package["rootUri"] = (config_path.parent / uri).resolve().as_uri()
        target = snapshot / ".dart_tool/package_config.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(config))
        run("dart", "format", "--output=none", "--set-exit-if-changed", *dart_paths,
            cwd=snapshot)
    print("Staged whitespace and Dart formatting checks passed.")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode)
