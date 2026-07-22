#!/usr/bin/env python3
"""
apply-foot-colors.py <colors.json> <foot.ini>

Rewrites the color section of foot.ini with the pywal-generated
palette, preserving everything else in the file exactly as-is.
"""

import json
import re
import sys

FOOT_ALPHA = "0.85"

def hex6(color):
    return color.lstrip("#").lower()


def build_colors_block(colors, special):
    lines = ["[colors-dark]"]
    lines.append(f"foreground={hex6(special['foreground'])}")
    lines.append(f"background={hex6(special['background'])}")
    lines.append(f"alpha={FOOT_ALPHA}")
    lines.append(f"blur=yes")

    for i in range(8):
        lines.append(f"regular{i}={hex6(colors[f'color{i}'])}")
    for i in range(8):
        lines.append(f"bright{i}={hex6(colors[f'color{8 + i}'])}")

    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) != 3:
        print("Usage: apply-foot-colors.py <colors.json> <foot.ini>", file=sys.stderr)
        sys.exit(1)

    colors_json_path, foot_ini_path = sys.argv[1], sys.argv[2]

    with open(colors_json_path, "r") as f:
        data = json.load(f)

    colors_block = build_colors_block(data["colors"], data["special"])

    with open(foot_ini_path, "r") as f:
        content = f.read()

    dark_pattern = re.compile(r"\[colors-dark\].*?(?=\n\[|\Z)", re.DOTALL)
    old_pattern = re.compile(r"\[colors\].*?(?=\n\[|\Z)", re.DOTALL)

    if dark_pattern.search(content):
        new_content = dark_pattern.sub(colors_block.rstrip("\n") + "\n", content, count=1)
    elif old_pattern.search(content):
        new_content = old_pattern.sub(colors_block.rstrip("\n") + "\n", content, count=1)
    else:
        separator = "" if content.endswith("\n\n") else ("\n\n" if content.endswith("\n") else "\n\n")
        new_content = content + separator + colors_block

    with open(foot_ini_path, "w") as f:
        f.write(new_content)

    print(f"foot.ini updated ([colors-dark]): {foot_ini_path}")


if __name__ == "__main__":
    main()
