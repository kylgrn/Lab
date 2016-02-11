
$affinitygroupname = "-affinity"

if ($StorageAccountCheck.StorageAccountName -eq $Null) {

Write-host "No Storage accounts exist, creating new storage account...."
Start-sleep 5
#Create Affinnity group using the Vnet name + append "-affinity", affinity group is required for creating a new storage account
New-AzureAffinityGroup -Name "$($vnet.name)$($affinitygroupname)" -Location $Vnet.Location -Description “Primary Affinity Group.”
$StorageAccountName = Read-Host "Please enter a name for your storage account, must be in all lower case letters"
New-AzureStorageAccount –StorageAccountName $StorageAccountName -AffinityGroup "$($vnet.name)$($affinitygroupname)" -Description “Primary 
storage account”
$StorageAccountName = Get-AzureStorageAccount
Write-Host "Successfully created storage account:$StorageaccountName.storageaccountname" -ForegroundColor Green
}
else
{
Write-host "Please select storage account" -ForegroundColor Green
$storageAccountName = (Get-AzureStorageAccount).StorageAccountName | Out-GridView -Title "Select Azure Storage Account" -PassThru
}



#"$($vnet.name)$($affinitygroupname)"