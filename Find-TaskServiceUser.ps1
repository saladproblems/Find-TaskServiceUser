﻿Function Find-TaskServiceUser {
    <#
.SYNOPSIS
Finding scheduled tasks, system services on computer by user name. 
.DESCRIPTION
Finding scheduled tasks, system services on local or remote computer by given user name. 
'Administrator' and local computer are default values.
The results can be redirected to the log file (see 'log' parameter).
.PARAMETER User
User name to find scheduled tasks or system services. Default value is 'Administrator'.
.PARAMETER Computer
Computer to find tasks/services. Default value is 'localhost' ($env:COMPUTERNAME).
.PARAMETER Task
A Switch to look for scheduled tasks where user name is matched.
.PARAMETER Service
A Switch to look for system services where user name is matched.
.PARAMETER Minimal
A switch to enable minimalistic results. Object containing the computer name, number of tasks and/or number of services only. With -Log information about log file path is displayed but log file is not minimal. The return value is en object.
.PARAMETER Export
Enable exporting results objectsr to file (using "Export-Clixml"). Export file path is defined in "Exportpath" parameter.
.PARAMETER Exportpath
File name path to export results finding scheduled tasks and/or system services.
.PARAMETER Log
A switch to enable logging of output data to a log file. The log file with the path is defined in "LogFile" parameter.
.PARAMETER Logfile
Path with file name where logging output. Default value is [$env:TEMP]\find-taskserviceuser.log. Works only with Log switch.
.EXAMPLE
PS> Find-TaskServiceUser -Computer "WSRV00" -User "BobbyK" -Service -Task -Log

Description
-----------
Find system services and scheduled tasks on "WSRV00" for user name is matched "BobbyK". Logging is enabled.
.EXAMPLE
PS> "WSRV01","WSRV02" | Find-TaskServiceUser -Service -Task

Description
-----------
Find system services and scheduled tasks on computers "WSRV01", "WSRV02"  where user name is matched "Administrator".
.EXAMPLE
PS> $data = Find-TaskServiceUser -Task -Service -Server "WSRV04" -User "SYSTEM" -Minimal
PS> $data

Description
-----------
Find tasks and services on server "WSRV04" for "SYSTEM" user and return a minimalistic result as custom object `$data`.
.EXAMPLE
PS> "WSRV01","WSRV10" | Find-TaskServiceUser -Service -Task -Export
PS> $data = Import-Clixml "C:\Users\test_user\Documents\Find-TaskServiceUser.XML"
PS> $data.Tasks | Format-Table -Autosize
PS> $data.Services | Format-Table -Autosize

Description
-----------
Find system services and scheduled tasks on computers "WSRV01", "WSRV10" where user name is matched "Administrator". Results are exported to XML file and then imported to $data variable. Results are displayed.
.LINK
https://github.com/voytas75/Find-TaskServiceUser
.LINK
https://www.powershellgallery.com/packages/Find-TaskServiceUser
.NOTES
ICON CREDITS: Module icon made by [Freepik](https://www.freepik.com/) from [Flaticon](https://www.flaticon.com/) is licensed [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)
DONATION: If you want to support my work https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=ZQJXFYKHL7JUA&currency_code=PLN&source=url
#>
    [CmdletBinding()]
    Param(
        [parameter(mandatory = $false, position = 0, valuefrompipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Computer NetBIOS, DNS name or IP.')]
        [Alias('MachineName', 'Server')]
        [string[]]$Computer = $env:COMPUTERNAME,

        [parameter(Mandatory = $false, HelpMessage = 'User(s) or group name(s) to find scheduled tasks and/or services. Group is used for the security context of the scheduled task only, not system services.')]
        [string[]]$User = 'Administrator',

        [parameter(Mandatory = $false, HelpMessage = 'Turns on the search after the exact username.')]
        [switch]$Strict,

        [parameter(Mandatory = $false, HelpMessage = 'Switch to find system services.')]
        [switch]$Service,

        [parameter(Mandatory = $false, HelpMessage = 'Switch to find scheduled tasks.')]
        [switch]$Task,

        [parameter(Mandatory = $false, HelpMessage = 'Minimalistic results. Object containing the computer name, number of tasks and/or number of services only. with -Log info about log file is displayed but log file is not minimal.')]
        [Alias('Count','CountOnly')]
        [switch]$Minimal,

        [parameter(Mandatory = $false, HelpMessage = 'Enable exporting to file.')]
        [switch]$Export,

        [parameter(Mandatory = $false, HelpMessage = 'Enter path to export file.')]
        [string]$Exportpath = [Environment]::GetFolderPath("MyDocuments") + "\Find-TaskServiceUser.XML",

        [parameter(Mandatory = $false, HelpMessage = 'Enable exporting to JSON file.')]
        [switch]$ExportJSON,

        [parameter(Mandatory = $false, HelpMessage = 'Enter path to export JSON file.')]
        [string]$ExportJSONpath = [Environment]::GetFolderPath("MyDocuments") + "\Find-TaskServiceUser.json",

        [parameter(Mandatory = $false, HelpMessage = 'Switch to enable logging.')]
        [switch]$Log,

        [parameter(Mandatory = $false, HelpMessage = 'Log file path. Default is ''[$env:TEMP]\Find-TaskServiceUser.log''.')]
        [string]$Logfile = "$env:TEMP\Find-TaskServiceUser.log"
    )
    Begin {
        if (!$service -and !$task) { 
            $Service = $Task = $true
        } 
        if (-not $Minimal) {
            if ($user -eq "Administrator") {
                Write-Output "Set default user: Administrator"
            }
            if ($computer -eq $env:COMPUTERNAME) {
                Write-Output "Set default computer: $env:COMPUTERNAME (localhost)"
            }  
        }
        else {
            Write-Verbose "Initializing minimalistic results."
            $minimal_obj = @()
            $s = 0
            $t = 0
            $services_count = $s
            $tasks_count = $t
        }
        if ($Log) {
            Write-Log "---------$(Get-Date)---------"
        }
        $i = 1 #write-progress
    } # end BEGIN block
    Process {
        foreach ($user_item in $User) {
            $user_item = $user_item.trim()
            Write-Progress -id 1 -activity "Searching user" -status "$user_item" -percentComplete ($i++ / $user.Count * 100)
            $j = 1 #write-progress
            foreach ($item in $Computer) {
                $item = $item.trim()
                Write-Progress -parentId 1 -activity "Searching on server" -status "$item" -percentComplete ($j++ / $Computer.count * 100)
                #Tasks
                if ($task) {
                    if (!$Minimal) {
                        Write-Output "Finding tasks with user: ""$($user_item.toupper())"" on machine: ""$($item.toupper())"""
                    }
                    if ($Log) {
                        Write-Log "$(Get-Date): Finding tasks with user: ""$($user_item.toupper())"" on machine: ""$($item.toupper())"""
                    }
                    if ($Strict) {
                        $tasks = Find-TaskUser -server $item -user $user_item -Strict | Sort-Object taskname
                    } else {
                        $tasks = Find-TaskUser -server $item -user $user_item | Sort-Object taskname
                    }
                    #$tasks
                    if ($tasks) {
                        # tasks found
                        Write-Verbose "Task result not null"
                        if ($Log) {
                            Write-Log "$(Get-Date): Scheduled tasks:"
                        }
                        $tasksdata = $tasks | Select-Object Hostname, Taskname, Author, "Run as user", URI
                        if ($Minimal) {
                            $tasks_count = ($tasks | Measure-Object).count
                        }
                        else {
                            Write-Output "Found scheduled task(s) where ""$user_item"" matches task author or 'run as user'"
                            $tasksdata | Format-Table -AutoSize
                        }
                        if ($Log) {
                            $tasksdata | ForEach-Object { Write-Log $_ }
                        }
                    }
                    else {
                        # tasks not found
                        if ($Log) {
                            Write-Log "$(Get-Date): No scheduled tasks or no data from ""$item"" for user ""$user_item"""
                        }
                        if ($Minimal) {
                            $tasks_count = $t
                        }
                        else {
                            Write-Output "No scheduled tasks or no data from ""$item"" for user ""$user_item"""
                        }
                    }
                }
                #Services
                if ($service) {    
                    if (-not $Minimal) {
                        Write-Output "Finding system services with user: ""$($user_item.toupper())"" on machine: ""$($item.toupper())"""
                    }
                    if ($Log) {
                        Write-Log "$(Get-Date): Finding services with user: ""$($user_item.toupper())"" on machine: ""$($item.toupper())"""
                    }
                    if ($Strict){
                        $services = Find-ServiceUser -computer $item -user $user_item -strict | Sort-Object name
                    } else {
                        $services = Find-ServiceUser -computer $item -user $user_item | Sort-Object name
                    }
                    if ($services) { 
                        # services found
                        Write-Verbose "Services result not null"
                        if ($Log) {
                            Write-Log "$(Get-Date): System services:"
                        }
                        $output1 = $services | Select-Object SystemName, Name, StartName, State
                        if ($Minimal) {
                            $services_count = ($services | Measure-Object).count
                        }
                        else {
                            Write-Output "Found system service(s) where ""$user_item"" matches 'Service Logon Account'"
                            $output1 | Format-Table -AutoSize
                        }
                        if ($Log) {
                            $output1 | ForEach-Object { Write-Log $_ }            
                        }
                    }
                    else {
                        # services not found
                        Write-Verbose "Services result is null"
                        if ($Log) {
                            Write-Log "$(Get-Date): No services found or no data from ""$item"" for user ""$user_item"""
                        }
                        if ($Minimal) {
                            $services_count = $s
                        }
                        else {
                            Write-Output "No system services or no data from ""$item"" for user ""$user_item"""          
                        }
                    }
                }
                if (-not $tasks -and (-not $task -and $service)) {
                    $tasks_count = $null
                }
                if (-not $services -and (-not $service -and $task)) {
                    $services_count = $null
                }
                if ($Minimal) {
                    $minimal_obj += [PSCustomObject]@{
                        UserName      = $user_item
                        ComputerName  = $item
                        ServicesCount = $services_count
                        TasksCount    = $tasks_count
                    }
                    $services_count = $s
                    $tasks_count = $t
                }
                if ($Export -or $ExportJSON) {
                    Write-Verbose -Message "Building objects with all results"
                    if ($tasks) {
                        $tasks_all += $tasks 
                    }
                    if ($services) {
                        $services_all += $services
                    }
                }
            } # end foreach $Computer
        } # end foreach $User
    } # end PROCESS block
    End {
        if ($Log -and -not $Minimal) { 
            Write-Output "Log File: $($Logfile)"
        }
        elseif ($minimal -and $Log) {
            Write-Information -MessageData "Log File: $($Logfile)" -InformationAction Continue
            $minimal_obj
        }
        elseif ($minimal -and -not $log) {
            $minimal_obj
        }
        if ($export) {
            Write-Information -MessageData "Export XML File: $($Exportpath)" -InformationAction Continue
            Write-Information -MessageData "Export XML File: You can import file using 'Import-Clixml `"$($Exportpath)`"'" -InformationAction Continue
            $task_all_unique = $tasks_all | Sort-Object taskname -Unique
            $services_all_unique = $services_all | Sort-Object name -Unique
            $export_data = @{"Tasks" = $task_all_unique; "Services" = $services_all }
            #Add-Content -LiteralPath $Exportpath -Value $export_data -PassThru
            Export-Clixml -LiteralPath $Exportpath -InputObject $export_data
        }
        if ($ExportJSON) {
            Write-Information -MessageData "Export JSON File: $($Exportjsonpath)" -InformationAction Continue
            Write-Information -MessageData "Export JSON File: You can import file using '`$json_data = Get-Content -Raw -Path `"$($Exportjsonpath)`" | ConvertFrom-Json'" -InformationAction Continue
            $task_all_unique = $tasks_all | Sort-Object taskname -Unique
            $services_all_unique = $services_all | Sort-Object name -Unique
            $export_data = @{"Tasks" = $task_all_unique; "Services" = $services_all }
            $export_data | ConvertTo-Json | out-file $Exportjsonpath
        }
    } # end END block
} # end Find-TaskServiceUser function
