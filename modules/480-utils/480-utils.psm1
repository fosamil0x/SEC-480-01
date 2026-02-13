function 480banner()
{
    Write-Host "
 _  _      ___     ___       __    __  .___________. __   __          _______.
| || |    / _ \   / _ \     |  |  |  | |           ||  | |  |        /       |
| || |_  | (_) | | | | |    |  |  |  | `---|  |----`|  | |  |       |   (----`
|__   _|  > _ <  | | | |    |  |  |  |     |  |     |  | |  |        \   \    
   | |   | (_) | | |_| |    |  `--'  |     |  |     |  | |  `----.----)   |   
   |_|    \___/   \___/      \______/      |__|     |__| |_______|_______/    

   "
}

function 480connect([string] $server)
{
    $connection = $global:DefaultVIServer
    #test connection
    If ($connection) {
        $message = "Already connected to {0}" -f $connection
        
        Write-Host -foregroundcolor Green $message
    }else
    {
        Write-host "Connecting, provide credentials"
        $connection = Connect-VIServer -server $server
    }

}

function 480config ([string] $config_path)
{
    # Tell user that it's looking for the provided path
    Write-host "Reading $config_path"
    #set config to null before running the content of the function
    $conf=$null
    #test the path and let the user know if it works or not
    If (test-path $config_path)
    {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-json)
        $msg = "Using config at {0}" -f $config_path
        Write-Host -ForegroundColor "Green" $msg
    }
    else {
        Write-Host -ForegroundColor "Yellow" "No Config Path found"
    }
    #end with the config
    return $conf
}

function select-vm([string] $folder)
#Choose a VM to clone in a provided folder
{
    $selected_vm=$null
    try {
        
        # Give each VM a number from the provided folder
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            write-host [$index] $vm.name
            $index+=1
        }
        # Error handling for an invalid number provided
        $max_index = $index -1
        do {
            # Choose a VM with a valid number
            $pick_index = Read-Host "Select an index number [x] between 1 and $max_index without brackets"
        } while (($pick_index -lt 1) -or ($pick_index -gt $max_index))

        # Set the selected VM to a variable
        $selected_vm = $vms[$pick_index -1]
        Write-Host "Using $($selected_vm)" -ForegroundColor Green
        return $selected_vm
    }
    catch {
        # Give an error message as needed
        # More debugging code for issues I had
        # Write-Host "Caught Error : $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Invalid Folder $folder" -ForegroundColor Red
    }
}

