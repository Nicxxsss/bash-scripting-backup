#!/usr/bin/bash

if [[ $# -ne 2 ]]; then
	printf 'Usage: bash %q <source> <backup>\n' "$0" >&2
	exit 1
fi

source_dir="$1"
backup_dir="$2"

if [[ ! -d "$source_dir" ]]; then
	printf 'Error: source directory is not an existing directory: %q\n' "$source_dir" >&2
	exit 1
fi

if [[ ! -d "$backup_dir" ]]; then
	printf 'Error: backup directory is not an existing directory: %q\n' "$backup_dir" >&2
	exit 1
fi
printf 'Source: %s\n' "$source_dir"
printf 'Backup: %s\n' "$backup_dir"

if [[ "$source_dir" -ef "$backup_dir" ]]; then
	printf 'Error: source and backup directories must be different\n' >&2
	exit 1
fi

if [[ ! -r "$source_dir" || ! -x "$source_dir" ]]; then
	printf 'Permission error on source directory\n' >&2
	exit 1
fi

if [[ ! -r "$backup_dir" || ! -x "$backup_dir" || ! -w "$backup_dir" ]]; then
	printf 'Permission error on backup directory\n' >&2
	exit 1
fi

if IFS= read -r -d '' resolved_source < <(realpath -e -z -- "$source_dir"); then
        printf 'Resolved source: %q\n' "$resolved_source"
else
        printf 'Could not resolve source\n' >&2
        exit 1
fi

if IFS= read -r -d '' resolved_backup < <(realpath -e -z -- "$backup_dir"); then
        printf 'Resolved backup: %q\n' "$resolved_backup"
else
        printf 'Could not resolve backup\n' >&2
        exit 1
fi

parent="$resolved_source"
candidate="$resolved_backup"

if [[ "$candidate" == "${parent%/}/"* ]]; then
	printf 'Error: backup directory is inside source\n' >&2
	exit 1
fi

if [[ "$parent" == "${candidate%/}/"* ]]; then
	printf 'Error: source directory is inside backup\n' >&2
	exit 1
fi

log_file="$HOME/bash-scripting-backup/backup.log"
checker_script="$HOME/backup-integrity-checker/backup_integrity_checker.py"

if [[ ! -f "$checker_script" || ! -r "$checker_script" ]]; then
    printf 'Error: integrity checker is missing or unreadable: %q\n' \
        "$checker_script" >&2
    exit 1
fi

printf '[%s] Backup started\n' "$(date -Is)" >> "$log_file"

if rsync -ai -- "$resolved_source/" "$resolved_backup/" >> "$log_file" 2>&1; then
    printf 'Backup copy completed successfully\n'
    printf '[%s] Backup copy completed successfully\n' "$(date -Is)" >> "$log_file"
else
    printf 'Error: backup copy failed\n' >&2
    printf '[%s] Backup copy failed\n' "$(date -Is)" >> "$log_file"
    exit 1
fi

printf '[%s] Verification started\n' "$(date -Is)" >> "$log_file"

if python3 "$checker_script" "$resolved_source" "$resolved_backup" >> "$log_file" 2>&1; then
    printf 'Backup verification passed\n'
    printf '[%s] Backup verification passed\n' "$(date -Is)" >> "$log_file"
else
    printf 'Error: backup verification failed\n' >&2
    printf '[%s] Backup verification failed\n' "$(date -Is)" >> "$log_file"
    exit 1
fi
