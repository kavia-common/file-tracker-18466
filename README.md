# file-tracker

Track where your files have come from, where they're going to, where they are. I am in process of converting this from the proof-of-concept shell scripts to a perl project. Executable names will change from the `ce_` prefix to something else in the future.

## Installation

Copy the files to your local drive and set your `PATH` to the scripts folder

## How to run (startup)

A universal start script is provided to make the container runnable in preview systems and locally.

- Start via start.sh:
  bash start.sh

- Start via Procfile-compatible runners:
  The repository includes a Procfile with:
    web: bash start.sh

Behavior:
- If a Node.js app is detected (package.json or common Node entry files), it will run it (npm start or node <entry>).
- If a Python entry (main.py) is found, it will execute it.
- If neither is present, it will start a small static help server on port 8000 (if Python is installed) that exposes the repository contents and quick instructions.
- If no suitable runtime is found, it prints CLI usage for the scripts.

Environment variables (optional):
- HOST: host for the help server (default 0.0.0.0)
- PORT: port for the help server (default 8000)

## Examples

    ./scripts/ce_createDb.sh test.sqlite
    # Add three files
    for i in 1 2 3; do
      touch $i.txt
      ./scripts/ce_addFile.sh test.sqlite $i.txt
    done
    
    # Make a few move operations
    ./scripts/ce_mvFile.sh test.sqlite 1.txt 4.txt
    ./scripts/ce_mvFile.sh test.sqlite 4.txt 5.txt
    ./scripts/ce_mvFile.sh test.sqlite 5.txt 54.txt
    
    # check out the file's history
    ./scripts/ce_history.sh test.sqlite 54.txt
    # => should see a few entries describing previous directories of the file
