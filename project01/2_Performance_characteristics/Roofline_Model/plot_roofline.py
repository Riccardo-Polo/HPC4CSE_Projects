#!/usr/bin/env python3
import os
import numpy as np
import matplotlib.pyplot as plt

def roofline_curve(P_peak_gflops, B_gbs, I):
    """Return bandwidth line, compute line, and roofline bound."""
    P_bw = B_gbs * I
    P_comp = P_peak_gflops * np.ones_like(I)
    P = np.minimum(P_comp, P_bw)
    I_ridge = P_peak_gflops / B_gbs
    return P_bw, P_comp, P, I_ridge

def make_roofline_both(out_pdf):
    # Match the "simple" look: powers-of-two-ish ticks like the screenshot
    I = 2.0 ** np.linspace(-6, 10, 1200)  # Flops/Byte

    # Phase 1
    P1_peak = 41.6
    B1 = 19.6681
    P1_bw, P1_comp, P1, I1_ridge = roofline_curve(P1_peak, B1, I)

    # Phase 2 (updated bandwidth)
    P2_peak = 39.2
    B2 = 14.20
    P2_bw, P2_comp, P2, I2_ridge = roofline_curve(P2_peak, B2, I)

    # One figure, both rooflines (simple graphics: just the bound lines)
    plt.figure()
    plt.loglog(I, P1, linewidth=2, label="Phase 1 (EPYC 7H12)")
    plt.loglog(I, P2, linewidth=2, label="Phase 2 (EPYC 7763)")

    # Optional: ridge-point markers (still simple)
    plt.scatter([I1_ridge], [P1_peak], zorder=5, s=25)
    plt.scatter([I2_ridge], [P2_peak], zorder=5, s=25)

    plt.xlabel("Operational Intensity $I$ [Flops/Byte]")
    plt.ylabel("Performance $P$ [GFlops/s]")
    plt.title("Naive roofline model (single core) - Euler VII (Phase 1 vs Phase 2)")
    plt.grid(True, which="both")
    plt.legend()

    os.makedirs(os.path.dirname(out_pdf), exist_ok=True)
    plt.savefig(out_pdf, bbox_inches="tight")
    plt.close()

if __name__ == "__main__":
    make_roofline_both("images/roofline_both.pdf")