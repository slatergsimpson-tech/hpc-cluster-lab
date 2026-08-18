#!/bin/bash
# Multi-node MPI job: Intel MPI Benchmarks PingPong between the two nodes —
# one rank per node, messages bounced across the cluster network, reporting
# latency and bandwidth per message size. On real HPC this is the benchmark
# you run to verify the interconnect (InfiniBand: ~1 us; our virtual
# ethernet will be orders of magnitude slower — that gap IS the lesson).
#SBATCH --job-name=pingpong
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --output=pingpong-%j.out

module load mpi/openmpi-x86_64

# Multi-homed nodes: every VM has an identical NAT address (10.0.2.15), so
# MPI must be pinned to the cluster network or ranks advertise the wrong
# interface and try to connect to themselves. Same reason production
# clusters pin MPI to the InfiniBand fabric, not the management net.
export UCX_NET_DEVICES=enp0s8
mpirun --mca oob_tcp_if_include 192.168.56.0/24 \
       --mca btl_tcp_if_include 192.168.56.0/24 \
       mpitests-IMB-MPI1 PingPong
