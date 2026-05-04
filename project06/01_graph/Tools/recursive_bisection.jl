# M.L. for High Performance Computing Lab @USI & @ETHZ - malik.lechekhab@usi.ch
"""
    rec_bisection(method, levels, A, coords=zeros(0), vn=zeros(0))

Compute recursive partitioning of graph `A` using a specified `method` and
number of `levels`.

If the `method` is `coords`-based, coordinates must be passed.

# Examples
```julia-repl
julia> rec_bisection("spectralPart", 3, A)
 5
 ⋮
 2

julia> rec_bisection("coordinatePart", 3, A, coords)
 1
 ⋮
 8
```
"""

function rec_bisection(method, levels, A, coords=zeros(0), vn=zeros(0))

    n = size(A, 1)

    # Final partition vector.
    p = zeros(Int, n)

    function recursion(vertices, level, index)

        # Stop if no more levels are required.
        if level == 0
            p[vertices] .= index
            return
        end

        # Safety stop: cannot bisect zero or one vertex.
        if length(vertices) <= 1
            p[vertices] .= index
            return
        end

        # Extract current subgraph.
        A_sub = A[vertices, vertices]

        # Apply the selected bisection method.
        if method == "spectral_part"
            local_p = spectral_part(A_sub)

        elseif method == "coordinate_part"
            if length(coords) == 0
                error("Coordinates are required for coordinate bisection.")
            end
            coords_sub = coords[vertices, :]
            local_p = coordinate_part(A_sub, coords_sub)

        elseif method == "inertial_part"
            if length(coords) == 0
                error("Coordinates are required for inertial bisection.")
            end
            coords_sub = coords[vertices, :]
            local_p = inertial_part(A_sub, coords_sub)

        else
            error("Unknown partitioning method: $method")
        end

        # Do not assume labels are 1/2. They may be 0/1.
        labels = sort(unique(local_p))

        if length(labels) != 2
            error("Bisection failed: expected 2 parts, got labels = $labels")
        end

        vertices_1 = vertices[findall(local_p .== labels[1])]
        vertices_2 = vertices[findall(local_p .== labels[2])]

        if isempty(vertices_1) || isempty(vertices_2)
            error("Bisection failed: one of the two parts is empty.")
        end

        # Number of final parts contained in one recursive branch.
        offset = 2^(level - 1)

        recursion(vertices_1, level - 1, index)
        recursion(vertices_2, level - 1, index + offset)

    end

    recursion(collect(1:n), levels, 1)

    return p

end