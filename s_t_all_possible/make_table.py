import os
import re
import csv
from collections import defaultdict

ROOT_DIR = "."   # run from s_t_all_possible/
OUTPUT_CSV = "m_by_n_st_grid.csv"

FOLDER_RE = re.compile(r"paths_m(\d+)_n(\d+)")
FILE_RE = re.compile(
    r"paths_m\d+_n\d+_S\((\d+),(\d+)\)_T\((\d+),(\d+)\)\.txt"
)

def parse_file(path):
    m = n = count = None
    S = T = None

    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("m="):
                m = int(line[2:])
            elif line.startswith("n="):
                n = int(line[2:])
            elif line.startswith("S="):
                S = line[2:]
            elif line.startswith("T="):
                T = line[2:]
            elif line.startswith("count="):
                count = int(line[6:])

    return m, n, S, T, count


def main():
    # data[m][n][Sx][Tx] = count
    data = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    ns_by_m = defaultdict(set)

    # read all files
    for folder in os.listdir(ROOT_DIR):
        folder_path = os.path.join(ROOT_DIR, folder)
        if not os.path.isdir(folder_path):
            continue

        if not FOLDER_RE.match(folder):
            continue

        for fname in os.listdir(folder_path):
            match = FILE_RE.match(fname)
            if not match:
                continue

            full_path = os.path.join(folder_path, fname)
            m, n, S, T, count = parse_file(full_path)

            Sx = int(S[1:-1].split(",")[0])
            Tx = int(T[1:-1].split(",")[0])

            data[m][n][Sx][Tx] = count
            ns_by_m[m].add(n)

    with open(OUTPUT_CSV, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)

        for m in sorted(data.keys()):
            ns = sorted(ns_by_m[m])

            # header row for this m
            header = []
            for n in ns:
                header += ["m", "n", "S", "T", "count"]
            writer.writerow(header)

            # rows: enumerate Sx, Tx
            for Sx in range(m):
                for Tx in range(m):
                    row = []
                    for n in ns:
                        S = f"({Sx},0)"
                        T = f"({Tx},{n-1})"
                        count = data[m][n].get(Sx, {}).get(Tx, "")
                        row += [m, n, S, T, count]
                    writer.writerow(row)

            # empty line between m blocks
            writer.writerow([])

    print(f"CSV written to {OUTPUT_CSV}")


if __name__ == "__main__":
    main()
