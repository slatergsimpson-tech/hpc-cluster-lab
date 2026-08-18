#!/bin/bash
# Smoke-test batch job: one task on each of the two compute nodes.
#SBATCH --job-name=hello
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --output=hello-%j.out

srun hostname
echo "Job $SLURM_JOB_ID ran on nodes: $SLURM_JOB_NODELIST"
