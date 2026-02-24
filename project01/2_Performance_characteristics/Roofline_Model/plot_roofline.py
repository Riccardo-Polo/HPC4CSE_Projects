#!/usr/bin/env python3
import os
import numpy as np
import matplotlib.pyplot as plt

def make_roofline(P_peak_gflops, B_gbs, out_pdf, title):
    # Operational intensity range (Flops/Byte), log-spaced
    I = np.logspace(-2, 2, 1000)

    # Bandwidth roof (GFlops/s) since (GB/s)*(Flops/Byte) = GFlops/s
    P_bw = B_gbs * I

    # Roofline: min(peak, bandwidth line)
    P = np.minimum(P_peak_gflops, P_bw)

    # Ridge point
    I_ridge = P_peak_gflops / B_gbs

    # Plot
    plt.figure()
    plt.loglog(I, P_bw, label=r"$B \cdot I$ (memory roof)")
    plt.loglog(I, P_peak_gflops * np.ones_like(I), label=r"$P_{\mathrm{peak}}$ (compute roof)")
    plt.loglog(I, P, label="Roofline bound", linewidth=2)
    plt.scatter([I_ridge], [P_peak_gflops], zorder=5, label=rf"Ridge point ($I \approx {I_ridge:.2f}$)")

    plt.xlabel("Operational intensity I [Flops/Byte]")
    plt.ylabel("Performance P [GFlops/s]")
    plt.title(title)
    plt.grid(True, which="both")
    plt.legend()

    os.makedirs(os.path.dirname(out_pdf), exist_ok=True)
    plt.savefig(out_pdf, bbox_inches="tight")
    plt.close()

if __name__ == "__main__":
    # Values from the report (Table roofline_params):
    # Phase 1 (EPYC 7H12): P_peak = 41.6 GFlops/s, STREAM Triad = 19668.1 MB/s = 19.6681 GB/s
    make_roofline(
        P_peak_gflops=41.6,
        B_gbs=19.6681,
        out_pdf="images/roofline_phase1.pdf",
        title="Roofline model (single core) - Euler VII Phase 1 (EPYC 7H12)"
    )

    # Phase 2 (EPYC 7763): P_peak = 39.2 GFlops/s, STREAM Triad = 17459.6 MB/s = 17.4596 GB/s
    make_roofline(
        P_peak_gflops=39.2,
        B_gbs=17.4596,
        out_pdf="images/roofline_phase2.pdf",
        title="Roofline model (single core) - Euler VII Phase 2 (EPYC 7763)"
    )