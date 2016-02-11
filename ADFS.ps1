##########################################################################################################
<#
.SYNOPSIS
    Deploys necessary configurations and components for an ADFS farm in Azure, including VMs, Cloud Services, and StorageAccount
    
.DESCRIPTION
    Script will provision a total of 7 servers, a combination of ADFS, WAP, two Domain Controllers, and a single AAD Connect server. Domain Controllers are provisioned in-line with Microsoft's
    best practices. You will need to update the "Computer naming options" variables with the desired naming convention. This script also assumes that you've setup a VNET with the following subnets:
    AD, ADFS, Apps, DMZ. 
#
.NOTES
    THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
    FITNESS FOR A PARTICULAR PURPOSE.

    This sample is not supported under any Microsoft standard support program or service. 
    The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
    implied warranties including, without limitation, any implied warranties of merchantability
    or of fitness for a particular purpose. The entire risk arising out of the use or performance
    of the sample and documentation remains with you. In no event shall Microsoft, its authors,
    or anyone else involved in the creation, production, or delivery of the script be liable for 
    any damages whatsoever (including, without limitation, damages for loss of business profits, 
    business interruption, loss of business information, or other pecuniary loss) arising out of 
    the use of or inability to use the sample or documentation, even if Microsoft has been advised 
    of the possibility of such damages, rising out of the use of or inability to use the sample script, 
    even if Microsoft has been advised of the possibility of such damages. 
#>
#Select subscription to provision services in
    Write-Host Please select target subscription to provision services in: -ForegroundColor Green
    $subscriptionName = Get-AzureSubscription | select SubscriptionName,Environment,DefaultAccount,SubscriptionID | Out-GridView -Title "Select Azure Subscription" -PassThru | select

if ($Subscriptionname.SubscriptionName -eq $Null)
{
Write-Error "No Azure subscription found, please add your subscription(s) using the add-account cmdlet and rerun the script"
exit
}
else
{
Select-AzureSubscription -SubscriptionId $subscriptionName.subscriptionID
Write-Host Selected subscription: $subscriptionName.SubscriptionName -ForegroundColor Green
}

#Get local administrator credentials, these will be used for initial login on VM’s
    Write-Host "Please supply local administrator credentials to be used for each new VM" -ForegroundColor Green
    Start-Sleep 3
    $localadmincred=get-credential
    $Vnets = Get-AzureVnetSite 
    $StorageAccountCheck = Get-AzureStorageAccount | select StorageAccountName

#Computer naming options, note that computer names can't be longer than 15 characters, be entirely numeric, or contain unsupported characters. 

    #Domain Controllers
        $DC1=”Contoso-DC1”
        $DC2=”Contoso-DC2”
        $ADService=”Contoso-AD”
        $ADAvailability=”Contoso-AD-Availability”
    #ADFS Servers
        $ADFS1=”Contoso-ADFS1”
        $ADFS2=”Contoso-ADFS2”
        $ADFSService=”Contoso-ADFS”
        $ADFSAvailability=”Contoso-ADFS-Availability”
    #WAP Servers
        $WAP1=”Contoso-WAP1”
        $WAP2=”Contoso-WAP2”
        $WAPService=”Contoso-WAP”
        $WAPAvailability=”Contoso-WAP-Availability”
    #AAD Connect
        $SYNC=”Contoso-sync”
        $SYNCService=”Contoso-Apps”

#Check for existing VNet, if no VNET exists, error out and tell the user to create one using the portal

if ($Vnets.Name -eq $Null) {
Write-Error "No Azure VNET exists, please use the management portal to create a VNET before using this script"
exit
}
else
{
Write-host "Please select VNET" -foreground Green
$Vnet = Get-AzureVnetSite | select Name,Location | Out-GridView -Title "Select Azure VNet" -PassThru
}

#Check for existing storage account, if one doesn't exist create one, otherwise prompt to select the storage account

if ($StorageAccountCheck.StorageAccountName -eq $Null) {

Write-host "No Storage accounts exist, creating new storage account...."
Start-sleep 5
$StorageAccountName = Read-Host "Please enter a name for your storage account, must be in all lower case letters"
New-AzureStorageAccount –StorageAccountName $StorageAccountName -Location $Vnet.Location -Description “Primary storage account”
#Set-AzureStorageAccount -StorageAccountName $StorageAccountName -GeoReplicationEnabled $true
$StorageAccountName = Get-AzureStorageAccount
Write-Host "Successfully created storage account" -ForegroundColor Green
}
else
{
Write-host "Please select storage account" -ForegroundColor Green
$storageAccountName = Get-AzureStorageAccount | select storageaccountname | Out-GridView -Title "Select Azure Storage Account" -PassThru | select
}

