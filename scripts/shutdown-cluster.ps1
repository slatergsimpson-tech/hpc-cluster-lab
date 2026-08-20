# shutdown-cluster.ps1 — graceful cluster power-down, run on the Windows host.
#
# Order is the point: compute nodes first, head01 LAST. The nodes depend on
# head01 (NFS server, munge, slurmctld) — kill the head first and clients
# hang on a vanished NFS server. On the way down, servers go last; on the
# way up, servers go first (see startup-cluster.ps1).
#
# Graceful (guest 'shutdown now') beats VBoxManage poweroff: filesystems
# flush, slurmctld checkpoints its queue, the clock writes back to the RTC.

$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$key = "$HOME\.ssh\hpc-lab"
$ssh = "ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=NUL -i `"$key`""

function Test-Running($name) {
    (& $vbm list runningvms) -match "`"$name`""
}

function Wait-PoweredOff($name, $timeoutSec = 120) {
    $t = 0
    while (Test-Running $name) {
        if ($t -ge $timeoutSec) {
            Write-Host "$name still running after ${timeoutSec}s - forcing poweroff" -ForegroundColor Yellow
            & $vbm controlvm $name poweroff | Out-Null
            return
        }
        Start-Sleep 5; $t += 5
    }
    Write-Host "$name is off"
}

$nodes = @{ 'node01' = '192.168.56.11'; 'node02' = '192.168.56.12' }

# --- Phase 1: compute nodes ---
foreach ($n in $nodes.Keys) {
    if (Test-Running $n) {
        Write-Host "shutting down $n ..."
        # ssh exits non-zero when the connection drops mid-shutdown; that's expected
        Invoke-Expression "$ssh slater@$($nodes[$n]) 'sudo shutdown now'" 2>$null
    } else {
        Write-Host "$n already off"
    }
}
foreach ($n in $nodes.Keys) { Wait-PoweredOff $n }

# --- Phase 2: head node, only after workers are down ---
if (Test-Running 'head01') {
    Write-Host "shutting down head01 ..."
    Invoke-Expression "$ssh slater@192.168.56.10 'sudo shutdown now'" 2>$null
    Wait-PoweredOff 'head01'
} else {
    Write-Host "head01 already off"
}

Write-Host "`ncluster is down." -ForegroundColor Green
