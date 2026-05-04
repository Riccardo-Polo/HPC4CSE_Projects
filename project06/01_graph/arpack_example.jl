using Arpack
using SparseArrays
using Random


# Set random seed
Random.seed!(42)

# Generate random sparse symmetric matrix
n = 10_000                 # Size of the matrix
density = 1.e-3            # Proportion of nonzero elements
S = sprandn(n, n, density) # Random sparse matrix
A = S + S'                 # Make it symmetric

# Compute the smallest 2 eigenvalues
nev =  2    # Number of eigenvalues to compute
ncv = 40    # Lanczos basis size (choose large enough for convergence)
which = :SR # Compute the smallest real eigenvalues
eigenvalues, eigenvectors = eigs(A, nev=nev, which=which, ncv=ncv)

# Output the results
println("Computed Eigenvalues: ", eigenvalues)
println("Corresponding Eigenvectors: First 5 elements of each")
println("Eigenvector 1: ", eigenvectors[:, 1][1:5])
println("Eigenvector 2: ", eigenvectors[:, 2][1:5])
