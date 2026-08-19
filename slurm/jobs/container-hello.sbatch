#!/bin/bash
# Container job: run a task inside an Apptainer container on both nodes.
# The .sif image lives in shared /home, so every node sees the same file —
# no registry, no daemon, no root. The container carries Alpine userland;
# the host is Rocky; the job proves workloads can bring their own stack.
#SBATCH --job-name=container-hello
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --output=container-%j.out

srun -l apptainer exec ~/alpine.sif sh -c 'echo "host $(hostname) container: $(cat /etc/alpine-release 2>/dev/null && echo alpine) $(uname -r)"'
