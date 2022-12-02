@description('Virtual machine name. Do not include numerical identifier.')
@maxLength(14)
param vmNameSuffix string

@description('Virtual machine location.')
param location string = resourceGroup().location


@description('Array of objects defining data disks, including diskType and size')
@metadata({
  note: 'Sample input'
  dataDisksDefinition: [
    {
      diskType: 'StandardSSD_LRS'
      diskSize: 64
      caching: 'none'
    } 
  ]
})
param dataDisksDefinition array


resource dataDisk 'Microsoft.Compute/disks@2020-12-01' = [for (item, j) in dataDisksDefinition: {
  name: '${vmNameSuffix}_datadisk_${j}'
  location: location
  properties: {
    creationData: {
      createOption: item.createOption
    }
    diskSizeGB: item.diskSize
  }
  sku: {
    name: item.diskType
  }
}]


//${format('{0:D2}', 1)}
