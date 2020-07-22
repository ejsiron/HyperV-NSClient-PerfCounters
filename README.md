# HyperV-NSClient-PerfCounters

One script to automatically generate NSClient-compatible performance counters in Nagios, one to read them

## Purpose

The final product of these scripts is a file with auto-generated Nagios/Icinga services. Those services will call a Python script that will contact the Hyper-V host to retrieve counter data.

## Prerequisites

You need to bring:

- A functional [Nagios](https://www.nagios.org/), [Icinga](https://www.icinga.com/), or compatible environment
- check_nrpe on the above
- A plug-in for the above that can process performance data, such as [PNP4Nagios](https://docs.pnp4nagios.org/)
- A Python environment on the above
- A functional Hyper-V host with one or more running virtual machines
- Access to that host Hyper-V host with PowerShell
- [NSClient](https://www.nsclient.org/) installed on that Hyper-V host, reachable by the Nagios/Icinga/compatible environment

## Features of Python script

This section explains why you can't just use the normal performance counter reading tools and how the Python script solves them

- If the target VM is off, no counter data will be generated (counter won't even exist); the script substitutes empty data
- If the target VM is clustered, the script will chase down the owning node and retrieve counter data from it

## How to use the PowerShell script

Read the help data for it.

## How to configure NSClient

Make these changes to nsclient.ini:

```Shell
[/settings/NRPE/server]
allow nasty characters = 1

[/modules]
CheckCounter = 1
CheckWMI = 1
```

## Create the Nagios command

The automatically generated services list will attempt to use a Nagios command named "check-hypervmperf". How you implement that command depends on if you are using a secure or insecure channel to NSClient.

### Insecure command

```
# Retrieves performance information for Hyper-V virtual machines
# HOSTADDRESS: always attach to the cluster or host that owns the virtual machine
# ARG1: the host or cluster that owns the virtual machine
# ARG2: the name of the virtual machine. for clustered VMs, the cluster resource must end in the same
# ARG3: the counter to retrieve. works with any counter on the host, but VMs are intended. ex: "\\Hyper-V Dynamic Memory VM(VMNAME)\\Physical Memory"
# ARG4: additional optional arguments to pass to check_hypervmperf
## -l # treat VM as clustered; find actual current host
## -W value # warn level for counter
## -C value # critical level for counter
## -m # when specified, values from -W and -C will be treated as lower bounds instead of upper (min instead of max)
define command{
   command_name check-hypervmperf
   command_line $USER1$/check_hypervmperf -H $ARG1$ -N $ARG2$ -c $ARG3$ $ARG4$
}
```

### Secure command

Treat this as an example only. You will need to supply your own certificate paths and names.

```
# Retrieves performance information for Hyper-V virtual machines
# HOSTADDRESS: always attach to the cluster or host that owns the virtual machine
# ARG1: the host or cluster that owns the virtual machine
# ARG2: the name of the virtual machine. for clustered VMs, the cluster resource must end in the same
# ARG3: the counter to retrieve. works with any counter on the host, but VMs are intended. ex: "\\Hyper-V Dynamic Memory VM(VMNAME)\\Physical Memory"
# ARG4: additional optional arguments to pass to check_hypervmperf
## -l # treat VM as clustered; find actual current host
## -W value # warn level for counter
## -R value # critical level for counter
## -m # when specified, values from -W and -C will be treated as lower bounds instead of upper (min instead of max)
define command{
 command_name check-hypervmperf
 command_line $USER1$/check_hypervmperf -t 30 -p 5666 -A /var/ca/ca_cert.pem -C /var/certs/check_nrpe.pem -K /var/certs/check_nrpe.key -H $ARG1$ -N $ARG2$ -c $ARG3$ $ARG4$
}
```

# Sample Templates

Configuration mismatches will cause perfectly logical output from this script to fail spectacularly. For instance, if you do not properly attach the service or host name to a valid parent, it might attach to something like "generic-host", causing all sorts of duplicate service warnings. Carefully think through and build out the template hierarchy to use for your VM performance counters _before_ running this script.
Connecting a Hyper-V host to its services can be done in multiple perfectly valid ways. Here is a suggestion:

```
## Virtual Machine object ##
define host{
   name hyperv-vm
   use perf-host,generic-host
   contact_groups admins
   check_command check-vm-null
   max_check_attempts 1
   register 0
}

define command{
   command_name check-vm-null
   command_line $USER1$/check_dummy 0
}

define servicegroup{
   servicegroup_name hyperv-vm-perf-services
   alias Hyper-V VM Performance Metrics
}

define service{
   name hyperv-vm-performance
   servicegroups hyperv-vm-perf-services
   use perf-service,generic-service
   contact_groups admins
   notification_period none
   register 0
}
```

Instruct the script to use the above host and service names as templates, and you should avoid collisions.
