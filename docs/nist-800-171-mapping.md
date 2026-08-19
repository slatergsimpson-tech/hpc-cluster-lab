# Mapping lab controls to NIST SP 800-171 families

NIST SP 800-171 governs protection of Controlled Unclassified Information —
the framework research institutions meet when federal grants or health data
are involved. This lab is not a compliant environment (one admin, no CUI,
self-signed everything); the point is to show which concrete technical
controls in the cluster map to which requirement families, and to be honest
about what production adds.

| Family | Requirement theme | What this lab implements | What production adds |
|--------|-------------------|--------------------------|----------------------|
| 3.1 Access Control | Limit system access to authorized users | SSH key-only auth (passwords disabled), root login disabled, per-user accounts, sudo via wheel group, firewalld zones isolating the cluster network from the NAT/egress interface | Central IdM (FreeIPA/AD), MFA on bastion hosts, session recording, RBAC in SLURM (accounts/associations enforced) |
| 3.3 Audit & Accountability | Create and retain system audit records | slurmdbd job accounting (who ran what, where, when — `sacct`), systemd journal, Prometheus metric history (15d retention), dated build log of every change | Centralized log shipping (rsyslog/Loki/Splunk), auditd rules, tamper-evident retention, alerting on audit events |
| 3.4 Configuration Management | Baseline configurations, change control | Entire cluster defined as code in a git repo: kickstart templates, Ansible playbooks (idempotent, re-runnable), versioned slurm.conf; a node can be rebuilt from bare OS to baseline with one playbook run — the baseline IS the repo | Change advisory process, config drift detection (e.g. scheduled `ansible-playbook --check`), signed commits, protected branches, CI validation of playbooks |
| 3.5 Identification & Authentication | Identify users/devices, authenticate | Unique per-user accounts; consistent UIDs cluster-wide (uid 6001 slurm); munge shared-key authentication for every inter-daemon RPC; ed25519 SSH keys; NTP-disciplined clocks (munge credentials are time-windowed — clock skew is an auth failure) | Kerberos/SSSD, host certificates (SSH CA), hardware-backed keys, credential rotation policy |
| 3.13 System & Communications Protection | Monitor/control communications at boundaries | Two-zone network design: untrusted egress (NAT, firewalld public) vs trusted cluster fabric (host-only, firewalld trusted); services bound to the cluster network; MPI pinned to the cluster interface | TLS on Prometheus/Grafana/slurmdbd, network ACLs beyond zones, boundary firewalls/IDS, encrypted parallel filesystem traffic |
| 3.14 System & Information Integrity | Identify and correct flaws, monitor | SHA-256 verification of all installation media before use; SELinux enforcing on every node (kept on through the NFS-homes issue — fixed with the targeted boolean, not `setenforce 0`); dnf updates via EPEL; monitoring that surfaces anomalies (caught a live scheduler misconfiguration) | Scheduled patch cycles with maintenance windows, vulnerability scanning (OpenSCAP — 800-171 profiles exist for EL9), file integrity monitoring (AIDE), signed packages only |

## Two honest observations

**Containers (Apptainer) as a 3.4/3.14 story.** Researchers bring arbitrary
software; Apptainer lets them do it without root, without a daemon, and with
the image as a single auditable file. That converts "users compile random
things on the login node" into "workloads are declared, portable artifacts" —
a configuration-management win that also shrinks the attack surface.

**The controls that saved the lab were the boring ones.** SELinux enforcing
caught an insecure-by-default pattern (sshd reading NFS homes) that we then
allowed deliberately and narrowly. Checksum verification was practiced on
media that turned out fine — and then a bootloader corrupted by tooling
(not transit) reminded us why boot-path integrity matters. munge's time
window turned a silent clock drift into a visible authentication failure.
Security controls that fail loudly are diagnostic instruments.
