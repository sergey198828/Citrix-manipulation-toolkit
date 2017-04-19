#requires -version 3
#
#  .SYNOPSIS
#
#  XenApp-CheckDeliveryGroup -DeliveryGroup [-DeliveryController="localhost"] [-LogFile="ScriptDirectory\XenApp-DeliveryGroups.csv"]
#
#  .DESCRIPTION
#
#  PowerShell script connects to specified delivery controller and fetch machines information from specified delivery group like number of unassigned machines and machines in maintenance mode.
#
#  CSV File format: Assigned machines, Unassigned machines, Machines in maintenance mode, Total machines, Recomendation
#
#  .EXAMPLE
#
#  1. Connect to localhost and fetch "Mars Admin Desktops" Delivery Group to ScriptDirectory\XenApp-DeliveryGroups.csv file
#
#     XenApp-CheckDeliveryGroup -DeliveryGroup "Mars Admin Desktops"
#
#  2. Connect to vmww4712 and fetch "Mars Admin Desktops" Delivery Group to C:\Disabled.csv file
#
#     XenApp-CheckDeliveryGroup -DeliveryController "vmww4712" -DeliveryGroup "Mars Admin Desktops" -LogFile "C:\Disabled.csv"
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
   [string]$LogFile=$PSScriptRoot+"\XenApp-DeliveryGroups.csv"
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
   Add-Content $LogFile “Assigned machines;Unassigned machines;Machines in maintenance mode;Total machines;Recommendation”
#
# Fetching Machines information in specified delivery group from specified delivery controller
#
   $AssignedMachines = Get-BrokerMachine -AdminAddress $DeliveryController -DesktopGroupName $DeliveryGroup -IsAssigned $True -InMaintenanceMode $False -MaxRecordCount 1000
   $UnassignedMachines = Get-BrokerMachine -AdminAddress $DeliveryController -DesktopGroupName $DeliveryGroup -IsAssigned $False -InMaintenanceMode $False -MaxRecordCount 1000
   $MachinesInMaintenanceMode = Get-BrokerMachine -AdminAddress $DeliveryController -DesktopGroupName $DeliveryGroup -InMaintenanceMode $True -MaxRecordCount 1000
#
# Analizing delivery group
#
   $NumberOfAssignedMachines = $AssignedMachines.Count
   $NumberOfUnassignedMachines = $UnassignedMachines.Count
   $NumberOfMachinesInMaintenanceMode = $MachinesInMaintenanceMode.Count
   $TotalNumberOfMachines = $NumberOfAssignedMachines + $NumberOfUnassignedMachines + $NumberOfMachinesInMaintenanceMode
   $FivePersent = $TotalNumberOfMachines * 0.05
   $UnassignedMachinesRatio = $NumberOfUnassignedMachines / $TotalNumberOfMachines
   $Recommendation = "No action required"
   if($UnassignedMachinesRatio -lt 0.05){ 
      $Recommendation = "Need to add $FivePersent machines to delivery group";
   }
   if($UnassignedMachinesRatio -gt 0.1){ 
      $Recommendation = "Need to remove $FivePersent machines from delivery group";
   }
#
# Writing to log and console
#
       Write-host "Number of assigned machines is "$NumberOfAssignedMachines", Number of unassigned machines is "$NumberOfUnassignedMachines", Number of machines in maintenance mode "$NumberOfMachinesInMaintenanceMode" ,Total number of Machines "$TotalNumberOfMachines" ,UnassignedMachinesRatio "$UnassignedMachinesRatio" ,Recommendation "$Recommendation
       Add-Content $LogFile "$NumberOfAssignedMachines;$NumberOfUnassignedMachines;$NumberOfMachinesInMaintenanceMode;$TotalNumberOfMachines;$Recommendation"
