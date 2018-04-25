#requires -version 3
#
#  .SYNOPSIS
#
#  XenApp-GetAppsReport [-DeliveryController="localhost"] [-OutFile="ScriptDirectory\XenApp-GetAppsReport.csv"] [-PerApplication]
#
#  .DESCRIPTION
#
#  PowerShell script connects to specified delivery controller and fetch application/server information, qfarm /app analog
#
#  CSV File format: Application; Server
#
#  .EXAMPLE
#
#  1. Connect to localhost and fetch application report 1 line per each server to ScriptDirectory\XenApp-GetAppsReport.csv
#
#     XenApp-GetAppsReport
#
#  2. Connect to vmww3672 and fetch application report 1 line per each application to C:\Scripts.report.csv
#
#     XenApp-GetAppsReport -DeliveryController vmww3672 -OutFile "C:\Scripts.report.csv" -PerAppication
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Delivery Controller
#
   [Parameter(Mandatory=$false)]
   [string]$DeliveryController="localhost",
#
#  Output file
#
   [Parameter(Mandatory=$False)]
   [string]$OutFile=$PSScriptRoot+"\XenApp-GetAppsReport.csv",
#
#  PerApplication flag
#
   [Parameter(Mandatory=$False)]
   [switch]$PerApplication
)
#
# End of parameters block
#
#_______________________________________________________
#
# Add Citrix PowerShell Snap-In
#
    Add-PSSnapin Citrix.XenApp.Commands
#
# Get list of all applications
#
    $appNames = get-xaapplication -ComputerName $DeliveryController | select BrowserName
#
# Create file structure
#
    Add-Content $OutFile "Application;Server"  
#
# For each application
#
foreach($name in $appNames.BrowserName){
#
# Get list of servers
#
    $result = Get-XAApplicationReport -BrowserName $name -ComputerName $DeliveryController | select ServerNames
    if(-not $PerApplication){
#
#Prints a record for each server
#
        foreach ($server in $result.ServerNames){
            Write-Host $name $server
            Add-Content $OutFile "$name;$server"
        }

    }else{
#
#Prints a record for each application
#
        $servers = $result.ServerNames
        Write-Host $name $servers
        Add-Content $OutFile "$name;$servers"
    }
}