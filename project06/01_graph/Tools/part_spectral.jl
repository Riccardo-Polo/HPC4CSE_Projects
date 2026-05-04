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

    n = size(A, 1)

    if n == 1
        return ones(Int, 1)
    end

    # 1. Construct the Laplacian matrix.
    D = Diagonal(vec(sum(A, dims=2)))
    L = Symmetric(Matrix(D - A))

    # 2. Compute eigendecomposition.
    eig = eigen(L)

    # 3. Take eigenvector associated with second smallest eigenvalue.
    perm = sortperm(eig.values)
    fiedler_vec = eig.vectors[:, perm[2]]

    # 4. Balanced partition by sorting the Fiedler vector.
    order = sortperm(fiedler_vec)

    p = ones(Int, n)

    n1 = div(n, 2)
    p[order[1:n1]] .= 1
    p[order[n1+1:end]] .= 2

    return p

end