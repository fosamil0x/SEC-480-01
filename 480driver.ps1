# import your module
Import-Module '/home/luc-480/Desktop/SEC-480-01/modules/480-utils/480-utils.psm1' -Force

# test your function
#480banner

# Provide config file
#$conf = 480config -config_path "/home/luc-480/Desktop/SEC-480-01/480.json"

# Use config file to connect to your server
#Write-Host "Connecting to your server"
#480connect -server $conf.vcenter_server

# Run your select VM function
#Write-Host "Selecting VM Options"
#select-vm -folder $conf.vm_folder

<#
$input = read-host "What do you want to do?"

if ($input -eq 1){
cloner -config_path "/home/luc-480/Desktop/SEC-480-01/480.json"
}
#>


# provide options
$prompt = "`n"
$prompt += "Welcome to the 480 Driver! Please select a function to run:`n"
$prompt += "[0] Exit this script`n"
$prompt += "[1] banner`n"
$prompt += "[2] cloner `n"
$prompt += "[3] new-network `n"
$prompt += "[4] get-ip `n"
$prompt += "[5] startorstop `n"
$prompt += "[6] 480connect `n"
$prompt += "[7] set-net `n"
$prompt += "[8] staticwinsrv"

# make a list for those options
$choices = @(0, 1, 2, 3, 4, 5, 6, 7, 8)

# make the prompt run with a while loop
$op = $true

while($op){
    # print the options and get an input
    Write-Host $prompt | Out-String
    $driver_choice = read-host

    if ($choices -contains $driver_choice){

        if ($driver_choice -eq 0){
            Write-Host "Exiting..." | Out-String
            exit
            $op = $false
        }

        if ($driver_choice -eq 1){
            480banner
        }

        elseif ($driver_choice -eq 2){
            cloner -config_path "/home/luc-480/Desktop/SEC-480-01/480.json"
        }

        elseif ($driver_choice -eq 3){
            new-network -config_path "/home/luc-480/Desktop/SEC-480-01/480.json"
        }

        elseif ($driver_choice -eq 4){
            get-ip
        }

        elseif ($driver_choice -eq 5){
            startvm-stopvm
        }

        elseif ($driver_choice -eq 6){
            $server_driver_choice = Read-Host "What server do you want to connect to?"
            Write-Host "Attempting to connect to $server_driver_choice"
            480connect -server $server_driver_choice
        }

        elseif ($driver_choice -eq 7){
            set-net
        }
        elseif ($driver_choice -eq 8){
            staticwinsrv
        }
    }
    else{
        Write-Host "Invalid option provided. Please select one of the provided options"
    }
}