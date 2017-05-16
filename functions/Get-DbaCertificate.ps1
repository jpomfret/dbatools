﻿Function Get-DbaCertificate {
<#
.SYNOPSIS
Gets database certificates.

.DESCRIPTION
Gets database certificates.

.PARAMETER SqlInstance
The target SQL Server instance.

.PARAMETER SqlCredential
Allows you to login to SQL Server using alternative credentials

.PARAMETER Database
Get certificate from specific database.

.PARAMETER Certificate
Get specific certificate.

.PARAMETER ExcludeMSCertificate
Excludes built in certificates that start with ##MS.

.PARAMETER Silent 
Use this switch to disable any kind of verbose messages.

.NOTES
Tags: Certificate
Website: https://dbatools.io
Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.EXAMPLE
Get-DbaCertificate -SqlInstance sql2016

Gets all certificates

.EXAMPLE
Get-DbaCertificate -SqlInstance Server1 -Database db1

Gets the certificate for the db1 database

.EXAMPLE
Get-DbaCertificate -SqlInstance Server1 -Database db1 -Certificate cert1

Gets the cert1 certificate within the db1 database
	
.EXAMPLE
Get-DbaCertificate -SqlInstance Server1 -ExcludeMSCertificate

Gets all certificates except those that start with ##MS

#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory, ValueFromPipeline)]
		[Alias("ServerInstance", "SqlServer")]
		[object[]]$SqlInstance,
		[System.Management.Automation.PSCredential]$SqlCredential,
		[string[]]$Database,
		[string[]]$Certificate,
		[switch]$ExcludeMSCertificate,
		[switch]$Silent
	)
	
	process {
		foreach ($instance in $SqlInstance) {
			try {
				Write-Message -Level Verbose -Message "Connecting to $instance"
				$server = Connect-SqlServer -SqlServer $instance -SqlCredential $sqlcredential
			}
			catch {
				Stop-Function -Message "Failed to connect to: $instance" -Target $instance -InnerErrorRecord $_ -Continue
			}
			
			if (!$Database) { $Database = $server.Databases.Name }
			
			foreach ($db in $database) {
				
				$smodb = $server.Databases[$db]
				
				if ($null -eq $smodb) {
					Write-Message -Message "Database '$db' does not exist on $instance" -Target $smodb -Level Verbose
					continue
				}
				
				if (0 -eq $smodb.Certificates.count) {
					Write-Message -Message "No certificate exists in the $db database on $instance" -Target $smodb -Level Verbose
					continue
				}
				
				if ($Certificate) {
					$certs = $smodb.Certificates | Where-Object Name -in $Certificate
				}
				elseif ($ExcludeMSCertificate) {
					$certs = $smodb.Certificates | Where-Object Name -notlike '##MS*'
				}
				else {
					$certs = $smodb.Certificates 
				}
				
				foreach ($cert in $certs) {
					
					Add-Member -InputObject $cert -MemberType NoteProperty -Name ComputerName -value $server.NetName
					Add-Member -InputObject $cert -MemberType NoteProperty -Name InstanceName -value $server.ServiceName
					Add-Member -InputObject $cert -MemberType NoteProperty -Name SqlInstance -value $server.DomainInstanceName
					Add-Member -InputObject $cert -MemberType NoteProperty -Name Database -value $smodb.Name
					
					Select-DefaultView -InputObject $cert -Property ComputerName, InstanceName, SqlInstance, Database, Name, Subject, StartDate, ActiveForServiceBrokerDialog, ExpirationDate, Issuer, LastBackupDate, Owner, PrivateKeyEncryptionType, Serial
				}
			}
		}
	}
}