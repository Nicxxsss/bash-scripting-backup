# Troubleshooting

These cases came from controlled tests during development.

## Copy failed: permission denied

A source file could not be read by the user running the script. The log showed:

```text
rsync: [sender] send_files failed to open "/tmp/backup-preview.SsLroL/source/read-error.8GwPoC": Permission denied (13)
rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1356) [sender=3.4.1]
[2026-10-24T15:54:14-03:00] Backup copy failed
```

The directory permission checks passed, but that did not guarantee access to every file inside it.

`rsync` returned `23`. The Bash script handled the failure by exiting with `1` before starting verification.

For a real backup, inspect the affected file's ownership, permissions and ACLs, then correct the access problem before running the script again. Other files may already have been copied; the script does not roll back the destination.

## Copy succeeded, but verification failed

I created files with different contents in the source and backup:

```text
Source: ORIGINAL
Backup: MODIFIED
```

Both files had the same byte count, including their newline. I used `touch -r` to give the backup file the source file's modification time.

With `rsync -ai`, the matching size and modification time caused the file to be skipped. The copy command succeeded, but the Python checker compared the SHA-256 hashes and detected the difference:

```text
[2026-10-24T16:02:31-03:00] Backup copy completed successfully
[2026-10-24T16:02:31-03:00] Verification started
[INFO] Starting backup integrity verification...
[ERROR] [MODIFIED] 'integrity-test.txt'
```

The Bash script reported a verification failure and returned `1`. This test showed why a successful copy command does not replace content verification.

The current script reports the mismatch without retrying or repairing it. I removed the temporary test files after the test.

Checksum-based transfer selection is a possible future improvement; it is not implemented in this version.
