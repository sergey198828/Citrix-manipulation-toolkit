#requires -version 3
#
#  .SYNOPSIS
#
#  XenApp-CheckDisabledAccounts -DeliveryGroup [-DeliveryController="localhost"] [-LogFile="ScriptDirectory\XenApp-DisabledAccounts.csv"] [-deleteOlderThanDays=0]
#
#  .DESCRIPTION
#
#  PowerShell script connects to specified delivery controller and check all VDI machines in Specified delivery group if account of associated user is disabled (disabled users might be removed if deleteOlderThanDays flag set greater than 0 and last logon time greater than specified value).
#
#  CSV File format: Machine, User, Enabled, Last Connection Time, Days since last connection, Action
#
#  .EXAMPLE
#
#  1. Connect to localhost and fetch all users of "Mars Admin Desktops" Delivery Group to ScriptDirectory\XenApp-DisabledAccounts.csv file
#
#     XenApp-CheckDisabledAccounts -DeliveryGroup "Mars Admin Desktops"
#
#  2. Connect to vmww4712 and fetch all users of "Mars Admin Desktops" Delivery Group to C:\Disabled.csv file, removes disabled accounts association if last login time greater than 7 days
#
#     XenApp-CheckDisabledAccounts -DeliveryController "vmww4712" -DeliveryGroup "Mars Admin Desktops" -LogFile "C:\Disabled.csv" -deleteOlderThanDays 7
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Delivery Group
#
   [Parameter(Mandatory=$true)]
   [string]$DeliveryGroup,
#
#  Delivery Controller
#
   [Parameter(Mandatory=$false)]
   [string]$DeliveryController="localhost",
#
#  Log file
#
   [Parameter(Mandatory=$False)]
   [string]$LogFile=$PSScriptRoot+"\XenApp-DisabledAccounts.csv",
#
#  Delete flag
#
   [Parameter(Mandatory=$False)]
   [int]$deleteOlderDays = 0
)
#
# End of parameters block
#
#_______________________________________________________
#
# Add Citrix PowerShell Snap-In
#
   Add-PSSnapin Citrix.Broker.Admin.V2
#
# Getting current date and time
#
   $CurrentDateTime = Get-Date
#
# Create log dirictory if not exist
#
   $logDir = ([io.fileinfo]$LogFile).DirectoryName
   if (-not (Test-Path $logDir)){
     New-Item -ItemType Directory -Path $logDir
     Write-Host $logDir" created" -ForegroundColor Yellow
   }
#
# Prepare log file
#
   Write-host "Writing file "$LogFile -ForegroundColor Green
   Add-Content $LogFile "$DeliveryGroup---;---;---;$CurrentDateTime;---;---;---"
   Add-Content $LogFile “Machine;User;Enabled;Last connection time;Days since last connection;Action”;
#
# Fetching Machines information in specified delivery group from specified delivery controller
#
   $machines = get-brokermachine -AdminAddress $DeliveryController -DesktopGroupName $DeliveryGroup -MaxRecordCount 1000 | select-object MachineName, AssociatedUserNames, LastConnectionTime
#
# Check each machine
#
   foreach($machine in $machines){
     $machineName = $machine.MachineName
     $associatedUsers = $machine.AssociatedUserNames
     $lastconnectiontime = $machine.LastConnectionTime
     if($lastconnectiontime -eq $null){
       $daysSinceLastConnection = 9999
     }
     else{
       $daysSinceLastConnection = (New-TimeSpan -Start $lastconnectiontime -End $CurrentDateTime).Days
     }
#
# Check all users associated with machine
#
     foreach($associatedUser in $associatedUsers){
#
# Cutting "domain\"
#
       $pos = $associatedUser.IndexOf("\")
       $userString = $associatedUser.Substring($pos+1)
#
# Getting user account status
#
       try{
         $account = Get-ADUser $userString | Select-Object Enabled -ErrorAction Stop
         $accountStatus = $account.Enabled
       }
       catch{
         $accountStatus = $False
       }
#
# Removing disabled users if last logon greater that specified number of days
#
       $action = "Kept"
       if($accountStatus -eq $False){
         $action = "Candidate for removal"
         if(($deleteOlderDays -ne 0) -and ($daysSinceLastConnection -ge $deleteOlderDays)){
           Write-host "Removing "$associatedUser" from "$machineName -ForegroundColor "Red"
           Remove-BrokerUser -AdminAddress $DeliveryController -Machine $machineName -Name $associatedUser
           $action = "Removed"
         }
       }
#
# Writing to log and console
#
       Write-host "User "$associatedUser" associated with "$machineName" Enabled="$accountStatus" Days since last connection "$daysSinceLastConnection" action "$action
       Add-Content $LogFile “$machineName;$associatedUser;$accountStatus;$lastconnectiontime;$daysSinceLastConnection;$action”
     }
   }