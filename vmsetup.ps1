# Define Parameters
param(
    [string]$VmName,
    [string]$SnapshotName,
    [string]$EsxiHost,
    [string]$DatastoreName,
    [string]$NewVmName,
    [ValidateSet("F","L")]
    [string]$CloneType
)

# Prompt for anything not supplied
Write-Host "Available VMs..."
Get-VM
if (-not $VmName)       { $VmName       = Read-Host "Enter source VM name (e.g. 480-device-firstname)" }
Write-Host "Available Snapshots..."
Get-Snapshot -VM "$VmName" | Select-object Name, Description, Created | Format-Table -Autosize
if (-not $SnapshotName) { $SnapshotName = Read-Host "Enter snapshot name (e.g. base)" }
Write-Host "Available Hosts..."
Get-VMHost | Select-Object Name, ConnectionState | Format-Table -Autosize
if (-not $EsxiHost)     { $EsxiHost     = Read-Host "Enter ESXi host/IP" }
Write-Host "Available Datastores..."
Get-Datastore | Select-Object Name, FreeSpaceGB, CapacticyGB | Sort-Object Name | Format-Table -Autosize
if (-not $DatastoreName){ $DatastoreName= Read-Host "Enter datastore name" }
if (-not $NewVmName)    { $NewVmName    = Read-Host "Enter new VM name (e.g. Win10.base)" }
if (-not $CloneType)    { $CloneType    = Read-Host "Clone type? Enter [F]ull or [L]inked" }

# Normalize input a bit
$CloneType = $CloneType.Trim()

# Get base objects
$vm       = Get-VM -Name $VmName
$snapshot = Get-Snapshot -VM $vm -Name $SnapshotName
$vmhost   = Get-VMHost -Name $EsxiHost
$ds       = Get-Datastore -Name $DatastoreName

if ($CloneType -eq "L") {
    Write-Host "Creating [L]INKED clone '$NewVmName' from '$VmName'..."
    $newvm = New-VM -LinkedClone `
                    -Name $NewVmName `
                    -VM $vm `
                    -ReferenceSnapshot $snapshot `
                    -VMHost $vmhost `
                    -Datastore $ds

    # Snapshot the new clone
    Write-Host "Taking snapshot of new VM called 'base'..."
    $newvm | New-Snapshot -Name "base"
    Write-Host "Be sure to validate the network of the new VM! It is probably on VM Network"

}
elseif ($CloneType -eq "F") {
    Write-Host "Creating [F]ULL clone '$NewVmName' from '$VmName'..."

    # Approach: create linked clone temporarily, then full clone from that
    $tempName = "{0}.linked-temp" -f $VmName
    Write-Host "Creating [L]inked clone first..."
    $linkedvm = New-VM -LinkedClone `
                       -Name $tempName `
                       -VM $vm `
                       -ReferenceSnapshot $snapshot `
                       -VMHost $vmhost `
                       -Datastore $ds

    # Now create a full clone from the temporary linked clone
    Write-Host "Creating [F]ull clone now ..."
    $newvm = New-VM -Name $NewVmName `
                    -VM $linkedvm `
                    -VMHost $vmhost `
                    -Datastore $ds

    # Snapshot of the new full clone
    Write-Host "Taking snapshot of new full clone called 'base'..."
    $newvm | New-Snapshot -Name "base"
    Write-Host "Be sure to validate the network of the new VM! It is probably on VM Network"

    # Clean up the temporary linked clone
    Write-Host "Removing temporary linked clone..."
    $linkedvm | Remove-VM -Confirm:$false
    Write-Host "Temporary linked clone '$($linkedvm.Name)'"
}
else {
    Write-Error "CloneType must be '[F]ull' or '[L]inked'."
}
