/*
Homogeneous Dirichlet Poisson problem in 2D.

We solve

   -div grad u = f,  0 < x,y < 1,

with forcing function

   f = 20,

and homogeneous Dirichlet boundary conditions

   u = 0 for x = 0, x = 1, y = 0, y = 1.

The discretization uses a second-order centered finite-difference scheme.
*/

static char help[] = "Solves 2D Poisson Equation using second-order centered finite differences.\n\n";

#include <petscdm.h>
#include <petscdmda.h>
#include <petscksp.h>
#include <mpi.h>
#include "walltime.h"

extern PetscErrorCode ComputeMatrix(KSP, Mat, Mat, void *);
extern PetscErrorCode ComputeRHS(KSP, Vec, void *);
extern PetscErrorCode WriteSolution(DM, Vec, const char *);

int main(int argc, char **argv)
{
  KSP ksp;
  DM  da;

  PetscFunctionBeginUser;
  PetscCall(PetscInitialize(&argc, &argv, NULL, help));

  PetscCall(KSPCreate(PETSC_COMM_WORLD, &ksp));

  PetscCall(DMDACreate2d(
      PETSC_COMM_WORLD,
      DM_BOUNDARY_NONE,
      DM_BOUNDARY_NONE,
      DMDA_STENCIL_STAR,
      3, 3,
      PETSC_DECIDE, PETSC_DECIDE,
      1, 1,
      NULL, NULL,
      &da));

  PetscCall(DMSetFromOptions(da));
  PetscCall(DMSetUp(da));

  PetscCall(DMDASetUniformCoordinates(da, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0));
  PetscCall(DMDASetFieldName(da, 0, "Solution"));

  double total_start, total_end;
  double setup_start, setup_end;
  double solve_start, solve_end;
  double local_times[3], max_times[3];
  PetscBool write_solution = PETSC_FALSE;
  PetscMPIInt nprocs;
  PetscInt mx, my, its;

  /*
     Use the project walltime() routine rather than PETSc's timer. Since this
     is an MPI code, the reported times are the maximum over all ranks, which is
     the relevant wall-clock time-to-solution for strong-scaling measurements.
  */
  PetscCallMPI(MPI_Barrier(PETSC_COMM_WORLD));
  total_start = walltime();

  PetscCall(KSPSetDM(ksp, da));
  PetscCall(KSPSetComputeRHS(ksp, ComputeRHS, NULL));
  PetscCall(KSPSetComputeOperators(ksp, ComputeMatrix, NULL));

  PetscCall(KSPSetFromOptions(ksp));

  PetscCallMPI(MPI_Barrier(PETSC_COMM_WORLD));
  setup_start = walltime();
  PetscCall(KSPSetUp(ksp));
  PetscCallMPI(MPI_Barrier(PETSC_COMM_WORLD));
  setup_end = walltime();

  PetscCallMPI(MPI_Barrier(PETSC_COMM_WORLD));
  solve_start = walltime();
  PetscCall(KSPSolve(ksp, NULL, NULL));
  PetscCallMPI(MPI_Barrier(PETSC_COMM_WORLD));
  solve_end = walltime();

  total_end = solve_end;

  local_times[0] = total_end - total_start;
  local_times[1] = setup_end - setup_start;
  local_times[2] = solve_end - solve_start;
  PetscCallMPI(MPI_Reduce(local_times, max_times, 3, MPI_DOUBLE, MPI_MAX, 0, PETSC_COMM_WORLD));

  PetscCall(KSPGetIterationNumber(ksp, &its));
  PetscCall(KSPGetDM(ksp, &da));
  PetscCall(DMDAGetInfo(da, NULL, &mx, &my, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));
  PetscCallMPI(MPI_Comm_size(PETSC_COMM_WORLD, &nprocs));

  PetscCall(PetscPrintf(PETSC_COMM_WORLD,
      "RESULT,%d,%" PetscInt_FMT ",%" PetscInt_FMT ",%.10e,%.10e,%.10e,%" PetscInt_FMT "\n",
      (int)nprocs, mx, my,
      max_times[0], max_times[1], max_times[2],
      its));

  PetscCall(PetscOptionsGetBool(NULL, NULL, "-write_solution", &write_solution, NULL));
  if (write_solution) {
    Vec  x;
    char filename[PETSC_MAX_PATH_LEN] = "solution.dat";

    PetscCall(PetscOptionsGetString(NULL, NULL, "-solution_file", filename, sizeof(filename), NULL));
    PetscCall(KSPGetSolution(ksp, &x));
    PetscCall(WriteSolution(da, x, filename));
  }

  PetscCall(DMDestroy(&da));
  PetscCall(KSPDestroy(&ksp));
  PetscCall(PetscFinalize());

  return 0;
}

