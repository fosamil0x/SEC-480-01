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

# Run everything from your cloner function
cloner -config_path "/home/luc-480/Desktop/SEC-480-01/480.json"