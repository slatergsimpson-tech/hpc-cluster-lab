# HPC Cluster Home Lab

A hands-on build of a miniature high-performance computing (HPC) cluster, documented in public. The goal: learn and demonstrate the core skills of research computing infrastructure — Linux cluster administration, job scheduling, parallel storage, automation, and monitoring — by building a working environment from scratch.

**Author:** Slater Simpson · Shreveport, LA · [linkedin.com/in/slatergsimpson](https://www.linkedin.com/in/slatergsimpson)

## Architecture

Three-node virtualized cluster running on a single physical host (Windows 11, 16 GB RAM, AMD GPU):

| Node | Role | Resources (planned) |
|------|------|---------------------|
| `head01` | Head node — SLURM controller, NFS server, Ansible control, monitoring | 2 vCPU / 4 GB |
| `node01` | Compute node | 2 vCPU / 3 GB |
| `node02` | Compute node | 2 vCPU / 3 GB |

**OS:** Rocky Linux 9 (RHEL-compatible, standard in academic HPC)

## Milestones

- [x] **1. Linux foundations** — Rocky Linux install on all nodes; static IPs, hostname resolution, SSH key auth, shared users/groups
- [x] **2. Job scheduling** — SLURM with munge authentication; partitions and QOS; batch, array, and multi-node MPI jobs
- [ ] **3. Shared storage** — NFS-exported home directories, then BeeGFS parallel file system; notes comparing Lustre/GPFS architectures
- [x] **4. Automation** — Ansible playbooks to provision a compute node from scratch; Bash/Python cluster health-check scripts
- [ ] **5. Monitoring** — Prometheus + node_exporter + Grafana dashboards; deliberate load testing to find and diagnose bottlenecks
- [ ] **6. Containers & hardening** — Apptainer (Singularity) container jobs under SLURM; SSH/firewalld hardening; mapping lab controls to NIST 800-171 families

Checkboxes get marked as each milestone lands, with configs and a build log committed alongside.

## Repository layout (planned)

```
docs/        Architecture notes, decisions, and troubleshooting log
ansible/     Playbooks and inventory for node provisioning
slurm/       slurm.conf, partition/QOS configs, example job scripts
monitoring/  Prometheus/Grafana configs and dashboards
scripts/     Health checks and utility scripts (Bash/Python)
```

## Why this project

I'm a Computer Information Systems graduate (Louisiana Tech, 2024) working in customer-facing technical support, transitioning into research computing infrastructure. Reading about clusters isn't the same as being paged by one — this lab exists so I can break things, fix them, and document what I learned. The troubleshooting log in `docs/` is deliberately honest: real problems, wrong turns included.