function cloner([string] $config_path)
{
    Clear-Host
    
    # Run your banner
    480banner
    # Write the Config Path
    Write-Host "Config Path: $config_path"
    # Get content from the config file
    $config = Get-Content -Raw -Path $config_Path | ConvertFrom-Json

    # Define Defaults
    $server = $config.vcenter_server
    $folder = $config.vm_folder
    $esxi = $config.esxi_host
    $datastore = $config.default_datastore
    $snapshot = $config.default_snapshot
    $network = $config.default_network

    # Give users an option to redefine variables

    # Define user_server
    $user_server = Read-Host "What server do you want? [$server]"
    # Lock in user_server
    If ([string]::IsNullOrWhiteSpace($user_server)) {
        $user_server = $server
    }
    # Connect to vcenter
    480connect -server $user_server

    # do loop with error handling for finding the right folder
    do {
        
        # Define user_folder
        $user_folder = Read-Host "What folder do you want? [$folder]"
        # Lock in user_folder
        if ([string]::IsNullOrWhiteSpace($user_folder)) {
            $user_folder = $folder
        }

        # check the folder and get VM Names
        $folder_test = Get-Folder -Name $user_folder -ErrorAction SilentlyContinue
        # Check to make sure it actually works
        if (-not $folder_test) {
            write-host "Folder '$user_folder' not found, please try another folder name" -Foregroundcolor Red
        }
    } while  (-not $folder_test)

    # do loop with error handling for finding the right snapshot
    do {
        
        # Set a selected VM with that folder
        $selected_vm = select-vm -folder $user_folder
        # Define user_snapshot
        $user_snapshot = Read-Host "What snapshot do you want? [$snapshot]"
        # Lock in user_snapshot
        if ([string]::IsNullOrWhiteSpace($user_snapshot)) {
            $user_snapshot = $snapshot
        }

        # check the folder and get VM Name
        # write-host "$selected_vm is Selected_vm"
        $snapshot_test = Get-Snapshot -VM $selected_vm -Name "$user_snapshot" -ErrorAction SilentlyContinue
        if (-not $snapshot_test) {
            write-host "Snapshot '$user_snapshot' not found, please try another snapshot name" -Foregroundcolor Red
        }
    } while  (-not $snapshot_test)
    
    # Tell the user what snapshot you're using
    Write-Host "Using snapshot '$user_snapshot'" -ForegroundColor Green

    # Print the snapshot information if you're testing, uncomment line below
    # Get-Snapshot -VM $selected_vm -Name "$user_snapshot"
    
    #
    # Set a datastore with another do loop
    do {
        # Define user_datastore
        $user_datastore = Read-Host "What datastore do you want? [$datastore]"
        # Lock in user_datastore
        if ([string]::IsNullOrWhiteSpace($user_datastore)) {
            $user_datastore = $datastore
        }

        # Check to make sure the datastore works
        $datastore_test = Get-Datastore -Name "$user_datastore" -ErrorAction SilentlyContinue
        if (-not $datastore_test) {
            write-host "Datastore '$user_datastore' not found, please try another datastore name" -Foregroundcolor Red
         } 
        } while (-not $datastore_test)
        
        # Print the datastore info to the screen if you wanna make sure it's working. Just uncomment the line below
        # Get-Datastore -Name $user_datastore | Select-Object Name, FreeSpaceGB, CapacticyGB | Sort-Object Name | Format-Table -Autosize
        Write-Host "Using Datastore '$user_datastore'" -ForegroundColor Green

        # Use another do loop for getting an esxi host    
    do {
        # Define user_esxi
        $user_esxi = Read-Host "What ESXI host do you want? [$esxi]"
        # Lock in user_esxi
        if ([string]::IsNullOrWhiteSpace($user_esxi)) {
            $user_esxi = $esxi
        }

        # Check to make sure the datastore works
        $esxi_test = Get-VMHost -Name "$user_esxi" -ErrorAction SilentlyContinue
        if (-not $esxi_test) {
            write-host "ESXI host '$user_esxi' not found, please try another ESXI host" -Foregroundcolor Red
         } 
        } while (-not $esxi_test)
        
        # Tell the user what host you're on
        Write-Host "Using ESXI host '$user_esxi'" -ForegroundColor Green

        # Print the ESXI info to the screen if you wanna make sure it's working. Just uncomment the line below
        # Get-VMHost -Name $user_esxi | Select-Object Name, ConnectionState, Version | Sort-Object Name | Format-Table -Autosize
        
        # Force $new_vm_name to be defined
        # Make new_vm_name null
        $new_vm_name = $null
        # Make a loop for if new_vm_name already exists or if it's empty
        while ([string]::IsNullOrWhiteSpace($new_vm_name) -or (Get-VM -Name $new_vm_name -ErrorAction SilentlyContinue)) {
            
            # If it was already set but exists, tell the user
            if (-not [string]::IsNullOrWhiteSpace($new_vm_name)) {
                Write-Warning "VM '$new_vm_name' already exists. Please enter a different name."
            }
            
            # Prompt for input
            $vmName = Read-Host "Enter a new, unique VM name"
        }

        # Tell user what the new_vm_name is
        Write-Host "Using '$new_vm_name' as New VM Name" -ForegroundColor Green
        
        # Set clone type to linked or full
        $clone_type = Read-Host "What clone type would you like? Enter 'F'ull or 'L'inked"

    if ($clone_type -eq "L") {
        Write-Host "Creating [L]INKED clone '$new_vm_name' from '$selected_vm'..." -ForegroundColor Green
        $newvm = New-VM -LinkedClone `
                        -Name $new_vm_name `
                        -VM $selected_vm `
                        -ReferenceSnapshot $user_snapshot `
                        -VMHost $user_esxi `
                        -Datastore $user_datastore

        # Snapshot the new clone
        Write-Host "Taking snapshot of new VM called 'base'..." -ForegroundColor Green
        $newvm | New-Snapshot -Name "base"

        # Open a do loop to get the network figured out without attempting to make a new linked clone
        do {
        # Set the network
        $user_network = Read-Host "What network do you want to use? [$network]"
        # Lock in user_datastore
        if ([string]::IsNullOrWhiteSpace($user_network)) {
            $user_network = $network
        }

        # Check to make sure the network exists
        $network_test = Get-VirtualNetwork -Name "$user_network" -ErrorAction SilentlyContinue
        if (-not $network_test) {
            write-host "Network '$user_network' not found, please try another network name" -Foregroundcolor Red
         } 
        } while (-not $network_test) 
        
        # Print the Network info to the screen if you wanna make sure it's working. Just uncomment the line below
        Write-Host "Using Network '$user_network'..." -ForegroundColor Green
        Write-Host "Attempting to set network..."
        $newvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $user_network

        Write-Host "output of 'newvm | Get-NetworkAdapter Select-Object Parent, NetworkName | Format-Table -Autosize'"
        $newvm | Get-NetworkAdapter | Select-Object Parent, NetworkName | Format-Table -Autosize
        }

    elseif ($clone_type -eq "F") {
    Write-Host "Creating [F]ULL clone '$new_vm_name' from '$selected_vm'..."

    # Create linked clone temporarily, then full clone from that
    $tempName = "{0}.linked-temp" -f $selected_vm
    Write-host '$tempName'
    Write-Host "Creating [L]inked clone first..."
    $linkedvm = New-VM -LinkedClone `
                       -Name $tempName `
                       -VM $selected_vm `
                       -ReferenceSnapshot $user_snapshot `
                       -VMHost $user_esxi `
                       -Datastore $user_datastore

    # Now create a full clone from the temporary linked clone
    Write-Host "Creating [F]ull clone now ..."
    $newvm = New-VM -Name $new_vm_name `
                    -VM $linkedvm `
                    -VMHost $user_esxi `
                    -Datastore $user_datastore

    # Snapshot of the new full clone
    Write-Host "Taking snapshot of new full clone called 'base'..."
    $newvm | New-Snapshot -Name "base"

    # Clean up the temporary linked clone
    Write-Host "Removing temporary linked clone..."
    $linkedvm | Remove-VM -Confirm:$false
    Write-Host "Temporary linked clone '$($linkedvm.Name)'"# Set the network
        # Open a do loop to get the network figured out without attempting to make a new linked clone
        do {
        # Set the network
        $user_network = Read-Host "What network do you want to use? [$network]"
        # Lock in user_datastore
        if ([string]::IsNullOrWhiteSpace($user_network)) {
            $user_network = $network
        }
        # Check to make sure the network exists
        $network_test = Get-VirtualNetwork -Name "$user_network" -ErrorAction SilentlyContinue
        if (-not $network_test) {
            write-host "Network '$user_network' not found, please try another network name" -Foregroundcolor Red
         } 
        } while (-not $network_test) 
    
        # Print the Network info to the screen if you wanna make sure it's working. Just uncomment the line below
        Write-Host "Using Network '$user_network'..." -ForegroundColor Green
        Write-Host "Attempting to set network..."
        $newvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $user_network

        Write-Host "output of 'newvm | Get-NetworkAdapter Select-Object Parent, NetworkName | Format-Table -Autosize'"
        $newvm | Get-NetworkAdapter | Select-Object Parent, NetworkName | Format-Table -Autosize

        }
    } 
else {
    Write-Error "CloneType must be 'F'ull or 'L'inked."
    }