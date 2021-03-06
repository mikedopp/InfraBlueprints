﻿function Get-ConfigurationDataAsObject
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable] $ConfigurationData    
    )
    return $ConfigurationData
}

#Replace this with the right configuration data path
$moduleBase = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$examplePath = "${moduleBase}\Examples\"
$baseName = ($MyInvocation.MyCommand.Name.Split('.'))[0]
$configurationDataPSD1 = "${examplePath}\Sample_${baseName}.NodeData.psd1"
#Replace till here

$configurationData = Get-ConfigurationDataAsObject -ConfigurationData $configurationDataPSD1
Describe 'Simple Operations tests for Hyper-V Deployment with Switch Embedded Teaming and related network Configuration' {
    Context 'Hyper-V module related tests' {
        It 'Hyper-V Module is available' {
            Get-Module -Name Hyper-V -ListAvailable | should not BeNullOrEmpty
        }

        It 'Hyper-V Module can be loaded' {
            Import-Module -Name Hyper-V -Global -PassThru -Force | should not BeNullOrEmpty
        }
    }

    Context 'Network Team tests' {
        $team = Get-NetLbfoTeam -Name $configurationData.AllNodes.TeamName -ErrorAction SilentlyContinue
        It 'Network team should exist' {
            $team | Should not BeNullOrEmpty
        }

        It 'Load balancing algorithm should match' {
            $team.LoadBalancingAlgorithm | Should be $configurationData.AllNodes.LoadBalancingAlgorithm
        }

        It 'Teaming mode should match' {
            $team.TeamingMode | Should Be $configurationData.AllNodes.TeamingMode
        }
    }

    Context 'Hyper-V Host networking tests' {
        $vmSwitch = Get-VMSwitch -Name $configurationData.AllNodes.SwitchName -ErrorAction SilentlyContinue
        It 'A VM Switch should exist' {            
            $vmSwitch | Should not BeNullOrEmpty
        }

        It 'VM Switch Type should be external' {
            $vmSwitch.SwitchType | Should Be 'External'
        }

        It 'Only one VM switch should exist' {
            $vmSwitch.Count | Should be 1
        }      

        It 'Bandwidth Reservation Mode should be Weight' {
            $vmSwitch.BandwidthReservationMode | Should be 'Weight'
        }

        It 'Management Network Adapter exists' {
            { Get-VMNetworkAdapter -ManagementOS -Name $configurationData.AllNodes.ManagementAdapterName } | Should Not Throw
        }

        It 'Cluster Network Adapter exists' {
            { Get-VMNetworkAdapter -ManagementOS -Name $configurationData.AllNodes.ClusterAdapterName } | Should Not Throw
        }

        It 'Live Migration Network Adapter exists' {
            { Get-VMNetworkAdapter -ManagementOS -Name $configurationData.AllNodes.LiveMigrationAdapterName } | Should Not Throw
        }
        
        It 'Management Bandwidth weight should match configuration' {
            (Get-VMNetworkAdapter -ManagementOS -Name $configurationData.AllNodes.ManagementAdapterName).BandwidthSetting.MinimumBandwidthWeight | Should Be $ConfigurationData.AllNodes.ManagementMinimumBandwidthWeight
        }

        It 'Cluster Bandwidth weight should match configuration' {
            (Get-VMNetworkAdapter -ManagementOS -Name $configurationData.AllNodes.ClusterAdapterName).BandwidthSetting.MinimumBandwidthWeight | Should Be $ConfigurationData.AllNodes.ClusterMinimumBandwidthWeight
        }

        It 'Live Migration Bandwidth weight should match configuration' {
            (Get-VMNetworkAdapter -ManagementOS -Name $configurationData.AllNodes.LiveMigrationAdapterName).BandwidthSetting.MinimumBandwidthWeight | Should Be $ConfigurationData.AllNodes.LiveMigrationMinimumBandwidthWeight
        }
    }

    Context 'General networking tests' {
        It 'DNS server should be reachable' {
            Test-Connection -ComputerName $configurationData.AllNodes.ManagementDns -Count 2 -Quiet | Should Be $true
        }

        It 'Default Gateway on the management network should be reachable' {
            Test-Connection -ComputerName $configurationData.AllNodes.ManagementGateway -Count 2 -Quiet | Should Be $true
        }
    }

    AfterAll {
        remove-Module Hyper-V
    }
}
