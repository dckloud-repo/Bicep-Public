targetScope = 'subscription'

@description('Shortname of location. Used for resource naming.')
param hostPoolFriendlyName string

@description('AVD Services RG Name')
param resourceRgName string

@description('Location for all standard resources to be deployed into.')
param workSpacefriendlyName string 

@description('Shared Services Resource Group Name')
param shdSvcsRgName string

@description('Shared Services subscription ID')
param platformSubId string

@description('Shared Services Log Analytics Workspace Name')
param logWorkspaceName string

var logAnalyticsId = resourceId(platformSubId, shdSvcsRgName, 'Microsoft.OperationalInsights/workspaces', logWorkspaceName)

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

var applicationGroupArray = [
  {
    appgroupName: 'FileExplorer'
    appgroupType: 'RemoteApp'
    applicationAlias: 'FileExplorer'
    applicationPath: 'c:\\windows\\explorer.exe'
    applicationDesc: 'Windows File Explorer'
  }
  {
    appgroupName: 'RemoteDesktop'
    appgroupType: 'RemoteApp'
    applicationAlias: 'RemoteDesktop'
    applicationPath: 'C:\\windows\\system32\\mstsc.exe'
    applicationDesc: 'Remote Desktop'
  }
  {
    appgroupName: 'SQLServerManagementStudio'
    appgroupType: 'RemoteApp'
    applicationAlias: 'SQLServerManagementStudio'
    applicationPath: 'C:\\Program Files (x86)\\Microsoft SQL Server Management Studio 18\\Common7\\IDE\\Ssms.exe'
    applicationDesc: 'SQL Server Management Studio'
  }
  {
    appgroupName: 'MicrosoftEdge'
    appgroupType: 'RemoteApp'
    applicationAlias: 'MicrosoftEdge'
    applicationPath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe'
    applicationDesc: 'Microsoft Edge'
  }
]

//This section has to be manually defined becauase of a bicep limitation during the time of the implementation
var applicationGroupIDArray = [
  '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceRgName}/providers/Microsoft.DesktopVirtualization/applicationgroups/desktop-appgroup'
  '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceRgName}/providers/Microsoft.DesktopVirtualization/applicationgroups/FileExplorer'
  '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceRgName}/providers/Microsoft.DesktopVirtualization/applicationgroups/RemoteDesktop'
  '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceRgName}/providers/Microsoft.DesktopVirtualization/applicationgroups/SQLServerManagementStudio'
  '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceRgName}/providers/Microsoft.DesktopVirtualization/applicationgroups/MicrosoftEdge'
]


resource rg_shdSvcs 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceRgName
}

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2021-09-03-preview' existing = {
  scope: resourceGroup(resourceRgName)
  name: hostPoolFriendlyName
}

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' existing = {
  scope: resourceGroup(resourceRgName)
  name: 'desktop-appgroup'
}


module applicationGroups '../virtual-desktops/avd.applicationgroup.bicep' = [for appgroup in applicationGroupArray: {
  scope: resourceGroup(rg_shdSvcs.name)
  name: 'deploy_avd_applicationgroups_${appgroup.appgroupName}'
  params: {
    appGroupName: appgroup.appgroupName
    appgroupType: appgroup.appgroupType
    hostpoolID: hostpool.id
    applicationAlias: appgroup.applicationAlias
    applicationDesc: appgroup.applicationDesc
    applicationPath: appgroup.applicationPath
    location: hostpool.location
  }
}]

module workspace '../virtual-desktops/avd.workspace.bicep' = {
  scope: resourceGroup(rg_shdSvcs.name)
  name: 'deploy_avd_workspace'
  dependsOn: [
    applicationGroups
  ]
  params: {
    avdworkspacename: workSpacefriendlyName
    location: hostpool.location
    appgroupref: applicationGroupIDArray
    diagSettings:diagSettings
  }
}
