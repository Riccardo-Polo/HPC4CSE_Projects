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

    D = Diagonal(vec(sum(A, dims=2)))
    L = Symmetric(D - A)

    if n <= 2000
        eig = eigen(Symmetric(Matrix(L)))
        fiedler_vec = eig.vectors[:, 2]
    else
        eigvals, eigvecs = eigs(L; nev=2, which=:SR, maxiter=10000, tol=1e-8)
        perm = sortperm(real.(eigvals))
        fiedler_vec = real.(eigvecs[:, perm[2]])
    end

    threshold = median(fiedler_vec)

    p1 = findall(fiedler_vec .< threshold)
    p2 = findall(fiedler_vec .>= threshold)

    p = ones(Int, n)
    p[p1] .= 1
    p[p2] .= 2

    return p

end