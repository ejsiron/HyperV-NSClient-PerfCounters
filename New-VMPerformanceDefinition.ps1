<#
.SYNOPSIS
	Creates Nagios monitoring configurations for Hyper-V virtual machines.
.DESCRIPTION
	Scans one or more virtual machines and generates Nagios sensors for performance checks.
	Each check is expressed as a "service". A suitable "check-hypervmperf" command must already exist.
.PARAMETER VM
	One or more virtual machines. Each input item will be scanned and included in the output file.
	Accepts multiple input types:
	* Microsoft.HyperV.PowerShell.VirtualMachine: This object type is output by the native Get-VM cmdlet. ComputerName is ignored with this type.
	* System.String: Assumed to be the name of the target virtual machine. Used in conjunction with ComputerName.
	* Microsoft.Management.Infrastructure.CimInstance: This type is output by Get-CimInstance. Must have a CreationClassName of Msvm_ComputerSystem. ComputerName is ignored with this type.
	* System.Management.ManagementObject: This type is output by Get-WmiObject. Expected to be of type Msvm_ComputerSystem; must have a Name property that contains the VMId of a virtual machine on the objects __SERVER property to be effective. ComputerName is ignored with this type.
	* Nothing: If not specified, will scan ComputerName for virtual machines.
.PARAMETER ComputerName
	The target computer system to scan for virtual machines.
	Ignored if VM is anything other than a string (including an empty string or an array of strings).
	If a cluster name or IP is specified, only the current owner of the core cluster resource will be scanned.
	If not specified, the local system is used.
.PARAMETER Path
	The path to an output file. It will be created if it does not exist. By default, it will be overwritten. Use Append to override.
.PARAMETER Version
	Choices: 2012R2 or 2016. Default: 2012R2
	If specified, assumes that the virtual machine(s) are all of the indicated version.
	If not specified, the host will be queried.
.PARAMETER LineEndFormat
	Specifies the system codes to use to indicate an end-of-line in the output file. Default is "Linux".
	* Linux: Uses only a newline character (\n)
	* Windows: Uses a carriage-return/newline character combination (\r\n)
	* Macintosh: Uses only a carriage-return character (\r)
.PARAMETER ServiceTemplate
	Text to include on each service's "use" line. Defaults to "generic-service".
.PARAMETER ServiceGroups
	Text to include on each service's "servicegroups" line. If left empty, no "servicegroups" line will be generated.
.PARAMETER ServiceContacts
	Text to use as a service's "contacts" line. If left empty, the "contacts" line is not generated.
.PARAMETER ServiceContactGroups
	Text to use as a service's "contact_groups" line. If left empty, the "contact_groups" line is not generated.
.PARAMETER Append
	Appends the generated output to Path instead of overwriting.
.PARAMETER ResolveHost
	Determines the IP address of the Hyper-V host or cluster and uses that as the service target instead of the host name.
.PARAMETER VMAsHost
	Default behavior will assign the Hyper-V host or cluster as the service's "host_name". If VMAsHost is specified, uses the VM's name instead.
.PARAMETER UpperCaseHostName
	Nagios' host_names are case sensitive. The techniques used in this script will alwoys generate lower-case names. Specify UpperCaseHostNames to force them to uppercase.
.PARAMETER SkipCPU
	If specified, does not include any virtual CPU sensors.
.PARAMETER SkipDynamicMemory
	If specified, does not include any dynamic memory sensors. Unnecessary for fixed memory virtual machines.
.PARAMETER SkipDisk
	If specified, does not generate any virtual hard disk sensors. Unnecessary for diskless virtual machines. Operates independently of SkipIDE.
.PARAMETER SkipNetwork
	If specified, does not generate any virtual network sensors.
.PARAMETER IncludeAdvancedCounters
	If specified, includes several uncommon and advanced counters in each category.
.PARAMETER IncludeIDE
	If specified, includes emulated IDE sensors. Generally reads 0. Not useful for Generation 2 virtual machines. Operates independently of SkipDisk.
.PARAMETER IncludeLiveMigration
	If specified, includes LiveMigration-related counters. Unnecessary for non-clustered virtual machines.
.PARAMETER IncludeSavesSnaps
	If specified, includes counters related to Save and Snapshot/Checkpoint operations.
.PARAMETER IncludeSmartPaging
	If specified, includes counters related to Smart Paging operations.
.PARAMETER IncludeNUMA
	If specified, includes counters related to NUMA.
.PARAMETER IncludeNetworkDropReasons
	If specified, includes counters for network drop reasons. Ignored if host is not 2016.
.PARAMETER IncludeVmWorkerProcess
	If specified, includes counters for VM worker processors. Ignored if host is not 2016.
.PARAMETER IncludeVRSS
	If specified, includes vRSS counters for all virtual network adapters on 2016 VMs.
.PARAMETER CreateVMHostDefinition
	If specified, generates a host{} definition for each virtual machine. Ignored if VMAsHost is not also set.
	The generated host definition will include the following lines unless you specify a VMHostTemplate:

	max_check_attempts    1
	check_command         null
	notifications_enabled 0
.PARAMETER VMHostTemplate
	Text to use as a host's "use" line. Defaults to "generic-host". Ignored if CreateVMHostDefinition and VMAsHost are not also set.
.PARAMETER UseSkeletonHost
	If specified, will force the inclusion of the default items indicated in the description of CreateVMHostDefinition, even when VMHostTemplate is set.
	Ignored if CreateVMHostDefinition and VMAsHost are not also set.
.PARAMETER VMHostGroups
	Text to use as a host's "hostgroups" line. If left empty, the "hostgroups" line is not generated. Ignored if CreateVMHostDefinition and VMAsHost are not also set.
.PARAMETER VMHostContacts
	Text to use as a host's "contacts" line. If left empty, the "contacts" line is not generated. Ignored if CreateVMHostDefinition and VMAsHost are not also set.
