#!/usr/bin/env bash
# Deterministically builds materials/ALL_SLIDES.md by concatenating
# all weekly slide transcriptions (with > Source: lines stripped)
# and appending the errata from ERRORS.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRANSCRIBED="$SCRIPT_DIR/slides_transcribed"
OUTPUT="$SCRIPT_DIR/../materials/ALL_SLIDES.md"

: > "$OUTPUT"

# Concatenate weeks 01–10, stripping the "> Source:" first line
# and the blank line that follows it.
for week in 01 02 03 04 05 06 07 08 09 10; do
    src="$TRANSCRIBED/week_${week}.md"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: missing $src" >&2
        exit 1
    fi

    # Drop the leading "> Source: ..." line and the blank line after it.
    # The source line is always line 1; line 2 is always blank.
    tail -n +3 "$src"

    # Blank line between weeks (except after the last)
    if [[ "$week" != "10" ]]; then
        echo ""
    fi
done >> "$OUTPUT"

# Append errata section
ERRORS="$TRANSCRIBED/ERRORS.md"
if [[ -f "$ERRORS" ]]; then
    {
        echo ""
        echo "---"
        echo ""
        # Re-title the errors file as an errata appendix:
        # replace the H1 heading, keep everything else.
        sed '1s/^# .*$/# Errata: Known Source Errors/' "$ERRORS"
    } >> "$OUTPUT"
fi

echo "Built $OUTPUT"
