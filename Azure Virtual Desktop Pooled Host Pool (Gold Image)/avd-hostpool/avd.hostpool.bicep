// Main template to deploy a set of landing zone components at a subscription level
targetScope = 'subscription'

@description('Location of resources.')
param location string = 'australiaeast'

@description('Environment (prd/tst/qa).')
param worksSpacefriendlyName string

@description('Shortname of location. Used for resource naming.')
param hostPoolFriendlyName string

@description('Shortname of Landing Zone. Used for resource naming.')
param avdRgName string

@description('Shared Services Resource Group Name')
param shdSvcsRgName string

@description('Shared Services subscription ID')
param platformSubId string

@description('Shared Services Log Analytics Workspace Name')
param logWorkspaceName string

@description('AVD Host Location')
param avdHostLocation string = 'eastus'

@description('Host Pool Type')
param hostPoolType string = 'Pooled'

@description('Location for all standard resources to be deployed into.')
param loadBalancerType string = 'BreadthFirst'

@description('Location for all standard resources to be deployed into.')
param preferredAppGroupType string = 'desktop'

@description('Maximu Sessions allowed per VM Host')
param maxSessionLimit int = 5


var logAnalyticsId = resourceId(platformSubId, shdSvcsRgName, 'Microsoft.OperationalInsights/workspaces', logWorkspaceName)


param baseTime string = utcNow('u')
var expirationTime = dateTimeAdd(baseTime, 'P3D')

// Resource Names

var diagSettings = {
  name: 'diag-log'
  workspaceId: logAnalyticsId
  storageAccountId: ''
  eventHubAuthorizationRuleId: ''
  eventHubName: ''
  enableLogs: true
  enableMetrics: false
  retentionPolicy: {
    days: 0
    enabled: false
  }
}

resource rg_shdSvcs 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdRgName
  location:location
}

module deployAVD '../../../../../Modules/virtual-desktops/avd.hostpool.bicep' = {
  scope: resourceGroup(rg_shdSvcs.name)
  name: 'deployHostPool'
  params: {
    location: avdHostLocation
    hostPoolFriendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    worksSpacefriendlyName: worksSpacefriendlyName
    expirationTime: expirationTime
    diagSettings: diagSettings
    maxSessionLimit:maxSessionLimit
  }
}


output avdRgName string = avdRgName
output hostPoolFriendlyName string = hostPoolFriendlyName
output worksSpacefriendlyName string = worksSpacefriendlyName
output hostpoolid string = deployAVD.outputs.hostPoolId
