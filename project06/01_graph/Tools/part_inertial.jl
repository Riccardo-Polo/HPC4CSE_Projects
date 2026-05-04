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

    p = ones(Int, size(coords)[1])

    # 1. Compute the center of mass.
    xbar = mean(coords[:, 1]);
    ybar = mean(coords[:, 2]);

    # 2. Construct the matrix M. (see pdf of the assignment)
    Sxx = sum((coords[:, 1] .- xbar) .^ 2);
    Syy = sum((coords[:, 2] .- ybar) .^ 2);
    Sxy = sum((coords[:, 1] .- xbar) .* (coords[:, 2] .- ybar));
    M = [Syy -Sxy;
         -Sxy Sxx];

    # 3. Compute the eigenvector associated with the smallest eigenvalue of M.
    eigvals, eigvecs = eigen(M);
    idx_min = argmin(eigvals);
    eigv = eigvecs[:, idx_min];

    # 4. Partition the nodes around line L
    #    (use the function partition(coords, eigv))
    p1, p2 = partition(coords, eigv);
    p[p1] .= 1
    p[p2] .= 2

    # 5. Return the indicator vector
    return p

end