.PARAMETER VMHostContactGroups
	Text to use as a host's "contact_groups" line. If left empty, the "contact_groups" line is not generated. Ignored if CreateVMHostDefinition and VMAsHost are not also set.
.INPUTS
	System.String[]
	Microsoft.HyperV.PowerShell.VirtualMachine[]
	Microsoft.Management.Infrastructure.CimInstance[]
	System.Management.ManagementObject[]
.OUTPUTS
	None
.NOTES
	New-VMPerformanceDefinition.ps1
	Version 1.1, November 5, 2018
	Author: Eric Siron
.EXAMPLE
	New-VMPerformanceDefinition.ps1 -ComputerName -Path C:\Source\svhv01.cfg -ServiceTemplate 'hyperv-vm-performance'

	Creates a basic sensor set from all virtual machines on the host named svhv01 using the defined service template.
.EXAMPLE
	Get-CimInstance -ComputerName svhv01 -ClassName msvm_computersystem -Namespace root/virtualization/v2 -Filter 'ElementName="dtmanage"' | New-VMPerformanceDefinition.ps1 -Path C:\Source\dtmanage.cfg -ServiceTemplate 'hyperv-vm-performance' -VMAsHost -IncludeAdvancedCounters -IncludeLiveMigration -IncludeSavesSnaps -IncludeSmartPaging -IncludeNUMA -IncludeNetworkDropReasons -IncludeVmWorkerProcess -IncludeVRSS -IncludeRemotingChecks -CreateVMHostDefinition

	Retrieves the CIM definition from a host named "svhv01" for the virtual machine named "dtmanage" and creates a .cfg file with all possible counters.
#>
#requires -Version 4

[CmdletBinding()]
param(
	[Parameter(Position = 1, ValueFromPipeline = $true)][System.Object[]]$VM,
	[Parameter()][String]$ComputerName = $env:COMPUTERNAME,
	[Parameter(Position = 2, Mandatory = $true)][String]$Path,
	[Parameter()][ValidateSet('2012R2', '2016')][String]$Version,
	[Parameter()][ValidateSet('Linux', 'Windows', 'Macintosh')][String]$LineEndFormat = 'Linux',
	[Parameter()][String]$ServiceTemplate = 'generic-service',
	[Parameter()][String]$ServiceGroups = [System.String]::Empty,
	[Parameter()][String]$ServiceContacts = [System.String]::Empty,
	[Parameter()][String]$ServiceContactGroups = [System.String]::Empty,
	[Parameter()][Switch]$Append,
	[Parameter()][Switch]$ResolveHost,
	[Parameter()][Switch]$VMAsHost,
	[Parameter()][Switch]$UpperCaseHostName,
	[Parameter()][Switch]$SkipCPU,
	[Parameter()][Switch]$SkipDynamicMemory,
	[Parameter()][Switch]$SkipDisk,
	[Parameter()][Switch]$SkipNetwork,
	[Parameter()][Switch]$IncludeAdvancedCounters,
	[Parameter()][Switch]$IncludeIDE,
	[Parameter()][Switch]$IncludeLiveMigration,
	[Parameter()][Switch]$IncludeSavesSnaps,
	[Parameter()][Switch]$IncludeSmartPaging,
	[Parameter()][Switch]$IncludeNUMA,
	[Parameter()][Switch]$IncludeNetworkDropReasons,
	[Parameter()][Switch]$IncludeVmWorkerProcess,
	[Parameter()][Switch]$IncludeVRSS,
	[Parameter()][Switch]$IncludeRemotingChecks,
	[Parameter()][Switch]$CreateVMHostDefinition,
	[Parameter()][String]$VMHostTemplate = 'generic-host',
	[Parameter()][Switch]$UseSkeletonHost,
	[Parameter()][String]$VMHostGroups = [System.String]::Empty,
	[Parameter()][String]$VMHostContacts = [System.String]::Empty,
	[Parameter()][String]$VMHostContactGroups = [System.String]::Empty
)

