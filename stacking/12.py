import itertools
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

# ------------------------------------------------------------
# Basic utilities
# ------------------------------------------------------------

def adjacent(p, q):
    """Check if two grid points are adjacent."""
    return abs(p[0] - q[0]) + abs(p[1] - q[1]) == 1


# ------------------------------------------------------------
# Endpoint generators (case-based)
# ------------------------------------------------------------

# Case (1): m = 2, arbitrary n
# (s,t)=((0,0),(0,n-1)) or ((1,0),(1,n-1))
def endpoints_m2(n, y_offset=0):
    return [
        ((0, y_offset), (0, y_offset + n - 1)),
        ((1, y_offset), (1, y_offset + n - 1)),
    ]


# Case (2): m even > 2, n = 2
# x1 ≡ x2 (mod 2) and (x1 != x2 or x1=x2 in {0, m-1})
def endpoints_even_m_n2(m, y_offset=0):
    pairs = []
    for x1, x2 in itertools.product(range(m), repeat=2):
        if x1 % 2 != x2 % 2:
            continue
        if x1 != x2 or x1 in {0, m - 1}:
            s = (x1, y_offset)
            t = (x2, y_offset + 1)
            pairs.append((s, t))
    return pairs


# ------------------------------------------------------------
# Stacking logic
# ------------------------------------------------------------

def stack_endpoints(R2_pairs, R1_pairs):
    """
    Return all valid stacked combinations.
    Each entry records:
      - start of whole path
      - end of whole path
      - bridge edge (t_R2, s_R1)
    """
    results = []
    for s2, t2 in R2_pairs:
        for s1, t1 in R1_pairs:
            if adjacent(t2, s1):
                results.append({
                    "combined_start": s2,
                    "combined_end": t1,
                    "t_R2": t2,
                    "s_R1": s1
                })
    return results


# ------------------------------------------------------------
# Visualization helpers
# ------------------------------------------------------------

def draw_grid(ax, m, n, y_offset=0, color="black"):
    for x in range(m + 1):
        ax.plot([x, x], [y_offset, y_offset + n], color=color, lw=1)
    for y in range(n + 1):
        ax.plot([0, m], [y_offset + y, y_offset + y], color=color, lw=1)


def draw_point(ax, p, color, label=None):
    ax.scatter(p[0] + 0.5, p[1] + 0.5, s=100, color=color, zorder=5)
    if label:
        ax.text(p[0] + 0.55, p[1] + 0.55, label, fontsize=9)


def visualize_stacking(m1, n1, m2, n2, stacked_results, max_show=6):
    """
    Visualize stacked rectangles and valid endpoint bridges.
    """
    fig, axes = plt.subplots(1, min(len(stacked_results), max_show),
                             figsize=(4 * max_show, 4))

    if len(stacked_results) == 1:
        axes = [axes]

    for ax, res in zip(axes, stacked_results[:max_show]):
        ax.set_aspect("equal")
        ax.axis("off")

        # Draw R1 (bottom)
        draw_grid(ax, m1, n1, y_offset=0)

        # Draw R2 (top)
        draw_grid(ax, m2, n2, y_offset=n1)

        # Mark points
        draw_point(ax, res["combined_start"], "green", "s")
        draw_point(ax, res["combined_end"], "red", "t")
        draw_point(ax, res["t_R2"], "blue", "t₂")
        draw_point(ax, res["s_R1"], "purple", "s₁")

        # Draw bridge
        x_vals = [res["t_R2"][0] + 0.5, res["s_R1"][0] + 0.5]
        y_vals = [res["t_R2"][1] + 0.5, res["s_R1"][1] + 0.5]
        ax.plot(x_vals, y_vals, "k--", lw=2)

        ax.set_xlim(0, max(m1, m2))
        ax.set_ylim(0, n1 + n2)

    plt.show()


# ------------------------------------------------------------
# Main experiment: your FIRST stacking test
# ------------------------------------------------------------

if __name__ == "__main__":
    # Lower rectangle R1: m=4, n=2
    m1, n1 = 4, 2

    # Upper rectangle R2: m=2, n=2
    m2, n2 = 2, 2

    # Generate endpoints
    R1_pairs = endpoints_even_m_n2(m1, y_offset=0)
    R2_pairs = endpoints_m2(n2, y_offset=n1)

    # Stack
    stacked = stack_endpoints(R2_pairs, R1_pairs)

    print(f"Number of valid stacked Hamiltonian endpoint combinations: {len(stacked)}")
    for r in stacked:
        print(r)

    # Visualize
    visualize_stacking(m1, n1, m2, n2, stacked)
