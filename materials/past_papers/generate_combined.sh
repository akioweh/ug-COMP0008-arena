#!/bin/bash
set -e

# Change directory to where the script is located
cd "$(dirname "$0")"

for year in 2023 2024 2025; do
  output="COMP0008_${year}_answers.md"
  echo "> Reference answers for [COMP0008_${year}.md](COMP0008_${year}.md)." > "$output"
  echo "> Per-question source files: \`answers/${year}/Q*.md\`." >> "$output"
  echo "> Generated $(date -I) by parallel subagents grounded in \`materials/\`." >> "$output"
  echo "" >> "$output"
  echo "# COMP0008 $year — Reference Answers" >> "$output"
  echo "" >> "$output"
  
  # Concatenate files in order Q1, Q2, Q3, etc.
  for f in $(ls answers/${year}/Q*.md | sort -V); do
    cat "$f" >> "$output"
    echo "" >> "$output"
  done
  echo "Regenerated materials/past_papers/$output"
done
