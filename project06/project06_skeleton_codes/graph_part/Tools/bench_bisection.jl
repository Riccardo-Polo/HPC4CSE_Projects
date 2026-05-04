# M.L. for High Performance Computing Lab @USI & @ETHZ - malik.lechekhab@usi.ch
"""
    benchmark_bisection()

Run a benchmark of different meshes with different partitioning method.

# Examples
```julia-repl
julia> benchmark_bisection()
```
"""
function benchmark_bisection()
    # Draw flag
    draw = true

    # List the meshes to compare
    meshes = ["mesh1e1", "mesh2e1", "mesh3e1", "airfoil1", "netz4504_dual",
              "stufe", "3elt", "barth4", "ukerbe1", "crack"]

    # List the algorithms to compare
    algs = ["Coordinate", "Metis", "Inertial", "Spectral"]

    # Init comparison table
    pAll = Array{Any}(undef, length(meshes), length(algs) + 1)

    # Loop through meshes
    for (i, mesh) in enumerate(meshes)
        # Read data
        A, coords = getData(mesh);

        # 1st row
        pAll[i, 1] = mesh;

        # 1. Coordinate bisection
        pCoordinate = coordinate_part(A, coords);
        pAll[i, 2] = count_edge_cut(A, pCoordinate);
        if draw
          save("images/bisection/$(mesh)_coordinate_bisection.pdf",
               draw_graph(A, coords, pCoordinate));
        end

        # 2. METIS bisection
        pMetis = metis_part(A, 2, :KWAY);
        pAll[i, 3] = count_edge_cut(A, pMetis);
        if draw
          save("images/bisection/$(mesh)_metis_bisection.pdf",
               draw_graph(A, coords, pMetis));
        end

        # 3. Inertial bisection
        pInertial = inertial_part(A, coords);
        pAll[i, 4] = count_edge_cut(A, pInertial);
        if draw
          save("images/bisection/$(mesh)_inertial_bisection.pdf",
               draw_graph(A, coords, pInertial));
        end

        # 4. Spectral bisection
        pSpectral = spectral_part(A);
        pAll[i, 5] = count_edge_cut(A, pSpectral);
        if draw
          save("images/bisection/$(mesh)_spectral_bisection.pdf",
               draw_graph(A, coords, pSpectral));
        end
    end

    # Print table
    header = (vcat(["Mesh"], algs), ["", "", "v.5.1.0", "", ""])
    pretty_table(pAll; header = header, crop = :none)
    # pretty_table(pAll; header = header, backend = Val{:latex}())

end