PetscErrorCode ComputeRHS(KSP ksp, Vec b, void *ctx)
{
  PetscInt      i, j;
  PetscInt      mx, my;
  PetscInt      xs, ys, xm, ym;
  PetscScalar   Hx, Hy;
  PetscScalar **array;
  DM            da;

  PetscFunctionBeginUser;

  PetscCall(KSPGetDM(ksp, &da));
  PetscCall(DMDAGetInfo(da, NULL, &mx, &my, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

  Hx = 1.0 / (PetscReal)(mx - 1);
  Hy = 1.0 / (PetscReal)(my - 1);

  PetscCall(DMDAGetCorners(da, &xs, &ys, NULL, &xm, &ym, NULL));
  PetscCall(DMDAVecGetArray(da, b, &array));

  for (j = ys; j < ys + ym; j++) {
    for (i = xs; i < xs + xm; i++) {

      if (i == 0 || j == 0 || i == mx - 1 || j == my - 1) {
        array[j][i] = 0.0;
      } else {
        array[j][i] = 20.0 * Hx * Hy;
      }

    }
  }

  PetscCall(DMDAVecRestoreArray(da, b, &array));
  PetscCall(VecAssemblyBegin(b));
  PetscCall(VecAssemblyEnd(b));

  PetscFunctionReturn(PETSC_SUCCESS);
}

PetscErrorCode ComputeMatrix(KSP ksp, Mat J, Mat jac, void *ctx)
{
  PetscInt    i, j;
  PetscInt    mx, my;
  PetscInt    xs, ys, xm, ym;
  PetscScalar Hx, Hy;
  PetscScalar HxdHy, HydHx;
  PetscScalar v[5];
  MatStencil  row, col[5];
  DM          da;

  PetscFunctionBeginUser;

  PetscCall(KSPGetDM(ksp, &da));
  PetscCall(DMDAGetInfo(da, NULL, &mx, &my, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

  Hx = 1.0 / (PetscReal)(mx - 1);
  Hy = 1.0 / (PetscReal)(my - 1);

  HxdHy = Hx / Hy;
  HydHx = Hy / Hx;

  PetscCall(DMDAGetCorners(da, &xs, &ys, NULL, &xm, &ym, NULL));

  for (j = ys; j < ys + ym; j++) {
    for (i = xs; i < xs + xm; i++) {

      row.i = i;
      row.j = j;

      if (i == 0 || j == 0 || i == mx - 1 || j == my - 1) {

        /*
          Homogeneous Dirichlet boundary condition:

              u = 0

          Matrix row:

              1 * u_boundary = 0
        */

        v[0] = 1.0;

        PetscCall(MatSetValuesStencil(jac, 1, &row, 1, &row, v, INSERT_VALUES));

      } else {

        PetscInt ncols = 0;

        /*
          Interior discretization of

              -Delta u = 20.

          After multiplying by Hx * Hy, the stencil is

              center:  2(Hx/Hy + Hy/Hx)
              left:   -Hy/Hx
              right:  -Hy/Hx
              down:   -Hx/Hy
              up:     -Hx/Hy

          Boundary neighbours are skipped because their value is known
          and equal to zero. This keeps the matrix symmetric.
        */

        if (j - 1 > 0) {
          v[ncols]     = -HxdHy;
          col[ncols].i = i;
          col[ncols].j = j - 1;
          ncols++;
        }

        if (i - 1 > 0) {
          v[ncols]     = -HydHx;
          col[ncols].i = i - 1;
          col[ncols].j = j;
          ncols++;
        }

        v[ncols]     = 2.0 * (HxdHy + HydHx);
        col[ncols].i = i;
        col[ncols].j = j;
        ncols++;

        if (i + 1 < mx - 1) {
          v[ncols]     = -HydHx;
          col[ncols].i = i + 1;
          col[ncols].j = j;
          ncols++;
        }

        if (j + 1 < my - 1) {
          v[ncols]     = -HxdHy;
          col[ncols].i = i;
          col[ncols].j = j + 1;
          ncols++;
        }

        PetscCall(MatSetValuesStencil(jac, 1, &row, ncols, col, v, INSERT_VALUES));
      }
    }
  }

  PetscCall(MatAssemblyBegin(jac, MAT_FINAL_ASSEMBLY));
  PetscCall(MatAssemblyEnd(jac, MAT_FINAL_ASSEMBLY));

  PetscCall(MatSetOption(jac, MAT_SYMMETRIC, PETSC_TRUE));
  PetscCall(MatViewFromOptions(jac, NULL, "-view_mat"));

  PetscFunctionReturn(PETSC_SUCCESS);
}

PetscErrorCode WriteSolution(DM da, Vec x, const char *filename)
{
  PetscInt                i, j;
  PetscInt                mx, my;
  PetscInt                xs, ys, xm, ym;
  PetscReal               Hx, Hy;
  const PetscScalar     **array;
  PetscViewer             viewer;

  PetscFunctionBeginUser;

  PetscCall(DMDAGetInfo(da, NULL, &mx, &my, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

  Hx = 1.0 / (PetscReal)(mx - 1);
  Hy = 1.0 / (PetscReal)(my - 1);

  PetscCall(DMDAGetCorners(da, &xs, &ys, NULL, &xm, &ym, NULL));

  PetscCall(PetscViewerASCIIOpen(PETSC_COMM_WORLD, filename, &viewer));

  PetscCall(PetscViewerASCIIPrintf(viewer, "# x y u\n"));

  PetscCall(DMDAVecGetArrayRead(da, x, &array));

  PetscCall(PetscViewerASCIIPushSynchronized(viewer));

  for (j = ys; j < ys + ym; j++) {
    for (i = xs; i < xs + xm; i++) {
      PetscReal xcoord = ((PetscReal)i) * Hx;
      PetscReal ycoord = ((PetscReal)j) * Hy;
      PetscReal value  = PetscRealPart(array[j][i]);

      PetscCall(PetscViewerASCIISynchronizedPrintf(
          viewer,
          "%.16e %.16e %.16e\n",
          (double)xcoord,
          (double)ycoord,
          (double)value));
    }
  }

  PetscCall(PetscViewerFlush(viewer));
  PetscCall(PetscViewerASCIIPopSynchronized(viewer));

  PetscCall(DMDAVecRestoreArrayRead(da, x, &array));
  PetscCall(PetscViewerDestroy(&viewer));

  PetscFunctionReturn(PETSC_SUCCESS);
}