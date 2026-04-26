from mandelbrot_task import *
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
from mpi4py import MPI # MPI_Init and MPI_Finalize automatically called
import numpy as np
import sys
import time

# some parameters
MANAGER = 0       # rank of manager
TAG_TASK      = 1 # task       message tag
TAG_TASK_DONE = 2 # tasks done message tag
TAG_DONE      = 3 # done       message tag

def manager(comm, tasks):
    size = comm.Get_size()
    nworkers = size - 1

    next_task = 0
    active_workers = 0
    TasksDoneByWorker = {i: 0 for i in range(size)}

    # send initial tasks
    for worker in range(1, size):
        if next_task < len(tasks):
            comm.send(tasks[next_task], dest=worker, tag=TAG_TASK)
            next_task += 1
            active_workers += 1
        else:
            comm.send(None, dest=worker, tag=TAG_DONE)

    # receive results and assign new tasks
    status = MPI.Status()

    while active_workers > 0:
        completed_task = comm.recv(
            source=MPI.ANY_SOURCE,
            tag=TAG_TASK_DONE,
            status=status
        )

        worker = status.Get_source()
        TasksDoneByWorker[worker] += 1

        # replace the completed task in the task list
        tasks[completed_task._Id] = completed_task

        if next_task < len(tasks):
            comm.send(tasks[next_task], dest=worker, tag=TAG_TASK)
            next_task += 1
        else:
            comm.send(None, dest=worker, tag=TAG_DONE)
            active_workers -= 1

    return TasksDoneByWorker


def worker(comm):
    while True:
        status = MPI.Status()
        task = comm.recv(source=MANAGER, tag=MPI.ANY_TAG, status=status)

        if status.Get_tag() == TAG_DONE:
            break

        task.do_work()
        comm.send(task, dest=MANAGER, tag=TAG_TASK_DONE)

def readcmdline(rank):
    """
    Read command line arguments

    Parameters
    ----------
    rank : int
        Rank of calling MPI process

    Returns
    -------
    nx : int
        number of gridpoints in x-direction
    ny : int
        number of gridpoints in y-direction
    ntasks : int
        number of tasks
    """
    # report usage
    if len(sys.argv) != 4:
        if rank == MANAGER:
            print("Usage: manager_worker nx ny ntasks")
            print("  nx     number of gridpoints in x-direction")
            print("  ny     number of gridpoints in y-direction")
            print("  ntasks number of tasks")
        sys.exit()

    # read nx, ny, ntasks
    nx = int(sys.argv[1])
    if nx < 1:
        sys.exit("nx must be a positive integer")
    ny = int(sys.argv[2])
    if ny < 1:
        sys.exit("ny must be a positive integer")
    ntasks = int(sys.argv[3])
    if ntasks < 1:
        sys.exit("ntasks must be a positive integer")

    return nx, ny, ntasks


if __name__ == "__main__":

    # get COMMON WORLD communicator, size & rank
    comm    = MPI.COMM_WORLD
    size    = comm.Get_size()
    my_rank = comm.Get_rank()

    # report on MPI environment
    if my_rank == MANAGER:
        print(f"MPI initialized with {size:5d} processes")

    # read command line arguments
    nx, ny, ntasks = readcmdline(my_rank)

    # start timer
    timespent = - time.perf_counter()

    if my_rank == MANAGER:
        x_min = -2.
        x_max = +1.
        y_min = -1.5
        y_max = +1.5

        M = mandelbrot(x_min, x_max, nx, y_min, y_max, ny, ntasks)
        tasks = M.get_tasks()

        TasksDoneByWorker = manager(comm, tasks)

        m = M.combine_tasks(tasks)
        plt.imshow(m.T, cmap="gray", extent=[x_min, x_max, y_min, y_max])
        plt.savefig("mandelbrot.pdf")

        # stop timer
        timespent += time.perf_counter()

        print(f"Run took {timespent:f} seconds")
        for i in range(1, size):
            print(f"Process {i:5d} has done {TasksDoneByWorker[i]:10d} tasks")
        print("Done.")

    else:
        worker(comm)


