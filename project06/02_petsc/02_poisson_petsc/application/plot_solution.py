import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path


def load_solution(filename: str):
    """
    Load solution data written as three columns:

        x   y   u

    Returns X, Y, U as 2D arrays suitable for plotting.
    """
    path = Path(filename)

    if not path.exists():
        raise FileNotFoundError(
            f"Could not find {filename}. "
            "Make sure the PETSc code writes the solution to solution.dat."
        )

    data = np.loadtxt(path)

    if data.ndim != 2 or data.shape[1] != 3:
        raise ValueError(
            f"{filename} must contain exactly three columns: x y u."
        )

    x = data[:, 0]
    y = data[:, 1]
    u = data[:, 2]

    x_unique = np.unique(x)
    y_unique = np.unique(y)

    nx = len(x_unique)
    ny = len(y_unique)

    expected_size = nx * ny
    if len(u) != expected_size:
        raise ValueError(
            "The number of solution values does not match the detected grid size."
        )

    # Sort data lexicographically by y then x.
    # This makes reshaping robust even if the output order changes.
    order = np.lexsort((x, y))
    x_sorted = x[order]
    y_sorted = y[order]
    u_sorted = u[order]

    X = x_sorted.reshape(ny, nx)
    Y = y_sorted.reshape(ny, nx)
    U = u_sorted.reshape(ny, nx)

    return X, Y, U


def plot_heatmap(X, Y, U, output_file: str):
    """
    Create a 2D heatmap of the approximate solution.
    """
    fig, ax = plt.subplots(figsize=(6.2, 5.2))

    pcm = ax.pcolormesh(X, Y, U, shading="auto")
    cbar = fig.colorbar(pcm, ax=ax)
    cbar.set_label(r"$u_h(x_1,x_2)$")

    ax.set_xlabel(r"$x_1$")
    ax.set_ylabel(r"$x_2$")
    ax.set_title(r"Approximate solution of $-\Delta u = 20$")

    ax.set_aspect("equal", adjustable="box")

    fig.tight_layout()
    fig.savefig(output_file, bbox_inches="tight")
    plt.close(fig)


def plot_surface(X, Y, U, output_file: str):
    """
    Create a 3D surface plot of the approximate solution.
    """
    fig = plt.figure(figsize=(7.0, 5.5))
    ax = fig.add_subplot(111, projection="3d")

    surf = ax.plot_surface(X, Y, U, linewidth=0, antialiased=True)

    cbar = fig.colorbar(surf, ax=ax, shrink=0.75, pad=0.12)
    cbar.set_label(r"$u_h(x_1,x_2)$")

    ax.set_xlabel(r"$x_1$")
    ax.set_ylabel(r"$x_2$")
    ax.set_zlabel(r"$u_h$")
    ax.set_title(r"Approximate solution of $-\Delta u = 20$")

    fig.tight_layout()
    fig.savefig(output_file, bbox_inches="tight")
    plt.close(fig)


def main():
    X, Y, U = load_solution("solution.dat")

    plot_heatmap(X, Y, U, "solution_heatmap.pdf")
    plot_surface(X, Y, U, "solution_surface.pdf")

    print("Created:")
    print("  solution_heatmap.pdf")
    print("  solution_surface.pdf")
    print()
    print(f"Grid size: {X.shape[1]} x {X.shape[0]}")
    print(f"Minimum solution value: {np.min(U):.8e}")
    print(f"Maximum solution value: {np.max(U):.8e}")


if __name__ == "__main__":
    main()