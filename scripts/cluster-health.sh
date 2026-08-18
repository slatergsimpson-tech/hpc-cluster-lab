#!/bin/bash
# cluster-health.sh — one-command cluster physical, run on head01.
# Checks each layer in dependency order: network -> munge trust -> NFS ->
# scheduler -> node states. Exit 0 = all green, 1 = something failed.
# The layer ORDER is the diagnostic method: when nodes go unknown in
# sinfo, you check munge before slurm, network before munge.

NODES="node01 node02"
SSH="ssh -o BatchMode=yes -o ConnectTimeout=5 -i $HOME/.ssh/hpc-lab"
fail=0

ok()   { printf '  [ OK ] %s\n' "$1"; }
bad()  { printf '  [FAIL] %s\n' "$1"; fail=1; }

echo "== hpclab health check: $(date '+%F %T') =="

echo "-- network --"
for n in $NODES; do
    if ping -c1 -W2 "$n" >/dev/null 2>&1; then ok "ping $n"; else bad "ping $n"; fi
done

echo "-- munge trust --"
for n in $NODES; do
    if munge -n | $SSH "$n" unmunge >/dev/null 2>&1; then
        ok "credential decodes on $n"
    else
        bad "credential decodes on $n"
    fi
done

echo "-- shared /home --"
probe="/home/$USER/.health-probe-$$"
touch "$probe"
for n in $NODES; do
    if $SSH "$n" "test -f $probe" 2>/dev/null; then
        ok "NFS /home visible on $n"
    else
        bad "NFS /home visible on $n"
    fi
done
rm -f "$probe"

echo "-- scheduler --"
if systemctl is-active slurmctld >/dev/null 2>&1; then ok "slurmctld active"; else bad "slurmctld active"; fi
down=$(sinfo -h -t down,drain,unk -o "%D" | awk '{s+=$1} END {print s+0}')
if [ "$down" -eq 0 ]; then ok "no nodes down/drained/unknown"; else bad "$down node(s) down/drained/unknown"; fi

echo "-- node resources --"
for n in $NODES; do
    line=$($SSH "$n" "df -h / | tail -1 | awk '{print \$5}'; uptime | sed 's/.*load average: //'" 2>/dev/null)
    rootuse=$(echo "$line" | head -1)
    load=$(echo "$line" | tail -1)
    if [ "${rootuse%\%}" -lt 90 ] 2>/dev/null; then
        ok "$n root disk ${rootuse:-?} used, load ${load:-?}"
    else
        bad "$n root disk ${rootuse:-?} used, load ${load:-?}"
    fi
done

echo "== result: $([ $fail -eq 0 ] && echo ALL GREEN || echo FAILURES PRESENT) =="
exit $fail
