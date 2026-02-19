#!/usr/bin/env python3

from pathlib import Path

# Adjust if needed
STACKING_DIR = Path("/Users/cc/Desktop/hamiltonian/stacking")
SOLUTION_DIR = STACKING_DIR / "stacking_solution"


def file_contains_zero_solution(path: Path) -> bool:
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            if "#Solutions: 0" in line:
                return True
    return False


def main():
    txt_files = sorted(SOLUTION_DIR.glob("*.txt"))

    if not txt_files:
        print("No .txt files found.")
        return

    for file_path in txt_files:
        if file_contains_zero_solution(file_path):
            print(file_path.name)


if __name__ == "__main__":
    main()
