function New-DbaDbFileGroup {
    <#
    .SYNOPSIS
        Returns a summary of information on filegroups

    .DESCRIPTION
        Shows information around filegroups.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. This can be a collection and receive pipeline input.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Database
        The database(s) to process - this list is auto-populated from the server. If unspecified, all databases will be processed.

   .PARAMETER InputObject
        Database object piped in from Get-DbaDatabase

    .PARAMETER FileGroup
        Define a specific FileGroup  you would like to query.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Database, FileGroup
        Author: Patrick Flynn (@sqllensman)

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Get-DbaDbFileGroup

    .EXAMPLE
        PS C:\> Get-DbaDbFileGroup -SqlInstance sql2016

        Return all FileGroups for all databases on instance sql2016

    .EXAMPLE
        PS C:\> Get-DbaDbFileGroup -SqlInstance sql2016 -Database MyDB

        Return all FileGroups for database MyDB on instance sql2016

    .EXAMPLE
        PS C:\> Get-DbaDbFileGroup -SqlInstance sql2016 -FileGroup Primary

        Returns information on filegroup called Primary if it exists in any database on the server sql2016

    .EXAMPLE
        PS C:\> 'localhost','localhost\namedinstance' | Get-DbaDbFileGroup

        Returns information on all FileGroups for all databases on instances 'localhost','localhost\namedinstance'

    .EXAMPLE
        PS C:\> 'localhost','localhost\namedinstance' | Get-DbaDbFileGroup

        Returns information on all FileGroups for all databases on instances 'localhost','localhost\namedinstance'

    .EXAMPLE
        PS C:\> Get-DbaDatabase -SqlInstance SQL1\SQLExpress,SQL2 -ExcludeDatabase model,master | Get-DbaDbFileGroup

        Returns information on all FileGroups for all databases except model and master on instances SQL1\SQLExpress,SQL2
    #>
    [CmdletBinding()]
    param ([parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [string[]]$Name,
        [switch]$EnableException
    )

    process {
        if (Test-Bound -not 'SqlInstance', 'InputObject') {
            Write-Message -Level Warning -Message "You must specify either a SQL instance or supply an InputObject"
            return
        }

        if (Test-Bound -Not -ParameterName InputObject) {
            # should Get-DbaDatabase accept a Database object? currently only a name
            $InputObject += Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        }

        foreach ($db in $InputObject) {
            if ($db.IsAccessible) {
                Write-Message -Level Verbose -Message "Processing database: $db"
                $server = $db.Parent

                # why would we need this??
                if (Test-Bound -ParameterName Database) {
                    $db = $db | Where-Object { $Database -contains $_.Name }
                }

                if ($db.FileGroups | Where-Object { $_.Name -contains $Name }) {
                    Write-Message -Level Warning -Message "FileGroup $Name already exists in $Database"
                    return
                }
                try {
                    Write-Message -Message "Creating $Name filegroup for $Database" -Level Verbose
                    $fg = New-Object -TypeName Microsoft.SqlServer.Management.Smo.FileGroup -ArgumentList $db, $Name
                    $fg.Create()
                } catch {
                    Stop-Function -Message "Issue creating filegroup $Name for $Database" -Target $Database -ErrorRecord $_ -Continue
                }

                Get-DbaDbFileGroup -SqlInstance $server -Database $Database -FileGroup $Name
            } else {
                Write-Message -Level Verbose -Message "Skipping processing of database: $db as database is not accessible"
            }
        }
    }
}