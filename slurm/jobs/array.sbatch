#!/bin/bash
# Array job: eight independent tasks sharing one submission — the standard
# pattern for parameter sweeps (numbering via %A = job id, %a = task id).
#SBATCH --job-name=array-demo
#SBATCH --partition=debug
#SBATCH --array=1-8
#SBATCH --cpus-per-task=1
#SBATCH --output=array-%A_%a.out

echo "array task $SLURM_ARRAY_TASK_ID running on $(hostname)"
sleep 15
