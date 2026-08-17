# create-vms.ps1 — provision the three cluster VMs from the command line.
#
# Builds head01 (SLURM controller / NFS / monitoring) and node01/node02
# (compute) as VirtualBox guests, each with:
#   NIC1 = NAT            -> internet access for package installs
#   NIC2 = host-only net  -> private 192.168.56.0/24 "cluster network"
# Disks are dynamically allocated: they only consume host space as data
# is written inside the guest.
#
# Idempotent-ish: skips a VM if one with the same name already exists.
# Re-run after deleting a VM (VBoxManage unregistervm <name> --delete)
# to rebuild it — the point of scripting this instead of using the GUI.

$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VmDir      = "$HOME\VirtualBox VMs"
$IsoPath    = "$HOME\Downloads\Rocky-9-latest-x86_64-minimal.iso"

$vms = @(
    @{ Name = "head01"; Cpus = 2; MemMB = 4096; DiskMB = 30720 }
    @{ Name = "node01"; Cpus = 2; MemMB = 3072; DiskMB = 20480 }
    @{ Name = "node02"; Cpus = 2; MemMB = 3072; DiskMB = 20480 }
)

# The host-only network is the VMs' private switch; VirtualBox creates one
# named like this at install time. Fail loudly if it's missing.
$hostOnlyIf = (& $VBoxManage list hostonlyifs |
    Select-String '^Name:\s+(.+)$').Matches |
    ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
if (-not $hostOnlyIf) {
    throw "No host-only interface found. Create one: VBoxManage hostonlyif create"
}

foreach ($vm in $vms) {
    $existing = & $VBoxManage list vms
    if ($existing -match "`"$($vm.Name)`"") {
        Write-Host "$($vm.Name): already exists, skipping"
        continue
    }

    Write-Host "Creating $($vm.Name) ($($vm.Cpus) vCPU, $($vm.MemMB) MB RAM, $([int]($vm.DiskMB/1024)) GB disk)"

    # Register the VM. --ostype tells VirtualBox to pick RHEL9-appropriate
    # virtual hardware defaults (chipset, APIC, etc.).
    & $VBoxManage createvm --name $vm.Name --ostype "RedHat9_64" --register --basefolder $VmDir

    & $VBoxManage modifyvm $vm.Name `
        --cpus $vm.Cpus --memory $vm.MemMB --vram 16 `
        --graphicscontroller vmsvga `
        --nic1 nat `
        --nic2 hostonly --hostonlyadapter2 $hostOnlyIf `
        --boot1 dvd --boot2 disk --boot3 none --boot4 none `
        --audio-enabled off --usb off

    # Disk: VDI grows on demand up to DiskMB. SATA/AHCI is the standard
    # virtual disk controller; the guest sees it as /dev/sda.
    $disk = Join-Path $VmDir "$($vm.Name)\$($vm.Name).vdi"
    & $VBoxManage createmedium disk --filename $disk --size $vm.DiskMB --format VDI
    & $VBoxManage storagectl $vm.Name --name "SATA" --add sata --controller IntelAhci --portcount 2
    & $VBoxManage storageattach $vm.Name --storagectl "SATA" --port 0 --device 0 --type hdd --medium $disk

    # Optical drive with the Rocky ISO — first boot lands in the installer.
    & $VBoxManage storageattach $vm.Name --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $IsoPath
}

Write-Host "`nDone. Current VMs:"
& $VBoxManage list vms
