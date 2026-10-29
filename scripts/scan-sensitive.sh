#!/usr/bin/env bash
set -euo pipefail

# Scan staged files (or files passed as arguments) for forbidden extensions,
# oversized files (> 5 MB), and sensitive content patterns.

MAX_SIZE=$((5 * 1024 * 1024))
CURRENT_USER="${USER:-$( id -un 2>/dev/null || echo nepo )}"

if [ "$#" -gt 0 ]; then
    FILES=("$@")
else
    mapfile -t FILES < <(git diff --cached --name-only --diff-filter=ACMR)
fi

if [ "${#FILES[@]}" -eq 0 ]; then
    exit 0
fi

FAIL=0

# Sensitive regex patterns (case-insensitive)
SECRET_REGEX='(password|senha|passwd|secret|token|api[_-]?key|ghp_|gho_|github_pat_|BEGIN [A-Z0-9 ]*PRIVATE KEY)'
MAC_REGEX='([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'
UUID_REGEX='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
SERIAL_REGEX='\bserial\b'
HOME_REGEX="/home/${CURRENT_USER}\b"

for f in "${FILES[@]}"; do
    [ -e "$f" ] || continue

    # 1. Block .agents/memory/ files
    if [[ "$f" == .agents/memory/* ]]; then
        echo "[BLOCKED] Memory file must not be committed: $f" >&2
        FAIL=1
        continue
    fi

    # 2. Block forbidden extensions and patterns from .gitignore
    case "$(basename "$f")" in
        *.img|*.iso|*.zip|*.xz|*.zst|*.tar.gz|*.ri|*.tplg|*.bin|jinlon-pack*|*.log|*.raw|*.bak|*.bak-*)
            echo "[BLOCKED] Forbidden file extension or binary artifact: $f" >&2
            FAIL=1
            continue
            ;;
    esac

    # 3. Block files larger than 5 MB
    FILE_SIZE=$(stat -c%s "$f" 2>/dev/null || echo 0)
    if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
        echo "[BLOCKED] File exceeds 5 MB limit (${FILE_SIZE} bytes): $f" >&2
        FAIL=1
        continue
    fi

    # Skip self-inspection of the scanner and rules files that document these exact terms
    if [[ "$f" == "scripts/scan-sensitive.sh" ]] || [[ "$f" == .agents/rules/* ]] || [[ "$f" == .agents/skills/* ]] || [[ "$f" == .agents/workflows/* ]]; then
        # Still check for actual home path and real tokens/MACs/UUIDs in rules/scripts
        if grep -E -i -n "(ghp_[A-Za-z0-9]{10,}|gho_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]{10,}|BEGIN [A-Z0-9 ]*PRIVATE KEY)" "$f" >/dev/null 2>&1; then
            echo "[BLOCKED] Real token or private key detected in $f" >&2
            FAIL=1
        fi
        if grep -E -i -n "$MAC_REGEX" "$f" >/dev/null 2>&1; then
            echo "[BLOCKED] MAC address detected in $f" >&2
            FAIL=1
        fi
        if grep -E -i -n "$UUID_REGEX" "$f" >/dev/null 2>&1; then
            echo "[BLOCKED] UUID detected in $f" >&2
            FAIL=1
        fi
        if grep -E -i -n "$HOME_REGEX" "$f" >/dev/null 2>&1; then
            echo "[BLOCKED] Local user home path (/home/${CURRENT_USER}) detected in $f" >&2
            FAIL=1
        fi
        continue
    fi

    # 4. Content checks for all regular files
    if grep -E -i -n "$SECRET_REGEX" "$f" >&2; then
        echo "[BLOCKED] Sensitive keyword/secret pattern matched in: $f" >&2
        FAIL=1
    fi

    if grep -E -i -n "$MAC_REGEX" "$f" >&2; then
        echo "[BLOCKED] MAC address pattern matched in: $f" >&2
        FAIL=1
    fi

    if grep -E -i -n "$UUID_REGEX" "$f" >&2; then
        echo "[BLOCKED] UUID pattern matched in: $f" >&2
        FAIL=1
    fi

    if grep -E -i -n "$SERIAL_REGEX" "$f" >&2; then
        echo "[BLOCKED] Forbidden word 'serial' matched in: $f" >&2
        FAIL=1
    fi

    if grep -E -i -n "$HOME_REGEX" "$f" >&2; then
        echo "[BLOCKED] Local user home path matched in: $f" >&2
        FAIL=1
    fi
done

if [ "$FAIL" -ne 0 ]; then
    echo "Commit aborted by scripts/scan-sensitive.sh." >&2
    exit 1
fi

exit 0
