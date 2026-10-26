#!/bin/sh
# Claude Code status line: RAM in use (total minus available), red above 80%.
cat >/dev/null
awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2}
  END {
    u = (t - a) / 1048576; g = t / 1048576; p = 100 * (t - a) / t
    c = p >= 80 ? "\033[38;2;255;92;92m" : "\033[38;2;57;211;83m"
    printf "%sRAM %.1f/%.0f GB\033[0m\n", c, u, g
  }' /proc/meminfo
