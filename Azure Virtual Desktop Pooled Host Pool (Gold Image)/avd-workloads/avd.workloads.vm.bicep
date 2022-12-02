// Main template to deploy a set of landing zone components at a subscription level
targetScope = 'subscription'

@description('Location of resources.')
param location string

@description('Shared Services Log Analytics Workspace Name')
param logWorkspaceName string

@description('VM Naming Prefix')
param VMprefix string

@description('Virtual Machin Image Verions')
param vmImageVerion string = ''

@description('Shortname of location. Used for resource naming.')
param hostPoolFriendlyName string

@description('AVD Services RG Name')
param resourceRgName string

@description('Shared Services Resource Group Name')
param shdSvcsRgName string

@description('Hub Virtual Network Name')
param corpVirtualNetworkName string

@description('Shared Platform (Network) Services Resources Group Name')
param corpPlatformRgName string

@description('Key Vault Name')
param keyvaultName string

@description('DSC Storage Container Name')
param dscStorageAccountContainer string

@description('DSC Storage Container Name')
param dscStorageAccount string

@description('Local User Name')
param localAdminUserName string = 'sym_ladmin'

@description('AVD Registration Token')
param avdregtoken string

@description('Local User Secret Name to retrive it from KV')
param localAdminSecretName string = 'localAdmin'

@description('Shared Services subscription ID')
param platformSubId string

@description('Corp Services subscription ID')
param resourceSubId string

@description('Domain to Join')
param domainToJoin string = ''

@description('Domain Join User Name')
param domainJoinUserName string = ''

@description('Domain Join User Secret Name to retrive it from KV')
param domainJoinSecretName string = ''

@description('RegistrationToken for the AVD environment')
@secure()
param pfxPassword string = ''

@description('Image Galary Resource Group name')
param  imageGRgName string = ''

@description('Image Galary Name')
param imageGName string = ''

@description('Image Definition Name')
param imageDefinitionName string = ''

@description('OU to join VM into.')
param ouPath string = 'OU=Servers,OU=AVD-03,OU=Sym AVD (Azure Virtual Desktops),OU=_Applications and Servers,DC=CONSET,DC=local'


//Parameters Set at the BICEP Template Level
@description('Virtual Machine Size')
param vmSize string = 'Standard_D4s_v3'

@description('AVD Fslogix profile container storage account')
param avdProfileStorage string

@description('Object containing resource tags.')
param tags object = {
  'backupType' : 'SpecialServers'
}

@description('Number of final hosts in the hostpool')
param number_Of_Instances int = 2

@description('Name of subnet for VM')
param SubnetName string = 'avdsubnet'

param schedules array = [
  {
    name: 'weekdays_schedule'
    daysOfWeek: [
        'Monday'
        'Tuesday'
        'Wednesday'
        'Thursday'
        'Friday'
    ]
    rampUpStartTime: {
        hour: 7
        minute: 0
    }
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 20
    rampUpCapacityThresholdPct: 60
    peakStartTime: {
        hour: 8
        minute: 0
    }
    peakLoadBalancingAlgorithm: 'DepthFirst'
    rampDownStartTime: {
        hour: 18
        minute: 0
    }
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 5
    rampDownCapacityThresholdPct: 90
    rampDownWaitTimeMinutes: 30
    rampDownStopHostsWhen: 'ZeroSessions'
    rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
    offPeakStartTime: {
        hour: 20
        minute: 0
    }
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
    rampDownForceLogoffUsers: true
  }
]


var logAnalyticsId = resourceId(platformSubId, shdSvcsRgName, 'Microsoft.OperationalInsights/workspaces', logWorkspaceName)
var subnetID = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${corpPlatformRgName}/providers/Microsoft.Network/virtualNetworks/${corpVirtualNetworkName}/subnets/${SubnetName}'
var healthDataCollectionRuleResourceId = '/subscriptions/${platformSubId}/resourceGroups/${shdSvcsRgName}/providers/Microsoft.Insights/dataCollectionRules/Microsoft-VMInsights-Health'
var azureUserProfileShare = '\\\\${avdProfileStorage}.file.core.windows.net\\profiles'
var imageReference = '/subscriptions/${resourceSubId}/resourceGroups/${imageGRgName}/providers/Microsoft.Compute/galleries/${imageGName}/images/${imageDefinitionName}'

resource rg_shdSvcs 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceRgName
  location:location
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  scope: resourceGroup(platformSubId,shdSvcsRgName)
  name: keyvaultName
}

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2021-09-03-preview' existing = {
  scope: resourceGroup(resourceRgName)
  name: hostPoolFriendlyName
}

module deployAVD '../virtual-desktops/avd.host.vm.bicep' = {
  scope: resourceGroup(resourceRgName)
  name: 'deploy_avd_hosts'
  params: {
    location: location
    AVDnumberOfInstances: number_Of_Instances
    avdRegToken: avdregtoken
    domainJoinPassword: keyVault.getSecret(domainJoinSecretName)
    domainJoinUser: domainJoinUserName
    domainToJoin: domainToJoin
    dscStorageAccount: dscStorageAccount
    dscStorageAccountContainer: dscStorageAccountContainer
    administratorAccountPassword: keyVault.getSecret(localAdminSecretName)
    administratorAccountUserName: localAdminUserName
    vmPrefix: VMprefix
    vmImageVerion:vmImageVerion
    vmSize: vmSize
    subnetID: subnetID
    ouPath: ouPath
    healthDataCollectionRuleResourceId: healthDataCollectionRuleResourceId
    logAnalyticsId: logAnalyticsId
    azureUserProfileShare:azureUserProfileShare
    pfxPassword:pfxPassword
    imageReference:{
      publisher: ''
      offer: ''
      sku: ''
      version: ''
      id:imageReference
    }
  }
}

module autoScaling '../virtual-desktops/avd.scaling.plan.bicep' = {
  scope: resourceGroup(resourceRgName)
  name:  'deploy_avd_autoscalling'
  params: {
    avdLocation: hostpool.location
    exclusionTag: ''
    hostPoolId: hostpool.id
    scalingPlanDescription: 'Scaling ${hostpool.name}'
    scalingPlanName: 'Scaling_${hostpool.name}'
    tags: {
    }
    timeZone: 'AUS Eastern Standard Time'
    schedules:schedules
  }
}
