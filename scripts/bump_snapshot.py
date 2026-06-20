#!/usr/bin/env python3
"""Bump all custom node hashes in snapshot.json to the latest HEAD of each repo.

Usage:
    python scripts/bump_snapshot.py [--dry-run] [--snapshot snapshot.json]

Reads snapshot.json, fetches the latest HEAD for each git_custom_nodes URL via
git ls-remote, and updates the hash in place. Skips repos where HEAD is
unreachable (private/deleted).
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def get_latest_head(url: str) -> str | None:
    """Return the latest HEAD commit for a git URL, or None on failure."""
    try:
        result = subprocess.run(
            ["git", "ls-remote", url, "HEAD"],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            return None
        # Output: "<hash>\tHEAD"
        return result.stdout.strip().split("\t")[0]
    except (subprocess.TimeoutExpired, OSError):
        return None


def main():
    parser = argparse.ArgumentParser(description="Bump custom node hashes to latest HEAD")
    parser.add_argument("--dry-run", action="store_true", help="Show changes without writing")
    parser.add_argument("--snapshot", default="snapshot.json", help="Path to snapshot.json")
    args = parser.parse_args()

    snapshot_path = Path(args.snapshot)
    if not snapshot_path.exists():
        print(f"Error: {snapshot_path} not found", file=sys.stderr)
        sys.exit(1)

    with open(snapshot_path) as f:
        data = json.load(f)

    nodes = data.get("git_custom_nodes", {})
    if not nodes:
        print("No git_custom_nodes to bump.")
        sys.exit(0)

    updated = 0
    skipped = 0
    errors = 0

    for url, info in nodes.items():
        current = info.get("hash", "")
        latest = get_latest_head(url)

        if latest is None:
            print(f"  SKIP {url} (unreachable)")
            errors += 1
            continue

        if latest == current:
            # Already up to date
            continue

        print(f"  {current[:12]} -> {latest[:12]}  {url.split('/')[-1]}")
        if not args.dry_run:
            info["hash"] = latest
            updated += 1
        else:
            updated += 1

    if args.dry_run:
        print(f"\nDry run: {updated} nodes would be updated, {errors} errors.")
    else:
        with open(snapshot_path, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        print(f"\nUpdated {updated}/{len(nodes)} nodes. {errors} errors.")
        if errors:
            sys.exit(1)


if __name__ == "__main__":
    main()
