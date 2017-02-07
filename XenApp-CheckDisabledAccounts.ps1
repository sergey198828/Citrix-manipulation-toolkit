#requires -version 3
#
#  .SYNOPSIS
#
#  XenApp-CheckDisabledAccounts -DeliveryController -DeliveryGroup [-OutputFile="ScriptDirectory\XenApp-DisabledAccounts.csv"]
#
#  .DESCRIPTION
#
#  PowerShell script connects to specified delivery controller and export all VDI machines in Specified delivery group with flag if specified account is disabled
#
#  CSV File format: Machine, Users, Enabled
#
#  .EXAMPLE
#
#  1. Connect to vmww4712 and fetch all users of "Mars Admin Desktops" Delivery Group to ScriptDirectory\XenApp-DisabledAccounts.csv file
#
#     XenApp-CheckDisabledAccounts -DeliveryController "vmww4712" -DeliveryGroup "Mars Admin Desktops"
#
#  2. Connect to vmww4712 and fetch all users of "Mars Admin Desktops" Delivery Group to C:\Disabled.csv file
#
#     XenApp-CheckDisabledAccounts -DeliveryController "vmww4712" -DeliveryGroup "Mars Admin Desktops" -OutputFile "C:\Disabled.csv"
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Delivery Controller
#
   [Parameter(Mandatory=$true)]
   [string]$DeliveryController,
#
#  Delivery Group
#
   [Parameter(Mandatory=$true)]
   [string]$DeliveryGroup,
#
#  Output file
#
   [Parameter(Mandatory=$False)]
   [string]$OutputFile=$PSScriptRoot+"\XenApp-DisabledAccounts.csv"
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
# Prepare output file
#
   Write-host "Writing file "$OutputFile
   Add-Content $OutputFile “Machine;User;Enabled”;
#
# Fetching Machines information in specified delivery group on specified delivery controller
#
   $machines = get-brokermachine -AdminAddress $DeliveryController -DesktopGroupName $DeliveryGroup -MaxRecordCount 1000 | select-object MachineName, AssociatedUserNames
#
# Looping over all machines
#
   foreach($machine in $machines){
     $machineName = $machine.MachineName
     $associatedUsers = $machine.AssociatedUserNames
#
# Looping over all users associated with machine
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
         $accountStatus = "Unable to check"
       }
#
# Writing to output file and console
#
       Write-host "User "$associatedUser" associated with "$machineName" Enabled="$accountStatus
       Add-Content $OutputFile “$machineName;$associatedUser;$accountStatus”
     }
   }