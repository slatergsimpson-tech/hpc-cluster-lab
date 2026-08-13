# CLAUDE.md — hpc-cluster-lab

## What this project is

A 3-node virtualized HPC cluster home lab, built and documented publicly to demonstrate research computing infrastructure skills. Owner: Slater Simpson (GitHub: slatergsimpson-tech). The lab supports a job application for **Research Computing Infrastructure Engineer at LSU Health Shreveport (PSN 56049)** — application submitted August 2026; this repo is interview evidence and a learning vehicle.

## How to work with Slater (IMPORTANT)

- **Teaching mode by default.** Slater's goal is understanding, not a finished repo. Before running any non-trivial command, explain what it does and why. Prefer walking him through commands he types himself over executing silently — especially anything inside the VMs.
- His background: CIS degree (Louisiana Tech, 2024), coursework Linux (Kali), Python/SQL basics — but skills are rusty. Assume smart-but-out-of-practice. Define HPC jargon on first use.
- Work happens in two places: (1) this repo on the Windows host — configs, playbooks, scripts, docs, git; (2) inside the VirtualBox VMs — Slater drives those consoles himself with guidance.
- Every work session should end with: updating the build log, committing with a descriptive message, and pushing.

## Environment

- Host: custom desktop, Windows 11, 16 GB RAM, AMD GPU (no CUDA — GPU topics are book-knowledge only, mention ROCm as the Linux/AMD path)
- Hypervisor: VirtualBox (planned)
- Cluster plan: `head01` (2 vCPU/4 GB — SLURM controller, NFS server, Ansible control, monitoring) + `node01`, `node02` (2 vCPU/3 GB each)
- OS: Rocky Linux 9

## Milestones (update checkboxes in README.md as completed)

1. **Linux foundations** — Rocky installs, static IPs, /etc/hosts, SSH keys, users/groups
2. **SLURM** — munge, slurm.conf, partitions/QOS, batch + array + MPI jobs
3. **Storage** — NFS /home export, then BeeGFS; write-up comparing Lustre/GPFS
4. **Automation** — Ansible playbooks to rebuild a compute node from bare OS; health-check scripts (Bash/Python)
5. **Monitoring** — Prometheus + node_exporter + Grafana; induce and diagnose a bottleneck
6. **Containers & hardening** — Apptainer jobs under SLURM; SSH/firewalld hardening; map controls to NIST 800-171 families

## Repo conventions

- Layout: `docs/` (architecture notes + `docs/build-log.md` troubleshooting journal), `ansible/`, `slurm/`, `monitoring/`, `scripts/`
- Build log entries are dated, honest, and include failures and dead ends — that's the point
- Commit style: short imperative subject, body explains the why (e.g., `Add slurm.conf with debug partition` / `Two-node partition for testing job placement before adding node02`)
- Never commit secrets, munge keys, or private SSH keys — gitignore them from the start

## Interview relevance (keep in mind when writing docs)

Docs double as talking points. When a milestone lands, add a short "what I'd say in an interview" note to the build log: what broke, how it was diagnosed, what the production-scale equivalent would be (e.g., NFS here vs. Lustre/GPFS at scale; VirtualBox networking vs. InfiniBand).

## Current status

- [x] Repo planned; README drafted (August 2026)
- [ ] Repo initialized and pushed to github.com/slatergsimpson-tech/hpc-cluster-lab
- [ ] Milestone 1 begun

Next actions: init git repo, add README.md + this file + directory skeleton, first commit, create GitHub remote, push. Then download Rocky Linux 9 ISO and VirtualBox to begin Milestone 1.
