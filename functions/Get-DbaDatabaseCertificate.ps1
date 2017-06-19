﻿function Get-DbaDatabaseCertificate {
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

.PARAMETER ExcludeDatabase
Database(s) to ignore when retrieving certificates.

.PARAMETER Certificate
Get specific certificate.

.PARAMETER NoSystemCert
Excludes built in certificates that start with ##MS.

.PARAMETER Silent 
Use this switch to disable any kind of verbose messages.

.NOTES
Tags: Certificate
Website: https://dbatools.io
Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.EXAMPLE
Get-DbaDatabaseCertificate -SqlInstance sql2016

Gets all certificates

.EXAMPLE
Get-DbaDatabaseCertificate -SqlInstance Server1 -Database db1

Gets the certificate for the db1 database

.EXAMPLE
Get-DbaDatabaseCertificate -SqlInstance Server1 -Database db1 -Certificate cert1

Gets the cert1 certificate within the db1 database
	
.EXAMPLE
Get-DbaCertificate -SqlInstance Server1 -NoSystemCert

Gets all certificates except those that start with ##MS

#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory, ValueFromPipeline)]
		[Alias("ServerInstance", "SqlServer")]
		[DbaInstanceParameter[]]$SqlInstance,
		[System.Management.Automation.PSCredential]$SqlCredential,
<<<<<<< HEAD:functions/Get-DbaDatabaseCertificate.ps1
		[object[]]$Database,
		[object[]]$ExcludeDatabase,
		[object[]]$Certificate,
=======
		[string[]]$Database,
		[string[]]$Certificate,
		[switch]$NoSystemCert,
>>>>>>> 0945d256f7d90e89ceabfdc787d24e22226d1772:functions/Get-DbaCertificate.ps1
		[switch]$Silent
	)
	
	process {
		foreach ($instance in $SqlInstance) {
			try {
				Write-Message -Level Verbose -Message "Connecting to $instance"
				$server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $sqlcredential
			}
			catch {
				Stop-Function -Message "Failed to connect to: $instance" -Target $instance -InnerErrorRecord $_ -Continue
			}
			
			$databases = Get-DbaDatabase -SqlInstance $server
			if ($Database) { 
				$databases = $databases | Where-Object Name -In $Database
			}
			if ($ExcludeDatabase) {
				$databases = $databases | Where-Object Name -NotIn $ExcludeDatabase
			}
			
			foreach ($db in $databases) {
				if (!$db.IsAccessible) {
					Write-Message -Level Warning -Message "$db is not accessible, skipping"
					continue
				}
				$dbName = $db.Name
				$smodb = $server.Databases[$dbName]
				
				if ($null -eq $smodb) {
					Write-Message -Message "Database '$db' does not exist on $instance" -Target $smodb -Level Verbose
					continue
				}
				
				if (0 -eq $smodb.Certificates.count) {
					Write-Message -Message "No certificate exists in the $db database on $instance" -Target $smodb -Level Verbose
					continue
				}
				
				$certs = $smodb.Certificates
				if ($Certificate) {
<<<<<<< HEAD:functions/Get-DbaDatabaseCertificate.ps1
					$certs = $certs | Where-Object Name -in $Certificate
=======
					$certs = $smodb.Certificates | Where-Object Name -in $Certificate
				}
				elseif ($NoSystemCert) {
					$certs = $smodb.Certificates | Where-Object Name -notlike '##MS*'
				}
				else {
					$certs = $smodb.Certificates 
>>>>>>> 0945d256f7d90e89ceabfdc787d24e22226d1772:functions/Get-DbaCertificate.ps1
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
