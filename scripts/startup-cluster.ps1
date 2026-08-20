# startup-cluster.ps1 — cluster power-up, run on the Windows host.
#
# Mirror image of shutdown: head01 FIRST (it serves NFS, munge time base,
# and the scheduler), then the compute nodes. Each node gets a clock step
# immediately after boot — VirtualBox RTCs drift badly here, and munge
# credentials are time-windowed, so clock agreement is a hard requirement
# (see build log 2026-08-18: 10.5h of skew masqueraded as an auth failure).
#
# Idempotent: already-running VMs are left alone. Ends with the full
# health check; exit code is the health check's own.

$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$key = "$HOME\.ssh\hpc-lab"
$ssh = "ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=NUL -i `"$key`""

function Test-Running($name) {
    (& $vbm list runningvms) -match "`"$name`""
}

function Start-Node($name) {
    if (Test-Running $name) { Write-Host "$name already running" }
    else { & $vbm startvm $name --type headless | Out-Null; Write-Host "$name starting ..." }
}

function Wait-Ssh($ip, $timeoutSec = 240) {
    $t = 0
    while ($t -lt $timeoutSec) {
        Invoke-Expression "$ssh slater@$ip 'true'" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "$ip ssh up"; return $true }
        Start-Sleep 5; $t += 5
    }
    Write-Host "$ip NOT reachable after ${timeoutSec}s" -ForegroundColor Red
    return $false
}

function Sync-Clock($ip) {
    Invoke-Expression "$ssh slater@$ip 'sudo chronyc makestep >/dev/null; date'" 2>$null
}

# --- Phase 1: head node first ---
Start-Node 'head01'
if (-not (Wait-Ssh '192.168.56.10')) { exit 1 }
Write-Host "head01 clock: $(Sync-Clock '192.168.56.10')"

# --- Phase 2: compute nodes ---
Start-Node 'node01'
Start-Node 'node02'
$ok = (Wait-Ssh '192.168.56.11') -and (Wait-Ssh '192.168.56.12')
if (-not $ok) { exit 1 }
Write-Host "node01 clock: $(Sync-Clock '192.168.56.11')"
Write-Host "node02 clock: $(Sync-Clock '192.168.56.12')"

# --- Phase 3: prove it ---
Write-Host "`nrunning cluster health check ..." -ForegroundColor Cyan
Invoke-Expression "$ssh slater@192.168.56.10 './hpc-cluster-lab/scripts/cluster-health.sh'"
exit $LASTEXITCODE
