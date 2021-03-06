## Adding multiple data disks to an existing Azure VM using PowerShell

## Please ensure you run Add-AzureRmAccount to login prior to running this script

## Variables required to run the script:
$rgName = '<resource_group_name>'           # Name of the RG (Resource Group)
$vmName = '<name_of_VM_SKU_instance>'       # Name of the VM (Virtual Machine)
$location = '<location_of_NV6>'             # Location = which Azure region does the VM exist in?
$storageType = '<storage_type>'             # Select either 'PremiumLRS' or 'StandardLRS'
$disksize = <number_of_GB>                  # Size of each disk being added
$maxdisks = <number_of_disks>               # Total number of disks we want to add as part of this operation

## We start at disk 0, so reducing the above by 1
$actualdisks = $maxdisks - 1                # We don't need to modify this variable

foreach ($i in 0..$actualdisks)
{
  $dataDiskName = $vmName + '_datadisk_' + $i
  $diskConfig = New-AzureRmDiskConfig -AccountType $storageType -Location $location -CreateOption Empty -DiskSizeGB $disksize
  $dataDisk = New-AzureRmDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $rgName
  $vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName 
  $vm = Add-AzureRmVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun $i
  Update-AzureRmVM -VM $vm -ResourceGroupName $rgName
} 
