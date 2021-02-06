function New-DbaDbFile {
    <#
    .SYNOPSIS
        Adds a new filegroup to the specified database.

    .DESCRIPTION
        Adds a new filegroup to the specified database, that can be used to group data files together.

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

    .PARAMETER Name
        The name of the filegroup to create.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Database, FileGroup
        Author: Jess Pomfret (@jpomfret)

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/New-DbaDbFileGroup

    .EXAMPLE
        PS C:\> NNew-DbaDbFileGroup -SqlInstance sql2019 -Database AdventureWorks2019 -Name fg2

        Creates a new filegroup named 'fg2' for the 'AdventureWorks2019' database on sql2019.

    .EXAMPLE
        PS C:\> Get-DbaDatabase -SqlInstance sql2019 -Database AdventureWorks2019 | New-DbaDbFileGroup -Name fg3

        Creates a new filegroup by piping in a database object.
    #>
    [CmdletBinding()]
    param ([parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String[]]$Database,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [string[]]$FileGroup,
        [string[]]$Name,
        [switch]$EnableException
    )

    process {
        if (Test-Bound -not 'SqlInstance', 'InputObject') {
            Write-Message -Level Warning -Message "You must specify either a SQL instance or supply an InputObject"
            return
        }

        if (Test-Bound -Not -ParameterName InputObject) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        }

        if (Test-Bound -Not -ParameterName FileGroup) {
            Write-Message -Message "No FileGroup specified, defaulting to Primary for $db" -Level Verbose
            $FileGroup = 'Primary'
        }

        foreach ($db in $InputObject) {
            if ($db.IsAccessible) {
                Write-Message -Level Verbose -Message "Processing database: $db"
                $server = $db.Parent

                #if ($db.FileGroups | Where-Object { $_.Name -contains $Name }) {
                #    Write-Message -Level Warning -Message "FileGroup $Name already exists in $db"
                #    return
                #}
                #try {
                #    Write-Message -Message "Creating $Name filegroup for $db" -Level Verbose
                #    $fg = New-Object -TypeName Microsoft.SqlServer.Management.Smo.FileGroup -ArgumentList $db, $Name
                #    $fg.Create()
                #} catch {
                #    Stop-Function -Message "Issue creating filegroup $Name for $db" -Target $Database -ErrorRecord $_ -Continue
                #}

                Get-DbaDbFile -SqlInstance $server -Database $db.Name # $FileGroup
            } else {
                Write-Message -Level Verbose -Message "Skipping processing of database: $db as database is not accessible"
            }
        }
    }
}