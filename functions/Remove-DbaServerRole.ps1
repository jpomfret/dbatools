function Remove-DbaServerRole {
    <#
    .SYNOPSIS
        Deletes specified database certificate

    .DESCRIPTION
        Deletes specified database certificate

    .PARAMETER SqlInstance
        The SQL Server to create the certificates on.

    .PARAMETER SqlCredential
        Allows you to login to SQL Server using alternative credentials.

    .PARAMETER ServerRole
        The server-role that will be removed

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .PARAMETER InputObject
        Piped server-role objects

    .NOTES
        Tags: ServerRole, Instance, Security
        Author: Claudio Silva (@ClaudioESSilva), https://claudioessilva.com
        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Remove-DbaServerRole -SqlInstance Server1 -ServerRole 'serverExecuter'

        Server-role 'serverExecuter' on Server1 will be removed if it exists.

    .EXAMPLE
        PS C:\> Remove-DbaServerRole -SqlInstance Server1 -Database db1 -Confirm:$false

        Suppresses all prompts to remove the server-role in the 'Server1'.

    #>
    [CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string[]]$ServerRole,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.ServerRole[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if ($SqlInstance) {
            $InputObject += Get-DbaServerRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -ServerRole $ServerRole
        }

        foreach ($srvrole in $InputObject) {
            if ($Pscmdlet.ShouldProcess($srvrole.DomainInstanceName, "Dropping the server-role named $($srvrole.Role) on $($srvrole.DomainInstanceName)")) {
                try {
                    $srvrole.Drop()

                    [pscustomobject]@{
                        ComputerName = $srvrole.ComputerName
                        InstanceName = $srvrole.InstanceName
                        SqlInstance  = $srvrole.SqlInstance
                        ServerRole   = $srvrole.Role
                        Status       = "Success"
                    }
                } catch {
                    Stop-Function -Message "Failed to drop server-role named $($srvrole.Name) on $($srvrole.Name)." -Target $srvrole -ErrorRecord $_ -Continue

                    [pscustomobject]@{
                        ComputerName = $srvrole.ComputerName
                        InstanceName = $srvrole.InstanceName
                        SqlInstance  = $srvrole.SqlInstance
                        ServerRole   = $srvrole.Role
                        Status       = "Failed"
                    }
                }
            }
        }
    }
}