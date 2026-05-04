# M.L. for High Performance Computing Lab @USI & @ETHZ - malik.lechekhab@usi.ch
"""
    spectral_part(A, fiedler=false)

Compute the bi-partions of graph `A` using spectral method.

If `fiedler` is true, return the entries of the fiedler vector.

# Examples
```julia-repl
julia> spectral_part(A)
 1
 ⋮
 2
```
"""
function spectral_part(A)
    n = size(A)[1]

    if n > 4*10^4
        @warn "graph is large. Computing eigen values may take too long."
    end

    # 1. Construct the Laplacian matrix.
    D = Diagonal(sum(A, dims=2)[:]);
    L = D - A;

    # 2. Compute its eigendecomposition.
    eigvals, eigvecs = eigs(L);
    idx_min = argmin(eigvals[2:end]) + 1; # skip the first eigenvalue (which is zero)
    fiedler_vec = eigvecs[:, idx_min];

    # 3. Partition them around their median value, or 0.
    p1 = findall(fiedler_vec .<= 0);
    p2 = findall(fiedler_vec .> 0);

    # 4. Return the indicator vector
    p = ones(Int, n);
    p[p1] .= 1
    p[p2] .= 2

    return p

end
