#Select VM image

$Image = Get-AzureVMimage | where {$_.Label -like ‘Windows Server 2012 R2 Datacenter*’} | Select ImageFamily,Publisheddate,imagename| Out-GridView -Title "Select an Image" -PassThru | select

#$Image | Out-GridView -Title "Select an Image" -PassThru | select
$image