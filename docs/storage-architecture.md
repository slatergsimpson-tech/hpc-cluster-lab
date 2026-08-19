# Cluster storage: what NFS gives us, where it stops, and what parallel filesystems change

Milestone 3 planned "NFS, then BeeGFS." NFS is deployed and carries the
cluster's shared /home. BeeGFS was **deliberately descoped** — the reasoning
is at the bottom, because it only makes sense after the architecture story.

## What we run: single-server NFS

`head01` exports /home; both compute nodes mount it. One server owns both
the metadata (filenames, permissions, directory tree) and the data (file
contents). Every byte every client reads or writes flows through that one
server's NIC, memory, and disk.

Measured on this cluster (512 MiB direct-I/O `dd` over the virtual network):

| Scenario | Result |
|----------|--------|
| Single client write (node01) | 96 MB/s |
| Single client read (node01) | 110 MB/s |
| Two clients writing concurrently | 83 + 77 MB/s (per-client degradation under contention) |

The pattern to internalize: with N clients hammering one NFS server, each
client converges toward bandwidth/N. Two virtual clients already cost each
other ~15-20%. A 500-node cluster running an I/O-heavy workload against one
NFS server is a denial-of-service against itself — this is THE scaling wall
that parallel filesystems exist to break.

(Virtualization caveat, honestly noted: our "network" is a software switch
on one physical host, so absolute numbers are optimistic and aggregate
bandwidth can exceed a single real link. On physical hardware the server's
NIC is a hard ceiling shared by all clients.)

## How parallel filesystems break the wall

All three major players separate **metadata** from **data**, and stripe data
across many servers so clients talk to many machines at once:

- **Lustre** (dominant in national labs, open source): dedicated metadata
  servers (MDS/MDT) plus object storage servers (OSS/OST). A file striped
  across 4 OSTs gives a single client 4 servers' worth of bandwidth.
  Massive aggregate throughput; famously unforgiving to operate; POSIX
  semantics with sharp edges under contention.
- **IBM Storage Scale / GPFS** (common in universities and enterprise,
  commercial): every server can hold data and metadata; distributed lock
  management; strong POSIX semantics, snapshots, tiering. The polished,
  supported, licensed option.
- **BeeGFS** (the accessible one, out of Fraunhofer): management, metadata,
  and storage daemons that can share nodes or scale out separately;
  buddy-mirroring for HA. The easiest of the three to stand up — a common
  choice for department-scale clusters.

Same design idea everywhere: scale bandwidth by adding data servers, keep
the namespace coherent via dedicated metadata service. The differences are
operational maturity, licensing, and failure-mode ergonomics.

## Why BeeGFS was descoped here (and what would justify it)

A BeeGFS install on this lab would put mgmtd + meta + storage daemons on
head01 — one storage server, i.e. the same single-server bottleneck as NFS
with more daemons. **Striping across one server demonstrates nothing that a
diagram doesn't.** The property that justifies a parallel filesystem —
aggregate bandwidth scaling with server count — needs at least two storage
servers with real independent disks and links, which a 16 GB laptop-class
host running three VMs cannot honestly provide. The lab therefore keeps
NFS (architecturally correct for /home at this scale — small files, config,
code) and documents the parallel-FS layer as design knowledge.

What would change the answer: a fourth and fifth VM as dedicated storage
nodes on separate physical disks, or real hardware. First experiment I'd
run: stripe a file across both storage nodes and show a single client
reading faster than either server's individual link — the number NFS can
never produce.

In production the pattern is both, not either/or: NFS (or the parallel FS's
"home" tier) for small files and configuration; the parallel filesystem
for scratch — large sequential I/O, checkpoint/restart dumps, shared
datasets. Data management policy (what lives where, quotas, purge windows)
is as much the job as the filesystem itself.
