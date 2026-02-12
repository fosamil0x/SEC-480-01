function 480banner()
{
    Write-Host "
    **   ****   ****        **     **   **   **  **         **
   */*  */// * *///**      /**    /**  /**  //  /**        /**
  * /* /*   /*/*  */*      /**    /** ****** ** /**  ******/**
 ******/ **** /* * /*      /**    /**///**/ /** /** **//// /**
/////*  */// */**  /*      /**    /**  /**  /** /**//***** /**
    /* /*   /*/*   /*      /**    /**  /**  /** /** /////**// 
    /* / **** / ****       //*******   //** /** *** ******  **
    /   ////   ////         ///////     //  // /// //////  // 
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
        Write-Host "Selected $($selected_vm)"
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
        
        $select_vm_out = select-vm -folder $user_folder
        # Define user_snapshot
        $user_snapshot = Read-Host "What snapshot do you want? [$snapshot]"
        # Lock in user_snapshot
        if ([string]::IsNullOrWhiteSpace($user_snapshot)) {
            $user_snapshot = $snapshot
        }

        # check the folder and get VM Names
        write-host "$select_vm_out is select_vm_out"
        $snapshot_test = Get-Snapshot -VM $select_vm_out -Name "$user_snapshot" -ErrorAction SilentlyContinue
        if (-not $snapshot_test) {
            write-host "Snapshot '$user_snapshot' not found, please try another snapshot name" -Foregroundcolor Red
        }
    } while  (-not $snapshot_test)
    Get-Snapshot -VM $selected_vm -Name "$user_snapshot"
}