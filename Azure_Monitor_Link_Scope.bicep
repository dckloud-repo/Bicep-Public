@description('Resource Group Name')
param rgName string

@description('Resource Group Name')
param location string =  resourceGroup().location

@description('appliction shortname. Used for resource naming.')
param lzShortName string 

@description('Customer shortname. Used for resource naming.')
param custShortName string

@description('Shortname of evironment. Used for resource naming.')
param envShortName string

@description('Type of the Private Endpoint')
param type string = 'azuremonitor'

@description('Subnet ID of the Private Endpoint Connection')
param subnetId string

@description('Ingetion Mode for the Link Scope')
param ingestionAccessMode string = 'Open'

@description('Query Mode for the Link Scope')
param queryAccessMode string = 'Open'

@description('Linked ResourceDetailes')
param linkedResources array

param principalIds array = [
  'd81fadde-2449-455f-92d2-3d7e3c952862'
]

param roleDefinitionIdOrName string = 'Reader'

var linkScopeName = 'links-${lzShortName}-${envShortName}-${custShortName}'
var resourceName = 'azure-monitor'
var builtInRoleNames = {
  'Owner': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  'Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Log Analytics Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
  'Log Analytics Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '73c42c96-874c-492b-b04d-ab87d138a893')
  'Managed Application Contributor Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '641177b8-a67a-45b9-a033-47bc880bb21e')
  'Managed Application Operator Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c7393b34-138c-406f-901b-d8cf2b17e6ae')
  'Managed Applications Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b9331d33-8a36-4f8c-b097-4f54124fdb44')
  'Monitoring Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa')
  'Monitoring Metrics Publisher': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
  'Monitoring Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  'Resource Policy Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '36243c78-bf99-498c-9df9-86d9f8d28608')
  'User Access Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${resourceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-${type}-plink'
        properties: {
          privateLinkServiceId: privateLinkScope.id
          groupIds: [
            type
          ]
        }
      }
    ]
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-monitor-azure-com'
        properties: {
          privateDnsZoneId: resourceId(subscription().subscriptionId,resourceGroup().name,'Microsoft.Network/privateDnsZones','privatelink.monitor.azure.com')
        }
      }
      {
        name: 'privatelink-oms-opinsights-azure-com'
        properties: {
          privateDnsZoneId: resourceId(subscription().subscriptionId,resourceGroup().name,'Microsoft.Network/privateDnsZones','privatelink.oms.opinsights.azure.com')
        }
      }
      {
        name: 'privatelink-ods-opinsights-azure-com'
        properties: {
          privateDnsZoneId: resourceId(subscription().subscriptionId,resourceGroup().name,'Microsoft.Network/privateDnsZones','privatelink.ods.opinsights.azure.com')
        }
      }
      {
        name: 'privatelink-agentsvc-azure-automation-net'
        properties: {
          privateDnsZoneId: resourceId(subscription().subscriptionId,resourceGroup().name,'Microsoft.Network/privateDnsZones','privatelink.agentsvc.azure-automation.net')
        }
      }
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: resourceId(subscription().subscriptionId,resourceGroup().name,'Microsoft.Network/privateDnsZones','privatelink.blob.core.windows.net')
        }
      }
    ]
  }
}

resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: linkScopeName
  location: 'global'
  properties: {
    accessModeSettings: {
      exclusions: [ 
      ]
      ingestionAccessMode: ingestionAccessMode
      queryAccessMode: queryAccessMode
    }
  }
}


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for principalId in principalIds: {
  name: guid(privateLinkScope.name, principalId, roleDefinitionIdOrName)
  properties: {
    roleDefinitionId: contains(builtInRoleNames, roleDefinitionIdOrName) ? builtInRoleNames[roleDefinitionIdOrName] : roleDefinitionIdOrName
    principalId: principalId
  }
  scope: privateLinkScope
}]

resource linkResources 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = [for linkedResource in linkedResources:{
  name: 'scoped-${linkedResource.name}'
  parent: privateLinkScope
  properties: {
    linkedResourceId: linkedResource.id
  }
  dependsOn: [
    privateDNSZoneGroup
  ]
}]



output linkScopeName string = linkScopeName
