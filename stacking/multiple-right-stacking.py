import os
from itertools import product

# ==================================================
# Global constraint
# ==================================================

MAX_M = 15
NUM_LEVELS = 4   # change to 4, 5, 6, ...
NUM_EXAMPLES = 10
OUTPUT_DIR = "stacking_examples_4"

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


def generate_valid_stacks():
    valid = []

    for combo in product(CASES, repeat=NUM_LEVELS):
        ok = True
        for i in range(NUM_LEVELS - 1):
            upper = combo[i]
            lower = combo[i + 1]

            if not can_be_strictly_larger(
                CASES[upper]["m"],
                CASES[lower]["m"]
            ):
                ok = False
                break

        if ok:
            valid.append(combo)

    return valid


def generate_examples_for_case(case_tuple, count=NUM_EXAMPLES):
    examples = []

    def backtrack(level, current_m_values):
        if len(examples) >= count:
            return

        if level == NUM_LEVELS:
            ex = {}
            for i, (case_name, m_val) in enumerate(zip(case_tuple, current_m_values)):
                n_val = sample_n(CASES[case_name]["n"])
                ex[f"R{i+1}"] = (m_val, n_val)
            examples.append(ex)
            return

        case_name = case_tuple[level]

        if level == 0:
            m_range = range(2, MAX_M + 1)
        else:
            prev_m = current_m_values[level - 1]
            m_range = range(2, prev_m)

        for m_val in m_range:
            if m_valid(m_val, CASES[case_name]["m"]):
                backtrack(level + 1, current_m_values + [m_val])

    backtrack(0, [])
    return examples

def write_all_cases(output_dir=OUTPUT_DIR):
    os.makedirs(output_dir, exist_ok=True)
    stacks = generate_valid_stacks()

    for case_tuple in stacks:
        examples = generate_examples_for_case(case_tuple)

        if not examples:
            continue

        filename = "_".join(
            [f"R{i+1}-{case_tuple[i]}" for i in range(NUM_LEVELS)]
        ) + ".txt"

        path = os.path.join(output_dir, filename)

        with open(path, "w") as f:
            f.write("Stacking Case\n")
            f.write("-----------------------------\n")

            for i, case_name in enumerate(case_tuple):
                label = "bottom" if i == 0 else (
                    "top" if i == NUM_LEVELS - 1 else "middle"
                )
                f.write(
                    f"R{i+1} ({label}): {case_name} — {CASES[case_name]['desc']}\n"
                )

            f.write("\n")

            for i, ex in enumerate(examples, 1):
                f.write(f"Example {i}\n")
                for level in range(NUM_LEVELS):
                    m_val, n_val = ex[f"R{level+1}"]
                    f.write(
                        f"  R{level+1}: m={m_val}, n={n_val}\n"
                    )
                f.write("\n")

    print(
        f"All stacking examples written to '{output_dir}/' "
        f"({NUM_LEVELS} levels, m ≤ {MAX_M})"
    )

# ==================================================
# Run
# ==================================================

if __name__ == "__main__":
    write_all_cases()
