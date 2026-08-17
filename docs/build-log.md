# Build Log

Dated journal of the cluster build — including failures, dead ends, and what
each problem taught me. Newest entries at the top.

---

## 2026-08-17 — Milestone 1: three VMs provisioned, unattended installs (with a fight)

Downloaded and SHA256-verified Rocky 9.8 minimal ISO and VirtualBox 7.2.14,
scripted VM creation (`scripts/create-vms.ps1`: 3 VMs, dual NICs — NAT for
internet, host-only 192.168.56.0/24 as the cluster network), and did fully
unattended kickstart installs on all three nodes. head01 = 192.168.56.10,
node01 = .11, node02 = .12. SSH key auth working end to end.

**What broke, #1:** VirtualBox's `unattended install` hung the VM at
`ISOLINUX: Image checksum error`. Root cause: VBox doesn't boot the stock
ISO — it remasters `isolinux.cfg` via an auxiliary VISO to inject `ks=`
kernel args, and that remaster breaks on Rocky 9.8 media. Diagnosed by
grabbing a console screenshot (`VBoxManage controlvm head01 screenshotpng`)
after the install sat silent for 30 minutes.

**Fix:** ditched VBox's remastering for the RHEL-native mechanism — anaconda
auto-discovers `/ks.cfg` on any volume labeled `OEMDRV`. Wrote my own
kickstart (better than VBox's template anyway: @core only instead of desktop
groups, firewall *enabled* + ssh instead of disabled, static cluster IP set
at install time, sshkey directive, wheel NOPASSWD for Ansible), put it on a
tiny VISO labeled OEMDRV, booted the untouched ISO. Worked first try:
326 packages, ~10 min per node. Template: `scripts/kickstart/node.ks.template`.

**What broke, #2:** head01 came up with no IPv4 on the NAT NIC — DHCP raced
the NAT engine at boot. `nmcli con up enp0s3` fixed it; worth watching
whether it recurs on the compute nodes.

**What broke, #3 (process lesson):** my install watcher polled for "SSH up"
and "VM died" but not "VM hung" — a wedged bootloader looks identical to a
slow install. Silence is not success; monitors need to cover the hang case.

**Completed same day:** node01/node02 installed clean off the same template
(~12 min each, DHCP race did not recur). /etc/hosts distributed to all three
nodes, cluster key installed on head01, verified head01 → node01/node02 SSH
by hostname. Milestone 1 done: three Rocky 9.8 nodes, static cluster IPs,
name resolution, key auth everywhere. Bonus lesson: PowerShell→ssh→bash
quoting (`\$` is not an escape in PowerShell; it reached bash as a literal).

**Interview note:** this is the toy version of what Warewulf/xCAT/Foreman do
at scale — image-based or kickstart-driven node provisioning where a node
netboots (PXE instead of a virtual DVD), pulls its config from a provisioning
server, and comes up identical to its peers. The OEMDRV/kickstart debugging
story is a good example of reading a failure at the right layer: the bug was
in the boot path, not the installer.

Set up the repository skeleton (`docs/`, `ansible/`, `slurm/`, `monitoring/`,
`scripts/`) with README, project notes, and a `.gitignore` that blocks secrets
(SSH private keys, munge keys) from ever being committed.

Next up: download Rocky Linux 9 ISO and VirtualBox, begin Milestone 1
(Linux foundations).