begin
{
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	$GUIDPattern = '[0-9a-fA-F]{8}.?[0-9a-fA-F]{4}.?[0-9a-fA-F]{4}.?[0-9a-fA-F]{4}.?[0-9a-fA-F]{12}'
	$CounterList = New-Object -TypeName System.Collections.ArrayList
	$VMList = New-Object -TypeName System.Collections.ArrayList
	$LineEnding = [String]::Empty

	if (-not (Test-Path -Path $Path))
	{
		$OutNull = New-Item -Path $Path -ItemType File
	}

	if (-not $Append)
	{
		Clear-Content -Path $Path
	}

	function New-ServiceObject
	{
		param(
			[Parameter()][String]$HostName,
			[Parameter()][String]$VMName,
			[Parameter()][String]$CounterCategory,
			[Parameter()][String]$Counter,
			[Parameter()][bool]$Clustered
		)
		$ServiceItem = New-Object -TypeName psobject
		Add-Member -InputObject $ServiceItem -MemberType NoteProperty -Name 'HostName' -Value $HostName
		Add-Member -InputObject $ServiceItem -MemberType NoteProperty -Name 'VMName' -Value $VMName
		Add-Member -InputObject $ServiceItem -MemberType NoteProperty -Name 'CounterName' -Value ([String]::Join(' ', $CounterCategory, ($Counter.Substring($Counter.LastIndexOf('\') + 1).Replace('%', 'Pct') -replace '([\(\)])', '')))
		Add-Member -InputObject $ServiceItem -MemberType NoteProperty -Name 'Counter' -Value $Counter
		Add-Member -InputObject $ServiceItem -MemberType NoteProperty -Name 'Clustered' -Value $Clustered
		$ServiceItem
	}

	function New-ServiceDefinition
	{
		param(
			[Parameter()][Object]$ServiceObject,
			[Parameter()][String]$LineEnding,
			[Parameter()][String]$ServiceTemplate,
			[Parameter()][String]$ServiceGroups,
			[Parameter()][String]$ServiceContacts,
			[Parameter()][String]$ServiceContactGroups,
			[Parameter()][bool]$VMAsHost
		)

		$ExtraCommands = ''
		if ($ServiceObject.Clustered)
		{
			$ExtraCommands = '-l'
		}

		$ServiceText = New-Object System.Text.StringBuilder
		$OutNull = $ServiceText.AppendFormat('define service{{{0}', $LineEnding)
		$OutNull = $ServiceText.AppendFormat('   use                 {0}{1}', $ServiceTemplate, $LineEnding)
		if ($VMAsHost)
		{
			$OutNull = $ServiceText.AppendFormat('   service_description {0}{1}', $ServiceObject.CounterName, $LineEnding)
			$TargetHost = $ServiceObject.VMName
		}
		else
		{
			$OutNull = $ServiceText.AppendFormat('   service_description {0} {1}{2}', $ServiceObject.VMName, $ServiceObject.CounterName, $LineEnding)
			$TargetHost = $ServiceObject.HostName
		}
		$OutNull = $ServiceText.AppendFormat('   host_name           {0}{1}', $TargetHost, $LineEnding)
		if ($ServiceGroups)
		{
			$OutNull = $ServiceText.AppendFormat('   servicegroups       {0}{1}', $ServiceGroups, $LineEnding)
		}
		if ($ServiceContacts)
		{
			$OutNull = $ServiceText.AppendFormat('   contacts            {0}{1}', $ServiceContacts, $LineEnding)
		}
		if ($ServiceContactGroups)
		{
			$OutNull = $ServiceText.AppendFormat('   contact_groups      {0}{1}', $ServiceContactGroups, $LineEnding)
		}
		$OutNull = $ServiceText.AppendFormat('   check_command       check-hypervmperf!{0}!{1}!"{2}"!{3}{4}', $ServiceObject.HostName, $ServiceObject.VMName, $ServiceObject.Counter, $ExtraCommands, $LineEnding)
		$OutNull = $ServiceText.AppendFormat('}}{0}', $LineEnding)
		$ServiceText.ToString()
	}

	function New-HostDefinition
	{
		param(
			[Parameter()][String]$ComputerName,
			[Parameter()][String]$HostTemplate,
			[Parameter()][String]$VMHostGroups,
			[Parameter()][String]$VMHostContacts,
			[Parameter()][String]$VMHostContactGroups,
			[Parameter()][bool]$UseSkeletonHost,
			[Parameter()][String]$LineEnding
		)

		$HostText = New-Object System.Text.StringBuilder
		$OutNull = $HostText.AppendFormat('define host{{{0}', $LineEnding)
		$OutNull = $HostText.AppendFormat('   host_name             {0}{1}', $ComputerName, $LineEnding)
		$OutNull = $HostText.AppendFormat('   use                   {0}{1}', $HostTemplate, $LineEnding)
		if (($HostTemplate -eq 'generic-host') -or $UseSkeletonHost)
		{
			$OutNull = $HostText.AppendFormat('   max_check_attempts    1{0}', $LineEnding)
			$OutNull = $HostText.AppendFormat('   check_command         null{0}', $LineEnding)
			$OutNull = $HostText.AppendFormat('   notifications_enabled 0{0}', $LineEnding)
		}
		if ($VMHostGroups)
		{
			$OutNull = $HostText.AppendFormat('   hostgroups            {0}{1}', $VMHostGroups, $LineEnding)
		}
		if ($VMHostContacts)
		{
			$OutNull = $HostText.AppendFormat('   contacts              {0}{1}', $VMHostContacts, $LineEnding)
		}
		if ($VMHostContactGroups)
		{
			$OutNull = $HostText.AppendFormat('   contact_groups        {0}{1}', $VMHostContactGroups, $LineEnding)
		}
		$OutNull = $HostText.AppendFormat('}}{0}', $LineEnding)
		$HostText.ToString()
	}

	$AdvancedChecks = @(
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Skipped Timer Ticks',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Device Interrupt Throttle Events',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Device DMA Errors',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Device Interrupt Errors',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\I/O TLB Flush Cost',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\I/O TLB Flushes/sec',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Device Interrupt Mappings',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Attached Devices',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\1G device pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\2M device pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\4K device pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\1G GPA pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\2M GPA pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\4K GPA pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Recommended Virtual TLB Size',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Virtual TLB Flush Entires/sec',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\GPA Space Modifications/sec',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\GPA Pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Deposited Pages',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Address Spaces',
		'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Virtual TLB Pages'
		#'\\Hyper-V Hypervisor Partition({0}:HvPt)\\Virtual Processors'
	)

	$AdvancedChecks2016 = @(
		'\\Hyper-V Hypervisor Partition(dtmanage:HvPt)\\Nested TLB Trimmed Pages/sec',
		'\\Hyper-V Hypervisor Partition(dtmanage:HvPt)\\Nested TLB Free List Size',
		'\\Hyper-V Hypervisor Partition(dtmanage:HvPt)\\Recommended Nested TLB Size',
		'\\Hyper-V Hypervisor Partition(dtmanage:HvPt)\\Nested TLB Size'
	)

	$CPUCoreChecks = @(
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\% Guest Run Time'
	)

	$CPUAdvancedChecks = @(
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\% Remote Run Time',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Total Intercepts Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Total Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Total Messages/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\% Hypervisor Run Time',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\% Total Run Time',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\CPU Wait Time Per Dispatch',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Logical Processor Dispatches/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested Page Fault Intercepts Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested Page Fault Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Hardware Interrupts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Virtual Processor Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Virtual MMU Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Virtual Interrupt Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Synthetic Interrupt Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Long Spin Wait Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Logical Processor Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\GPA Space Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\APIC Self IPIs Sent/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\APIC IPIs Sent/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Virtual Interrupts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Synthetic Interrupts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Table Write Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\APIC TPR Accesses/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Table Validations/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Table Resets/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Table Reclamations/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Table Evictions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Local Flushed GVA Ranges/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Global GVA Range Flushes/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Address Space Flushes/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Address Domain Flushes/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Address Space Switches/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Address Space Evictions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Logical Processor Migrations/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Table Allocations/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Messages/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\APIC EOI Accesses/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Memory Intercept Messages/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\IO Intercept Messages/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\APIC MMIO Accesses/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Reflected Guest Page Faults/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Small Page TLB Fills/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Large Page TLB Fills/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Guest Page Table Maps/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Fault Intercepts Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Fault Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Debug Register Accesses Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Debug Register Accesses/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Emulated Instructions Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Emulated Instructions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Pending Interrupts Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Pending Interrupts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\External Interrupts Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\External Interrupts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Intercepts Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MSR Accesses Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MSR Accesses/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\CPUID Instructions Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\CPUID Instructions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MWAIT Instructions Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MWAIT Instructions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\HLT Instructions Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\HLT Instructions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\IO Instructions Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\IO Instructions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Control Register Accesses Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Control Register Accesses/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Invalidations Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Invalidations/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Hypercalls Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Hypercalls/sec'
	)

	$CPUAdvanced2016Checks = @(
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Total Virtualization Instructions Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Total Virtualization Instructions Emulated/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Flush Physical Address List Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Flush Physical Address Space Hypercalls/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested TLB Page Table Evictions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested TLB Page Table Reclamations/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvVpid Single Address Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvVpid Single Address Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvVpid Single Context Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvVpid Single Context Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvVpid All Context Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvVpid All Context Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvEpt Single Context Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvEpt Single Context Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvEpt All Context Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\InvEpt All Context Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested SLAT Hard Page Faults Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested SLAT Hard Page Faults/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested SLAT Soft Page Faults Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested SLAT Soft Page Faults/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested VM Entries Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Nested VM Entries/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMXON Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMXON Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMXOFF Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMXOFF Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMWRITE Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMWRITE Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMREAD Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMREAD Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMPTRST Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMPTRST Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMPTRLD Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMPTRLD Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMCLEAR Instruction Emulation Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\VMCLEAR Emulation Intercepts/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Fault Intercepts Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Fault Intercepts Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Debug Register Accesses Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Debug Register Accesses Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Emulated Instructions Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Emulated Instructions Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Pending Interrupts Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Pending Interrupts Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\External Interrupts Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Intercepts Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Intercepts Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MSR Accesses Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MSR Accesses Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\CPUID Instructions Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\CPUID Instructions Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MWAIT Instructions Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MWAIT Instructions Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\HLT Instructions Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\HLT Instructions Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\IO Instructions Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\IO Instructions Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Control Register Accesses Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Control Register Accesses Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Invalidations Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Page Invalidations Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Hypercalls Forwarding Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Hypercalls Forwarded/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Local I/O TLB Flush Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Local I/O TLB Flushes/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Global I/O TLB Flush Cost',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Global I/O TLB Flushes/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Other Reflected Guest Exceptions/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\MBEC Nested Page Table Switches/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Extended Hypercall Intercept Messages/sec',
		'\\Hyper-V Hypervisor Virtual Processor({0}:Hv VP {1})\\Extended Hypercalls/sec'
	)

	$DiskCoreChecks = @(
		'\\Hyper-V Virtual Storage Device({0})\\Queue Length',
		'\\Hyper-V Virtual Storage Device({0})\\Normalized Throughput',
		'\\Hyper-V Virtual Storage Device({0})\\Write Operations/Sec',
		'\\Hyper-V Virtual Storage Device({0})\\Read Operations/Sec',
		'\\Hyper-V Virtual Storage Device({0})\\Write Bytes/sec',
		'\\Hyper-V Virtual Storage Device({0})\\Read Bytes/sec'
	)

	$DiskAdvancedChecks = @(
		'\\Hyper-V Virtual Storage Device({0})\\Error Count',
		'\\Hyper-V Virtual Storage Device({0})\\Flush Count',
		'\\Hyper-V Virtual Storage Device({0})\\Write Count',
		'\\Hyper-V Virtual Storage Device({0})\\Read Count'
	)

	$DiskAdvanced2012R2Checks = @(
		'\\Hyper-V Virtual Storage Device({0})\\Quota Replenishment Rate'
	)

	$DiskAdvanced2016Checks = @(
		'\Hyper-V Virtual Storage Device({0})\\Maximum Bandwidth',
		'\Hyper-V Virtual Storage Device({0})\\Byte Quota Replenishment Rate',
		'\Hyper-V Virtual Storage Device({0})\\Io Quota Replenishment Rate',
		'\Hyper-V Virtual Storage Device({0})\\Lower Latency',
		'\Hyper-V Virtual Storage Device({0})\\Minimum IO Rate',
		'\Hyper-V Virtual Storage Device({0})\\Maximum IO Rate',
		'\Hyper-V Virtual Storage Device({0})\\Latency',
		'\Hyper-V Virtual Storage Device({0})\\Throughput',
		'\Hyper-V Virtual Storage Device({0})\\Lower Queue Length'
	)

	$DynamicMemoryChecks = @( # same for 2012R2 and 2016, but always works on 2016
		'\\Hyper-V Dynamic Memory VM({0})\\Maximum Pressure',
		'\\Hyper-V Dynamic Memory VM({0})\\Minimum Pressure',
		'\\Hyper-V Dynamic Memory VM({0})\\Average Pressure',
		'\\Hyper-V Dynamic Memory VM({0})\\Current Pressure'
	)

	$DynamicMemoryDMOnlyChecks = @(
		'\\Hyper-V Dynamic Memory VM({0})\\Physical Memory',
		'\\Hyper-V Dynamic Memory VM({0})\\Guest Visible Physical Memory'
	)

	$DynamicMemoryChecks2016 = @(
		'\\Hyper-V Dynamic Memory VM({0})\\Memory Remove Operations',
		'\\Hyper-V Dynamic Memory VM({0})\\Removed Memory',
		'\\Hyper-V Dynamic Memory VM({0})\\Memory Add Operations',
		'\\Hyper-V Dynamic Memory VM({0})\\Added Memory'
	)

	$IDEChecks = @(
		'\\Hyper-V Virtual IDE Controller (Emulated)({0}:Ide Controller)\\Write Bytes/sec',
		'\\Hyper-V Virtual IDE Controller (Emulated)({0}:Ide Controller)\\Read Bytes/sec',
		'\\Hyper-V Virtual IDE Controller (Emulated)({0}:Ide Controller)\\Written Sectors/sec',
		'\\Hyper-V Virtual IDE Controller (Emulated)({0}:Ide Controller)\\Read Sectors/sec'
	)

	$LiveMigrationChecks = @(
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Decompressed Bytes/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Maximum Threadpool Thread Count',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Uncompressed Bytes Received/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Bytes Pending Write',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Bytes Written/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Memory Walker: Uncompressed Bytes Sent/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Memory Walker: Uncompressed Bytes Sent',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Memory Walker: Bytes Read/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Memory Walker: Maximum Threads',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Bytes Received/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Bytes Pending Processing',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Posted Receive Buffer Count',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Bytes Sent/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Bytes Pending Send',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Pending Send Count',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\TCP Transport: Total buffer count',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Transfer pass: CPU Cap',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Transfer pass: Dirty Page Count',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Transfer Pass: Is blackout',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Transfer Pass: Number'
	)

	$LiveMigrationCompressionChecks = @(
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Bytes Pending Decompression',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Receiver: Compressed Bytes Received/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Memory Walker: Bytes Sent for Compression/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Memory Walker: Bytes Sent for Compression',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Compressor: Enabled Threads',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Compressor: Maximum Threads',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Compressor: Compressed Bytes Sent/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Compressor: Compressed Bytes Sent',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\Compressor: Bytes to be Compressed'
	)

	$LiveMigrationSMBChecks = @( # same for 2012R2 and 2016
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\SMB Transport: Bytes Sent/sec',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\SMB Transport: Bytes Sent',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\SMB Transport: Pending Send Bytes',
		'\\Hyper-V VM Live Migration({0}:VM Live Migration)\\SMB Transport: Pending Send Count'
	)

	$NetworkCoreChecks = @(
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Bytes Sent/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Bytes Received/sec'
	)
	$NetworkAdvancedChecks = @(
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Extensions Dropped Packets Outgoing/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Extensions Dropped Packets Incoming/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Dropped Packets Outgoing/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Dropped Packets Incoming/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\IPsec offload Bytes Receive/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\IPsec offload Bytes Sent/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Directed Packets Sent/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Directed Packets Received/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Broadcast Packets Sent/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Broadcast Packets Received/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Multicast Packets Sent/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Multicast Packets Received/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Packets Sent/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Packets Received/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Packets/sec',
		'\\Hyper-V Virtual Network Adapter({0}_Network Adapter_{1}--{2})\\Bytes/sec'
	)

	$NetworkDropReasonChecks = @(
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing LowPowerPacketFilter',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming LowPowerPacketFilter',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidPDQueue',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidPDQueue',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing FilteredIsolationUntagged',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming FilteredIsolationUntagged',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing SwitchDataFlowDisabled',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming SwitchDataFlowDisabled',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing FailedPacketFilter',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming FailedPacketFilter',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing NicDisabled',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming NicDisabled',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing FailedDestinationListUpdate',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming FailedDestinationListUpdate',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InjectedIcmp',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InjectedIcmp',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing StormLimit',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming StormLimit',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Wnv',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Wnv',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidFirstNBTooSmall',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidFirstNBTooSmall',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidSourceMac',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidSourceMac',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidDestMac',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidDestMac',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidVlanFormat',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidVlanFormat',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing NativeFwdingReq',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming NativeFwdingReq',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing MTUMismatch',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming MTUMismatch',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidConfig',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidConfig',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing RequiredExtensionMissing',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming RequiredExtensionMissing',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing VirtualSubnetId',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming VirtualSubnetId',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing BridgeReserved',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming BridgeReserved',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing RouterGuard',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming RouterGuard',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing DhcpGuard',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming DhcpGuard',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing MacSpoofing',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming MacSpoofing',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Ipsec',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Ipsec',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Qos',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Qos',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing FailedPvlanSetting',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming FailedPvlanSetting',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing FailedSecurityPolicy',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming FailedSecurityPolicy',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing UnauthorizedMAC',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming UnauthorizedMAC',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing UnauthorizedVLAN',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming UnauthorizedVLAN',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing FilteredVLAN',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming FilteredVLAN',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Filtered',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Filtered',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Busy',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Busy',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing NotAccepted',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming NotAccepted',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Disconnected',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Disconnected',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing NotReady',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming NotReady',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Resources',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Resources',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidPacket',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidPacket',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing InvalidData',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming InvalidData',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Outgoing Unknown',
		'\\Hyper-V Virtual Network Adapter Drop Reasons({0}_Network Adapter_{1}--{2})\\Incoming Unknown'
	)

	$SaveSnapChecks = @( # same for 2012R2 and 2016
		'\\Hyper-V VM Save, Snapshot, and Restore({0}:Current or most recent Save-Restore-Snapshot operation)\\Operation Time',
		'\\Hyper-V VM Save, Snapshot, and Restore({0}:Current or most recent Save-Restore-Snapshot operation)\\Requests High Priority',
		'\\Hyper-V VM Save, Snapshot, and Restore({0}:Current or most recent Save-Restore-Snapshot operation)\\Requests Processed',
		'\\Hyper-V VM Save, Snapshot, and Restore({0}:Current or most recent Save-Restore-Snapshot operation)\\Requests Dispatched',
		'\\Hyper-V VM Save, Snapshot, and Restore({0}:Current or most recent Save-Restore-Snapshot operation)\\Requests Active',
		'\\Hyper-V VM Save, Snapshot, and Restore({0}:Current or most recent Save-Restore-Snapshot operation)\\Threads Spawned'
	)

	$SmartPagingChecks = @( # same for 2012R2 and 2016
		'\\Hyper-V Dynamic Memory VM({0})\\Smart Paging Working Set Size'
	)

	$VidChecks = @( # same for 2012R2 and 2016
		'\\Hyper-V VM Vid Partition({0})\\Remote Physical Pages',
		'\\Hyper-V VM Vid Partition({0})\\Preferred NUMA Node Index',
		'\\Hyper-V VM Vid Partition({0})\\Physical Pages Allocated'
	)

	#$VirtualDevicePipeChecks = @( # 2016 only -- uncertain where to find the GUIDs in {2}
	# '\\Hyper-V VM Virtual Device Pipe IO({0}:{1}-{{{2}}})\\Receive Message Quota Exceeded',
	# '\\Hyper-V VM Virtual Device Pipe IO({0}:{1}-{{{2}}})\\Receive QoS - Total Message Delay Time (100ns)',
	# '\\Hyper-V VM Virtual Device Pipe IO({0}:{1}-{{{2}}})\\Receive QoS - Exempt Messages/sec',
	# '\\Hyper-V VM Virtual Device Pipe IO({0}:{1}-{{{2}}})\\Receive QoS - Non-Conformant Messages/sec',
	# '\\Hyper-V VM Virtual Device Pipe IO({0}:{1}-{{{2}}})\\Receive QoS - Conformant Messages/sec'
	#)

	#$VMBusProviderChecks = @( # 2016 only -- uncertain where to find the GUIDs in {2}
	# '\\Hyper-V Virtual Machine Bus Provider Pipes({0}:{1}-{{{2}}})\\Bytes Written/sec',
	# '\\Hyper-V Virtual Machine Bus Provider Pipes({0}:{1}-{{{2}}})\\Bytes Read/sec',
	# '\\Hyper-V Virtual Machine Bus Provider Pipes({0}:{1}-{{{2}}})\\Writes/sec',
	# '\\Hyper-V Virtual Machine Bus Provider Pipes({0}:{1}-{{{2}}})\\Reads/sec'
	#)

	$VMWorkerProcessChecks = @( # 2016 only
		'\\Hyper-V Worker Virtual Processor({0}:WP VP {1})\\Intercepts Delayed',
		'\\Hyper-V Worker Virtual Processor({0}:WP VP {1})\\Intercept Delay Time (ms)'
	)

	$VRSSChecks = @( # 2016 only
		'\\Hyper-V Virtual Network Adapter VRSS({0}_Network Adapter_Entry _{1}_{2}--{3})\\SendPacketCompletionsPerSecond',
		'\\Hyper-V Virtual Network Adapter VRSS({0}_Network Adapter_Entry _{1}_{2}--{3})\\SendPacketPerSecond',
		'\\Hyper-V Virtual Network Adapter VRSS({0}_Network Adapter_Entry _{1}_{2}--{3})\\ReceivePacketPerSecond',
		'\\Hyper-V Virtual Network Adapter VRSS({0}_Network Adapter_Entry _{1}_{2}--{3})\\SendProcessor',
		'\\Hyper-V Virtual Network Adapter VRSS({0}_Network Adapter_Entry _{1}_{2}--{3})\\ReceiveProcessor'
	)

	$RemotingChecks = @( # 2016 only
		'\\Hyper-V VM Remoting({0}:Remoting)\\Updated Pixels/sec',
		'\\Hyper-V VM Remoting({0}:Remoting)\\Connected Clients'
	)
}

process
{
	Write-Progress -Activity 'Processing Input' -Status 'Processing Input'
	$RawVMList = New-Object -TypeName System.Collections.ArrayList
	if ($VM)
	{
		$InputType = $VM[0].GetType().FullName
		if ($InputType -eq 'Microsoft.HyperV.PowerShell.VirtualMachine')
		{
			$RawVMList.AddRange((Get-CimInstance -ComputerName $VM.ComputerName -Namespace 'root/virtualization/v2' -ClassName 'Msvm_ComputerSystem' -Filter ('Name="{0}"' -f $VM.Id)))
		}

		elseif ($InputType -eq 'System.String')
		{
			foreach ($VMItem in $VM)
			{
				$OutNull = $RawVMList.Add((Get-CimInstance -ComputerName $ComputerName -Namespace 'root/virtualization/v2' -ClassName 'Msvm_ComputerSystem' -Filter ('ElementName="{0}"' -f $VMItem)))
			}
		}
		elseif ($InputType -eq 'Microsoft.Management.Infrastructure.CimInstance' -and $VM[0].CreationClassName -eq 'Msvm_ComputerSystem')
		{
			$RawVMList.AddRange($VM)
		}
		elseif ($InputType -eq 'System.Management.ManagementObject')
		{
			foreach ($VMItem in $VM)
			{
				$OutNull = $RawVMList.Add((Get-CimInstance -ComputerName $VMItem.__SERVER -Namespace 'root/virtualization/v2' -ClassName 'Msvm_ComputerSystem' -Filter ('Name="{0}"' -f $VMItem.Name)))
			}
		}
		else
		{
			throw('Unable to process VM objects of type {0}' -f $InputType)
		}
	}
	else
	{
		$RawVMList.AddRange((Get-CimInstance -ComputerName $ComputerName -Namespace 'root/virtualization/v2' -ClassName 'Msvm_ComputerSystem'))
	}

	switch ($LineEndFormat[0].ToString().ToLower())
	{
		'l' { $LineEnding = "`n" }
		'm' { $LineEnding = "`r" }
		default { $LineEnding = "`r`n" }
	}

	Write-Progress -Activity 'Processing Input' -Status 'Loading Virtual Machines' -Completed

	if (-not $RawVMList.Count)
	{
		Write-Debug -Message 'No VMs specified in this pass'
		return
	}

	$SanitizedVMList = @($RawVMList | Where-Object -Property 'Name' -Match $GUIDPattern)

	if ($SanitizedVMList)
	{
		$VMList.AddRange($SanitizedVMList)
	}
	else
	{
		Write-Debug -Message 'A Hyper-V host was specified, but no VMs were found. Verify your permissions.'
		return
	}
}

end
{
	if (-not $VMList.Count)
	{
		Write-Warning -Message 'No VMs found'
		return
	}
	$PercentTracker = 0
	$ProcessPercentagePerVM = 100 * (1 / $VMList.Count)

	Write-Progress -Activity 'Retrieving Virtual Machine Information' -Status 'Loading List' -PercentComplete $PercentTracker
	foreach ($TargetVM in $VMList)
	{
		$PercentTracker += $ProcessPercentagePerVM
		Write-Progress -Activity 'Retrieving Virtual Machine Information' -Status $TargetVM.ElementName -PercentComplete $PercentTracker
		$HostName = $TargetVM.ComputerName

		try
		{
			$VMSD = Get-CimAssociatedInstance -InputObject $TargetVM -ResultClassName 'Msvm_VirtualSystemSettingData'
			$VMCPUData = Get-CimAssociatedInstance -InputObject $VMSD -ResultClassName 'Msvm_ProcessorSettingData'
			$VMDisks = Get-CimAssociatedInstance -InputObject $VMSD -ResultClassName 'Msvm_StorageAllocationSettingData' | where ResourceSubType -eq 'Microsoft:Hyper-V:Virtual Hard Disk'
			$VMMemory = (Get-CimAssociatedInstance -InputObject $VMSD -ResultClassName 'Msvm_MemorySettingData')[0]
			$VMIsClustered = [bool](
				[bool]((Get-CimAssociatedInstance -InputObject $VMSD -ResultClassName 'Msvm_KvpExchangeComponentSettingData').HostOnlyItems) -and
				(Get-CimAssociatedInstance -InputObject $VMSD -ResultClassName 'Msvm_KvpExchangeComponentSettingData').HostOnlyItems[0].Contains('VirtualMachineIsClustered')
			)

			$HostName = (Get-CimAssociatedInstance -InputObject $TargetVM -ResultClassName 'Msvm_VirtualSystemManagementService').SystemName
			if ([String]::IsNullOrEmpty($Version))
			{
				$Version = '2012R2'
				$DetectedVersion = (Get-CimInstance -ComputerName $HostName -ClassName 'Win32_OperatingSystem').Version
				if ($DetectedVersion -match '^10\.') { $Version = '2016' }
			}
			$VMMigrationSettings = Get-CimInstance -ComputerName $HostName -Namespace root/virtualization/v2 -ClassName Msvm_VirtualSystemMigrationServiceSettingData
			if ($VMIsClustered)
			{
				$HostName = (Get-CimInstance -ComputerName $HostName -Namespace 'root/MSCluster' -ClassName 'MSCluster_Cluster').Name
			}
		}
		catch
		{
			Write-Warning -Message ('An error occurred while retrieving data for {0}' -f $TargetVM.ElementName)
			Write-Error $_
			continue
		}

		if ($ResolveHost)
		{
			try
			{
				$HostName = (Resolve-DnsName -Name $HostName).IPAddress
			}
			catch
			{
				Write-Warning -Message ('Cannot resolve {0} to an IP address. Using "{0}" for the generated service target' -f $HostName)
			}
		}
		elseif ($UpperCaseHostName)
		{
			$HostName = $HostName.ToUpper()
		}

		$ServiceObjectParameters =
		@{
			'HostName'  = $HostName;
			'VMName'    = $TargetVM.ElementName;
			'Clustered' = $VMIsClustered;
		}

		$VMNetAdapters = Get-CimAssociatedInstance -InputObject $TargetVM -ResultClassName 'Msvm_SyntheticEthernetPort'

		if ($IncludeAdvancedCounters)
		{
			$ChecksList = $AdvancedChecks
			if ($Version -eq '2016') { $ChecksList += $AdvancedChecks2016 }
			foreach ($AdvancedCounter in $AdvancedChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'VM' -Counter ($AdvancedCounter -f $TargetVM.ElementName)))
			}
		}

		if (-not $SkipCPU)
		{
			$ChecksList = $CPUCoreChecks
			if ($IncludeAdvancedCounters)
			{
				$ChecksList += $CPUAdvancedChecks
				if ($Version -eq '2016') { $ChecksList += $CPUAdvanced2016Checks }
			}
			if ($Version -eq '2016' -and $IncludeVmWorkerProcess) { $ChecksList += $VMWorkerProcessChecks }
			for ($i = 0; $i -lt $VMCPUData.VirtualQuantity; $i++)
			{
				foreach ($CPUCounter in $ChecksList)
				{
					$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory ([String]::Join(' ', 'vCPU', $i)) -Counter ($CPUCounter -f $TargetVM.ElementName, $i)))
				}
			}
		}

		if (-not $SkipDisk)
		{
			foreach ($VMDisk in $VMDisks)
			{
				$ChecksList = $DiskCoreChecks
				if ($IncludeAdvancedCounters) { $ChecksList += $DiskAdvancedChecks }
				if ($IncludeAdvancedCounters -and $Version -eq '2012R2') { $ChecksList += $DiskAdvanced2012R2Checks }
				if ($IncludeAdvancedCounters -and $Version -eq '2016') { $ChecksList += $DiskAdvanced2016Checks }
				$DiskName = $VMDisk.HostResource[0]
				$DiskCounterPath = $DiskName -replace '^\\\\', '--?-UNC-'
				$DiskCounterPath = $DiskCounterPath -replace '\\', '-'
				$CounterCategory = [String]::Join(' ', 'vDisk', $DiskName.Substring($DiskName.LastIndexOf('\') + 1))
				foreach ($DiskCounter in $DiskCoreChecks)
				{
					$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory $CounterCategory -Counter ($DiskCounter -f $DiskCounterPath)))
				}
			}
		}

		if (-not $SkipDynamicMemory)
		{
			$ChecksList = @()
			if ($Version -eq '2016' -or $VMMemory.DynamicMemoryEnabled) { $ChecksList += $DynamicMemoryChecks }
			if ($VMMemory.DynamicMemoryEnabled) { $ChecksList += $DynamicMemoryDMOnlyChecks }
			if ($Version -eq '2016' -and $VMMemory.DynamicMemoryEnabled) { $ChecksList += $DynamicMemoryChecks2016 }
			foreach ($DynamicMemoryCounter in $ChecksList)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'vMemory' -Counter ($DynamicMemoryCounter -f $TargetVM.ElementName)))
			}
		}

		if ($VMIsClustered -and $IncludeLiveMigration)
		{
			$ChecksList = $LiveMigrationChecks
			if ($VMMigrationSettings.EnableCompression) { $ChecksList += $LiveMigrationCompressionChecks }
			if ($VMMigrationSettings.EnableSmbTransport) { $ChecksList += $LiveMigrationSMBChecks }
			foreach ($LiveMigrationCounter in $LiveMigrationChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'Live Migration' -Counter ($LiveMigrationCounter -f $TargetVM.ElementName)))
			}
		}

		if ($VMSD.VirtualSystemSubType -eq 'Microsoft:Hyper-V:SubType:1' -and $IncludeIDE)
		{
			foreach ($IDECount in $IDEChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'vIDE' -Counter ($IDECount -f $TargetVM.ElementName)))
			}
		}

		if ($VMNetAdapters -and -not $SkipNetwork)
		{
			foreach ($VMNetAdapter in $VMNetAdapters)
			{
				$FoundAdapterIDs = $false
				if ($VMNetAdapter.DeviceId -match $GUIDPattern)
				{
					$DeviceID = $Matches[0].ToLower()
					$FoundAdapterIDs = $true
				}

				if ($FoundAdapterIDs -and $VMNetAdapter.SystemName -match $GUIDPattern)
				{
					$SystemName = $Matches[0].ToLower()
					$FoundAdapterIDs = $true
				}
				if ($FoundAdapterIDs)
				{
					$ChecksList = $NetworkCoreChecks
					if ($IncludeAdvancedCounters) { $ChecksList += $NetworkAdvancedChecks }
					if ($Version -eq '2016' -and $IncludeNetworkDropReasons) { $ChecksList += $NetworkDropReasonChecks }
					foreach ($NetworkCounter in $ChecksList)
					{
						$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'vNIC' -Counter ($NetworkCounter -f $TargetVM.ElementName, $SystemName, $DeviceID)))
					}

					if ($Version -eq '2016' -and $IncludeVRSS)
					{
						foreach ($VP in @(0..15))
						{
							foreach ($VRSSCheck in $VRSSChecks)
							{
								$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory ('vRSS VP {0}' -f $VP) -Counter ($VRSSCheck -f $TargetVM.ElementName, $VP, $SystemName, $DeviceID)))
							}
						}
					}
				}
			}
		}

		if ($IncludeSavesSnaps)
		{
			foreach ($SaveSnapCounter in $SaveSnapChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'Save and Snapshot' -Counter ($SaveSnapCounter -f $TargetVM.ElementName)))
			}
		}

		if ($IncludeSmartPaging)
		{
			foreach ($SmartPagingCounter in $SmartPagingChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'Smart Paging' -Counter ($SmartPagingCounter -f $TargetVM.ElementName)))
			}
		}

		if ($IncludeNUMA)
		{
			foreach ($VidCounter in $VidChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'VID' -Counter ($VidCounter -f $TargetVM.ElementName)))
			}
		}

		if ($Version -eq '2016' -and $IncludeRemotingChecks)
		{
			foreach ($RemotingCheck in $RemotingChecks)
			{
				$OutNull = $CounterList.Add((New-ServiceObject @ServiceObjectParameters -CounterCategory 'Remoting' -Counter ($RemotingCheck -f $TargetVM.ElementName)))
			}
		}
	}
	Write-Progress -Activity 'Retrieving Virtual Machine Information' -Completed

	Write-Progress -Activity 'Writing Service Definitions' -Status 'Initializing'
	try
	{
		$OutStream = [System.IO.StreamWriter]::New($Path)
		if ($VMAsHost -and $CreateVMHostDefinition)
		{
			foreach ($TargetVM in $VMList)
			{
				$OutStream.Write((New-HostDefinition -ComputerName $TargetVM.ElementName -HostTemplate $VMHostTemplate -UseSkeletonHost $UseSkeletonHost.ToBool() -VMHostGroups $VMHostGroups -LineEnding $LineEnding -VMHostContacts $VMHostContacts -VMHostContactGroups $VMHostContactGroups))
			}
		}
		foreach ($CounterItem in $CounterList)
		{
			$ServiceText = New-ServiceDefinition -ServiceObject $CounterItem -LineEnding $LineEnding -ServiceTemplate $ServiceTemplate -ServiceGroups $ServiceGroups -ServiceContacts $ServiceContacts -ServiceContactGroups $ServiceContactGroups -VMAsHost $VMAsHost.ToBool()
			foreach ($ServiceTextLine in $ServiceText)
			{
				$OutStream.Write($ServiceTextLine)
			}
		}
	}
	catch
	{
		$_
	}
	finally
	{
		$OutStream.Close()
	}
	Write-Progress -Activity 'Writing Service Definitions' -Completed
}
