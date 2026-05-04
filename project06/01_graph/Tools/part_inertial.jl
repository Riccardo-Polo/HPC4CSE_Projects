# M.L. for High Performance Computing Lab @USI & @ETHZ - malik.lechekhab@usi.ch
"""
    inertial_part(A, coords)

Compute the bi-partions of graph `A` using inertial method based on the
`coords` of the graph.

# Examples
```julia-repl
julia> inertial_part(A, coords)
 1
 ⋮
 2
```
"""
function inertial_part(A, coords)

    p = ones(Int, size(coords, 1))

    xbar = mean(coords[:, 1])
    ybar = mean(coords[:, 2])

    Sxx = sum((coords[:, 1] .- xbar) .^ 2)
    Syy = sum((coords[:, 2] .- ybar) .^ 2)
    Sxy = sum((coords[:, 1] .- xbar) .* (coords[:, 2] .- ybar))

    M = Symmetric([Syy -Sxy;
                   -Sxy Sxx])

    eigvals, eigvecs = eigs(M; nev=1, which=:SM)
    eigv = real.(eigvecs[:, 1])

    p1, p2 = partition(coords, eigv)

    p[p1] .= 1
    p[p2] .= 2

    return p
end