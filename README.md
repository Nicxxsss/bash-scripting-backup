# Bash Backup Automation

A Bash script that copies files between two local directories with `rsync`, then checks their contents using my [Python backup integrity checker](https://github.com/Nicxxsss/backup-integrity-checker).

I built this project to practice input validation, exit statuses, logging, and combining Bash with Python.

## How it works

The script checks the supplied directories and their access permissions, resolves their paths, and rejects identical or nested source and backup directories.

It runs `rsync -ai` to copy the source directory's contents. If the copy succeeds, it runs the Python checker to compare files using SHA-256. A copy failure stops the script before verification.

The script logs the output from rsync and the Python checker, with timestamps marking the start and result of each stage. Initial validation errors are printed to the terminal and are not recorded in the log. The script returns exit status 0 when copying and verification succeed, or 1 when validation, copying, or verification fails.

## Requirements

- Linux with Bash and GNU Coreutils, including `realpath` and `date`.
- `rsync` and Python 3.
- `rsync` copies subdirectories recursively, but the current Python checker only verifies regular files directly inside the source directory. Subdirectories are skipped by the checker and cause verification to fail.

Both directories must already exist. The user running the script needs access to read the source files and write to the backup.

## Usage

Review these paths in `backup-automation.sh` before running it:

```bash
log_file="$HOME/bash-scripting-backup/backup.log"
checker_script="$HOME/backup-integrity-checker/backup_integrity_checker.py"
```

The log's parent directory must exist and be writable. Keep the log outside both the source and backup directories.

From the project directory, run:

```bash
bash backup-automation.sh "/path/to/source" "/path/to/backup"
printf 'Exit status: %s\n' "$?"
```

## Current limitations

- The Python checker verifies regular files directly inside the source directory. It does not scan subdirectories, and skipped items cause verification to fail.
- Files found only in the backup are not checked or deleted.
- Existing backup files can be overwritten. This version does not keep historical copies.
- Verification compares file contents, not ownership, permissions, or other metadata.
- Files should remain unchanged during copying and verification; the script does not create a filesystem snapshot.

During development, I tested a successful copy, a file-read permission error, a content mismatch that `rsync` skipped because size and modification time matched, and restoration into a separate temporary directory.

## Evidence

- [Backup execution logs](evidence/backup-runs.txt)
- [Restore validation](evidence/restore-validation.txt)
- [Troubleshooting notes](docs/troubleshooting.md)
