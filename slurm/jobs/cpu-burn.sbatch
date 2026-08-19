#!/bin/bash
# Deliberate CPU bottleneck: 4 array tasks x 1 CPU = every core in the
# cluster pegged for 5 minutes. Used to demonstrate diagnosing saturation
# from the Grafana/Prometheus side: load climbs to ~2.0 per node (= core
# count), CPU idle% collapses, memory stays flat -> CPU-bound, not memory.
#SBATCH --job-name=cpu-burn
#SBATCH --partition=debug
#SBATCH --array=1-4
#SBATCH --cpus-per-task=1
#SBATCH --output=burn-%A_%a.out

echo "burn task $SLURM_ARRAY_TASK_ID on $(hostname) starting"
timeout 300 openssl speed -seconds 300 aes-256-cbc >/dev/null 2>&1
echo "burn task $SLURM_ARRAY_TASK_ID done"
