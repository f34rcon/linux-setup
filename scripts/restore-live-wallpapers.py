#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import time
from pathlib import Path

PLAYLIST = "Live Wallpapers"
INTERVAL = 300

WALLPAPERS = [
    "Anime/lonely-itachi-in-the-snow-moewalls-com.mp4",
    "Generated/purple_space_loop.mp4",
    "Downloaded/o7dQQuI96xjqpHx_Space DreamScene Live Wallpaper.mp4",
    "Downloaded/9W9n8HdwBaBKsGi_Space Window_2_prob4.mp4",
    "Downloaded/mystic-mountain-temple-hd.mp4",
    "Downloaded/cherry-blossom-waterfall-hd.mp4",
]


def run(*args):
    result = subprocess.run(
        ["waypaper-daemon", *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        raise RuntimeError(
            f"Command failed: waypaper-daemon {' '.join(args)}\n"
            f"{result.stderr.strip()}"
        )
    return result.stdout


def gallery():
    return json.loads(run("images", "list", "--json", "--per-page", "1000"))["data"]


def playlists():
    return json.loads(run("playlist", "list", "--json"))


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} WALLPAPER_BACKUP_DIRECTORY")
        return 2

    root = Path(sys.argv[1]).expanduser().resolve()

    if not root.is_dir():
        raise RuntimeError(f"Wallpaper directory does not exist: {root}")

    files = [(root / relative, Path(relative).stem) for relative in WALLPAPERS]

    missing = [path for path, _ in files if not path.is_file()]
    if missing:
        raise RuntimeError(
            "Missing required wallpaper files:\n"
            + "\n".join(str(path) for path in missing)
        )

    # Start the daemon if it is not already running.
    status = subprocess.run(
        ["waypaper-daemon", "status"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    if status.returncode:
        state_dir = Path(
            os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")
        )
        state_dir.mkdir(parents=True, exist_ok=True)
        log = open(state_dir / "waypaper-daemon.log", "a")
        subprocess.Popen(
            ["waypaper-daemon", "start"],
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )

        for _ in range(30):
            time.sleep(1)
            if subprocess.run(
                ["waypaper-daemon", "status"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode == 0:
                break
        else:
            raise RuntimeError("Waypaper Engine daemon did not start.")

    print("Checking existing gallery...")
    current = gallery()
    ids = {}

    for path, name in files:
        match = next((item for item in current if item["name"] == name), None)

        if match is None:
            print(f"Importing: {path.name}")
            run("images", "add", str(path))

            # Imports are asynchronous; wait for this image to appear.
            for _ in range(120):
                time.sleep(1)
                current = gallery()
                match = next(
                    (item for item in current if item["name"] == name),
                    None,
                )
                if match is not None:
                    break
            else:
                raise RuntimeError(f"Timed out importing {path.name}")
        else:
            print(f"Already imported: {path.name}")

        ids[name] = match["id"]

    ordered_ids = ",".join(str(ids[name]) for _, name in files)

    existing = next(
        (item for item in playlists() if item["name"] == PLAYLIST),
        None,
    )

    if existing:
        print(f"Updating existing '{PLAYLIST}' playlist...")
        old_ids = ",".join(
            str(item["image_id"]) for item in existing.get("images", [])
        )

        if old_ids:
            run(
                "playlist", "update",
                "--name", PLAYLIST,
                "--remove-images", old_ids,
            )

        run(
            "playlist", "update",
            "--name", PLAYLIST,
            "--interval", str(INTERVAL),
            "--order", "ordered",
            "--type", "timer",
            "--add-images", ordered_ids,
        )
    else:
        print("Creating playlist...")
        run(
            "playlist",
            "create",
            PLAYLIST,
            "--interval", str(INTERVAL),
            "--order", "ordered",
            "--type", "timer",
        )
        run(
            "playlist",
            "update",
            "--name", PLAYLIST,
            "--add-images", ordered_ids,
        )

    print("Starting playlist on all connected monitors...")
    run("playlist", "start", "--name", PLAYLIST)

    print("\nWallpaper restoration complete.")
    print(f"Playlist: {PLAYLIST}")
    print(f"Interval: {INTERVAL} seconds")
    print("Order: original six-wallpaper sequence")
    print("Monitor behavior: cloned across connected monitors")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, KeyError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
