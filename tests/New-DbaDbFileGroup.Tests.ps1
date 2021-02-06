$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [array]$params = ([Management.Automation.CommandMetaData]$ExecutionContext.SessionState.InvokeCommand.GetCommand($CommandName, 'Function')).Parameters.Keys
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'InputObject', 'Name', 'EnableException'
        It "Should only contain our specific parameters" {
            Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params | Should -BeNullOrEmpty
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {

    BeforeAll {
        $newDbName = "dbatoolsci_db_$(Get-Random)"
        $newDb = New-DbaDatabase -SqlInstance mssql1 -Name $newDbName
        $newFgName = "dbatoolsci_fg_$(Get-Random)"
        $newFg = New-DbaDbFileGroup -SqlInstance mssql1 -Database $newDbName -Name $newFgName
    }

    AfterAll {
        $null = Remove-DbaDatabase -SqlInstance mssql1 -Database $newDb -Confirm:$false
    }

    Context "commands work as expected" {
        $fg = Get-DbaDbFileGroup -SqlInstance mssql1 -Database $newDbName -FileGroup $newFgName
        It "should create filegroup" {
            $fg | Should -Not -BeNullOrEmpty
        }

        It "should create filegroup with the correct name" {
            $fg.Name | Should -Be $newFgName
        }
    }

    Context "commands work as expected with piping" {
        $pipedFgName = 'PipedFg'
        $newDb | New-DbaDbFileGroup -Name $pipedFgName
        $pipedFg = Get-DbaDbFileGroup -SqlInstance mssql1 -Database $newDbName -FileGroup $pipedFgName
        It "should create filegroup" {
            $pipedFg | Should -Not -BeNullOrEmpty
        }

        It "should create filegroup with the correct name" {
            $pipedFg.Name | Should -Be $pipedFgName
        }
    }
}