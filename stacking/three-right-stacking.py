import os
from itertools import product

# ==================================================
# Global constraint
# ==================================================

MAX_M = 15
NUM_EXAMPLES = 10
OUTPUT_DIR = "stacking_examples_reverse"

# ==================================================
# Case definitions
# ==================================================

CASES = {
    "C1": {"m": "eq2", "n": "any", "desc": "m = 2"},
    "C2": {"m": "even>2", "n": "eq2", "desc": "m even > 2, n = 2"},
    "C3": {"m": "even>2", "n": "even>2", "desc": "m even > 2, n even > 2"},
    "C4": {"m": "even>2", "n": "eq3", "desc": "m even > 2, n = 3"},
    "C5": {"m": "even>2", "n": "odd>3", "desc": "m even > 2, n odd > 3"},
    "C6": {"m": "eq3", "n": "any", "desc": "m = 3"},
    "C7": {"m": "odd>3", "n": "eq2", "desc": "m odd > 3, n = 2"},
    "C8": {"m": "odd>3", "n": "even>2", "desc": "m odd > 3, n even > 2"},
    "C9": {"m": "odd>3", "n": "odd", "desc": "m odd > 3, n odd"},
}

# ==================================================
# Helpers: membership tests
# ==================================================

def m_valid(m, rule):
    if rule == "eq2":
        return m == 2
    if rule == "eq3":
        return m == 3
    if rule == "even>2":
        return m > 2 and m % 2 == 0
    if rule == "odd>3":
        return m > 3 and m % 2 == 1
    return False


def sample_n(rule):
    if rule == "eq2":
        return 2
    if rule == "eq3":
        return 3
    if rule == "even>2":
        return 4
    if rule == "odd>3":
        return 5
    if rule == "odd":
        return 5
    return 4


def can_be_strictly_larger(ruleA, ruleB):
    for mA in range(2, MAX_M + 1):
        for mB in range(2, MAX_M + 1):
            if mA > mB and m_valid(mA, ruleA) and m_valid(mB, ruleB):
                return True
    return False


# ==================================================
# Generate valid stacking case triplets
# ==================================================

def generate_valid_triplets():
    valid = []
    for R1, R2, R3 in product(CASES, repeat=3):
        if (
            can_be_strictly_larger(CASES[R1]["m"], CASES[R2]["m"])
            and can_be_strictly_larger(CASES[R2]["m"], CASES[R3]["m"])
        ):
            valid.append((R1, R2, R3))
    return valid


# ==================================================
# Generate concrete examples (m ≤ 15 enforced)
# ==================================================

def generate_examples_for_case(R1, R2, R3, count=NUM_EXAMPLES):
    examples = []

    for m1 in range(2, MAX_M + 1):
        if not m_valid(m1, CASES[R1]["m"]):
            continue
        for m2 in range(2, m1):
            if not m_valid(m2, CASES[R2]["m"]):
                continue
            for m3 in range(2, m2):
                if not m_valid(m3, CASES[R3]["m"]):
                    continue

                n1 = sample_n(CASES[R1]["n"])
                n2 = sample_n(CASES[R2]["n"])
                n3 = sample_n(CASES[R3]["n"])

                examples.append({
                    "R1": (m3, n3),
                    "R2": (m2, n2),
                    "R3": (m1, n1),
                })

                if len(examples) == count:
                    return examples

    return examples


# ==================================================
# Output
# ==================================================

def write_all_cases(output_dir=OUTPUT_DIR):
    os.makedirs(output_dir, exist_ok=True)
    triplets = generate_valid_triplets()

    for R1, R2, R3 in triplets:
        examples = generate_examples_for_case(R1, R2, R3)

        if not examples:
            continue  # skip structurally valid but numerically empty cases

        filename = f"R1-{R1}_R2-{R2}_R3-{R3}.txt"
        path = os.path.join(output_dir, filename)

        with open(path, "w") as f:
            f.write("Stacking Case\n")
            f.write("-----------------------------\n")
            f.write(f"R1 (bottom): {R1} — {CASES[R3]['desc']}\n")
            f.write(f"R2 (middle): {R2} — {CASES[R2]['desc']}\n")
            f.write(f"R3 (top):    {R3} — {CASES[R1]['desc']}\n\n")

            for i, ex in enumerate(examples, 1):
                f.write(f"Example {i}\n")
                f.write(f"  R1: m={ex['R1'][0]}, n={ex['R1'][1]}\n")
                f.write(f"  R2: m={ex['R2'][0]}, n={ex['R2'][1]}\n")
                f.write(f"  R3: m={ex['R3'][0]}, n={ex['R3'][1]}\n")
                f.write("\n")

    print(f"All stacking examples written to '{output_dir}/' (m ≤ {MAX_M})")


# ==================================================
# Run
# ==================================================

if __name__ == "__main__":
    write_all_cases()