Start-Sleep 10

#Set Account Storage

$subscriptionid = Get-AzureSubscription | Where-Object {$_.iscurrent -eq “True”} | Select-Object -ExpandProperty subscriptionid

$Storage=Get-AzureStorageAccount | Select-Object -ExpandProperty label

Set-AzureSubscription -subscriptionid $subscriptionid -CurrentStorageAccountname $storageaccountname.storageaccountname
#SET PREFERRED IMAGE

$imgnm = Get-AzureVMimage | where {$_.Label -like ‘Windows Server 2012 R2 Datacenter*’} | Select ImageFamily,Publisheddate,imagename| Out-GridView -Title "Select Windows Image to use for VM creation" -PassThru | select

#VIRTUAL MACHINES

#Domain Controller 1

$DC1VM = New-AzureVMConfig -name $DC1 -instancesize Medium -imagename $imgnm.ImageName -availabilitysetname $ADAvailability | Add-AzureProvisioningConfig -Windows -AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘AD’ | Add-AzureDataDisk -CreateNew -DiskSizeinGB 15 –DiskLabel “DataDisk15” -LUN 0 
New-AzureVM -VMs $DC1VM -ServiceName $ADService -VNetName $Vnet.Name -Location $Vnet.Location

Start-Sleep 300

#Domain Controller 2

$DC2VM = New-AzureVMConfig -name $DC2 -instancesize Medium -imagename $imgnm.ImageName -availabilitysetname $ADAvailability | Add-AzureProvisioningConfig -Windows -AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘AD’ | Add-AzureDataDisk -CreateNew -DiskSizeinGB 15 –DiskLabel “DataDisk15” -LUN 0 
New-AzureVM -VMs $DC2VM -ServiceName $ADService -VNetName $Vnet.Name -Location $Vnet.Location

Start-Sleep 300

#ADFS Server 1

$ADFS1VM = New-AzureVMConfig -name $ADFS1 -instancesize Medium -imagename $imgnm.ImageName -availabilitysetname $ADFSAvailability | Add-AzureProvisioningConfig -Windows -AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘ADFS’ 
New-AzureVM -VMs $ADFS1VM -ServiceName $ADFSService -vnetname $VNet.Name -Location $Vnet.Location

Start-Sleep 300

#ADFS Server 2

$ADFS2VM = New-AzureVMConfig -name $ADFS2 -instancesize Medium -imagename $imgnm.ImageName -availabilitysetname $ADFSAvailability | Add-AzureProvisioningConfig -Windows -AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘ADFS’ 
New-AzureVM -VMs $ADFS2VM -ServiceName $ADFSService -vnetname $VNet.Name -Location $Vnet.Location

Start-Sleep 300

#WAP Server 1

$WAP1VM = New-AzureVMConfig -name $WAP1 -instancesize Medium -imagename $imgnm.ImageName -availabilitysetname $WAPAvailability | Add-AzureProvisioningConfig -Windows -AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘DMZ’ 
New-AzureVM -VMs $WAP1VM -ServiceName $WAPService -vnetname $VNet.Name -Location $Vnet.Location

Start-Sleep 300
#WAP Server 2

$WAP2VM = New-AzureVMConfig -name $WAP2 -instancesize Medium -imagename $imgnm.ImageName -availabilitysetname $WAPAvailability | Add-AzureProvisioningConfig -Windows -AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘DMZ’ 
New-AzureVM -VMs $WAP2VM -ServiceName $WAPService -vnetname $VNet.Name -Location $Vnet.Location

Start-Sleep 300

#SYNC Server

$SyncVM = New-AzureVMConfig -name $Sync -instancesize Medium -imagename $imgnm.ImageName | Add-AzureProvisioningConfig -Windows –AdminUsername $localadmincred.GetNetworkCredential().username -Password $localadmincred.GetNetworkCredential().password | Set-AzureSubnet ‘APPS’ 
New-AzureVM -Vms $SyncVM -Servicename $SyncService -vnetname $VNet.Name -Location $Vnet.Location