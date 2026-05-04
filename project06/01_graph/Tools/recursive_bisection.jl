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
    # p[i] is the final part assigned to vertex i.
    p = zeros(Int, n)

    # vertices: indices of the original graph currently being partitioned
    # level: number of remaining bisection levels
    # index: label of the first final part in this recursive branch
    function recursion(vertices, level, index)

        # No more bisection: assign all vertices to the current final part.
        if level == 0
            p[vertices] .= index
            return
        end

        # Extract the subgraph induced by the current vertices.
        A_sub = A[vertices, vertices]

        # Apply the requested bisection method on the subgraph.
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

        # Convert the local bisection labels back to original vertex indices.
        vertices_1 = vertices[findall(local_p .== 1)]
        vertices_2 = vertices[findall(local_p .== 2)]

        # Each branch below this level contains 2^(level-1) final parts.
        offset = 2^(level - 1)

        # Recurse on both halves.
        recursion(vertices_1, level - 1, index)
        recursion(vertices_2, level - 1, index + offset)

    end

    # Start from the whole graph.
    recursion(collect(1:n), levels, 1)

    return p

end

    


