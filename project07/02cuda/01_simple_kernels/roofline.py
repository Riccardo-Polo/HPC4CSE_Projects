from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


# Roofline parameters for NVIDIA GeForce RTX 2080 Ti.
# Units:
#   P_peak: GFLOP/s
#   B_GPU:  GB/s
#   I:      FLOP/byte
B_GPU = 616.0
P_PEAK_FP32 = 13450.56
P_PEAK_FP64 = 420.33

OUTPUT_FILE = Path("roofline_fp32_fp64.pdf")

KERNEL_POINTS_64 = [
    ("axpy", 2.0 / (3.0 * 8.0), 46.2073),
    ("add scaled diff", 3.0 / (4.0 * 8.0), 52.7040),
    ("scaled diff", 2.0 / (3.0 * 8.0), 46.1247),
    ("scale", 1.0 / (2.0 * 8.0), 33.9054),
    ("linear combination", 3.0 / (3.0 * 8.0), 69.1512),
]

KERNEL_POINTS_32 = [
    ("axpy", 2.0 / (3.0 * 4.0), 91.7736),
    ("add scaled diff", 3.0 / (4.0 * 4.0), 104.988),
    ("scaled diff", 2.0 / (3.0 * 4.0), 91.798),
    ("scale", 1.0 / (2.0 * 4.0), 67.0205),
    ("linear combination", 3.0 / (3.0 * 4.0), 137.747),
]


def attainable_performance(intensity, peak_performance, memory_bandwidth):
    """Roofline model: P(I) = min(P_peak, B * I)."""
    return np.minimum(peak_performance, memory_bandwidth * intensity)


def main():
    i_ridge_fp32 = P_PEAK_FP32 / B_GPU
    i_ridge_fp64 = P_PEAK_FP64 / B_GPU

    intensity = np.logspace(-2, 3, 1000)

    perf_fp32 = attainable_performance(intensity, P_PEAK_FP32, B_GPU)
    perf_fp64 = attainable_performance(intensity, P_PEAK_FP64, B_GPU)

    fig, ax = plt.subplots(figsize=(8.0, 5.5))

    ax.loglog(
        intensity,
        perf_fp32,
        color="tab:blue",
        linewidth=2.5,
        label=rf"FP32 roofline, $P_{{peak}}={P_PEAK_FP32/1000:.2f}$ TFLOP/s",
    )
    ax.loglog(
        intensity,
        perf_fp64,
        color="tab:red",
        linewidth=2.5,
        label=rf"FP64 roofline, $P_{{peak}}={P_PEAK_FP64/1000:.2f}$ TFLOP/s",
    )

    ax.loglog(
        intensity,
        B_GPU * intensity,
        color="0.35",
        linestyle="--",
        linewidth=1.8,
        label=rf"Memory bandwidth, $B_{{GPU}}={B_GPU:.0f}$ GB/s",
    )

    ax.scatter(
        [i_ridge_fp32, i_ridge_fp64],
        [P_PEAK_FP32, P_PEAK_FP64],
        color=["tab:blue", "tab:red"],
        s=55,
        zorder=5,
    )

    ax.axvline(i_ridge_fp32, color="tab:blue", linestyle=":", linewidth=1.4)
    ax.axvline(i_ridge_fp64, color="tab:red", linestyle=":", linewidth=1.4)

    ax.annotate(
        rf"$I_{{ridge,FP32}}={i_ridge_fp32:.2f}$ FLOP/byte",
        xy=(i_ridge_fp32, P_PEAK_FP32),
        xytext=(1.25 * i_ridge_fp32, 0.65 * P_PEAK_FP32),
        color="tab:blue",
        arrowprops=dict(arrowstyle="->", color="tab:blue", lw=1.0),
    )
    ax.annotate(
        rf"$I_{{ridge,FP64}}={i_ridge_fp64:.2f}$ FLOP/byte",
        xy=(i_ridge_fp64, P_PEAK_FP64),
        xytext=(0.06, 1.12 * P_PEAK_FP64),
        color="tab:red",
        arrowprops=dict(arrowstyle="->", color="tab:red", lw=1.0),
    )

    point_colors = ["tab:green", "tab:olive", "tab:cyan", "tab:orange", "tab:purple"]
    for (name, intensity_value, performance_value), color in zip(KERNEL_POINTS_64, point_colors):
        ax.scatter(
            [intensity_value],
            [performance_value],
            color=color,
            s=70,
            zorder=10,
        )
        ax.annotate(
            name,
            xy=(intensity_value, performance_value),
            xytext=(1.08 * intensity_value, 1.08 * performance_value),
            color=color,
            fontsize=9,
            arrowprops=dict(arrowstyle="->", color=color, lw=0.9),
        )

    point_colors = ["tab:green", "tab:olive", "tab:cyan", "tab:orange", "tab:purple"]
    for (name, intensity_value, performance_value), color in zip(KERNEL_POINTS_32, point_colors):
        ax.scatter(
            [intensity_value],
            [performance_value],
            color=color,
            s=70,
            zorder=10,
        )
        ax.annotate(
            name,
            xy=(intensity_value, performance_value),
            xytext=(1.08 * intensity_value, 1.08 * performance_value),
            color=color,
            fontsize=9,
            arrowprops=dict(arrowstyle="->", color=color, lw=0.9),
        )

    ax.set_title("Roofline model for NVIDIA GeForce RTX 2080 Ti")
    ax.set_xlabel("Arithmetic intensity [FLOP/byte]")
    ax.set_ylabel("Attainable performance [GFLOP/s]")
    ax.set_xlim(1e-2, 1e3)
    ax.set_ylim(1e0, 3e4)
    ax.grid(True, which="both", linestyle=":", linewidth=0.7, alpha=0.7)
    ax.legend(loc="lower right")

    fig.tight_layout()
    fig.savefig(OUTPUT_FILE, bbox_inches="tight")

    print(f"Saved figure to {OUTPUT_FILE}")
    print(f"I_ridge_FP32 = {i_ridge_fp32:.2f} FLOP/byte")
    print(f"I_ridge_FP64 = {i_ridge_fp64:.2f} FLOP/byte")


if __name__ == "__main__":
    main()
