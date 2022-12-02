
@description('AVD Scaling Plan Name')
param scalingPlanName string

@description('AVD Scaling Plan Name')
param scalingPlanFriendlyName string

@description('Location of the hostpool')
param location string

@description('Application Group Type')
param hostPoolID string 

@description('Time Zone For the schedules ')
param timeZone string 

@description('Application Group Type')
param schedules array 

@description('Array of actions for the roleDefinition')
param actions array = [
  'Microsoft.Insights/eventtypes/values/read'
  'Microsoft.Compute/virtualMachines/deallocate/action'
  'Microsoft.Compute/virtualMachines/restart/action'
  'Microsoft.Compute/virtualMachines/powerOff/action'
  'Microsoft.Compute/virtualMachines/start/action'
  'Microsoft.Compute/virtualMachines/read'
  'Microsoft.DesktopVirtualization/hostpools/read'
  'Microsoft.DesktopVirtualization/hostpools/write'
  'Microsoft.DesktopVirtualization/hostpools/sessionhosts/read'
  'Microsoft.DesktopVirtualization/hostpools/sessionhosts/write'
  'Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete'
  'Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read'
  'Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action'
]

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string = 'Azure Virtual Desktop Autoscale'

@description('Friendly name of the role definition')
param roleAssignmentName string = 'AzureVirtualDesktopAutoscale'

@description('Detailed description of the role definition')
param roleDescription string = 'Scales your Azure Virtual Desktop deployment up or down'


resource auto_scaling 'Microsoft.DesktopVirtualization/scalingPlans@2022-02-10-preview' = {
  name: scalingPlanName
  location: location
  properties: {
    description: scalingPlanFriendlyName
    friendlyName: scalingPlanFriendlyName
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPoolID
        scalingPlanEnabled: true
      }
    ]
    hostPoolType: 'Pooled'
    schedules:schedules
    timeZone: timeZone
  }
}

var roleDefName = guid(subscription().id, string(actions), string(notActions))

resource roleDef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

resource role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleAssignmentName)
  properties: {
    principalId: '9cdead84-a844-4324-93f2-b2e6bb768d07'
    roleDefinitionId: roleDef.id
  }
}
