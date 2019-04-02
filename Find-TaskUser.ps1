Function Find-TaskUser {
    [CmdletBinding()]
    param(
        [string]$server,

        [string]$user
    )
    process {
        #23 start
        $server = $server.trim()
        #if ([bool](Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        if (Invoke-Command -ComputerName $server -ScriptBlock {[bool](Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)}) {
            try {
                Write-Verbose -Message "$server : Try use Get-ScheduledTask"
                $data = Get-ScheduledTask -CimSession $server -ErrorAction stop | Where-Object {$_.author -match $user.trim() -or $_.Principal.userid -match $user.trim()} | Select-Object hostname, taskname, @{Name="Run As User"; Expression = {$_.Principal.userid}}, Author, URI
            } 
            catch {
                Write-verbose -Message "Get-ScheduledTask error: $_"
                Write-Verbose -Message "$server : Switching to schtasks command."
            }
        } else {
            if (($server -match $env:COMPUTERNAME) -or ($server -eq "localhost")) {
                Write-Verbose -Message "$server : Try use schtasks on local computer"
                try {
                    $tasks=Invoke-Expression "schtasks /query /fo csv /v" -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Failed to invoke ""schtasks"": $_"
                }
            } else {
                Write-Verbose -Message "$server : Try use schtasks on remote computer"
                $exp_schtasks = "schtasks /Query /S $server /FO CSV /V"
                write-Verbose $exp_schtasks
                try {
                    $tasks=Invoke-Expression $exp_schtasks -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Failed to invoke ""schtasks"": $_"
                }
            } 
            Write-Verbose -Message "$server : Filtering scheduled tasks"
            $header = "HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Author","Task To Run","Start In","Comment","Scheduled Task State","Idle Time","Power Management","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Schedule","Schedule Type","Start Time","Start Date","End Date","Days","Months","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running"
            return $tasks | ConvertFrom-Csv -Header $header | Where-Object {$_."Run As User" -match $user -or $_."Author" -match $user}| Select-Object hostname, @{Name="taskname"; Expression = {($_.TaskName).split("\")[-1]}}, "run as user", author, @{Name="URI"; Expression = {$_.TaskName}} -Unique
        }
        #23 end

<#
        if ([bool](Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message 'Running ''Get-ScheduleTask'''
            $data = Get-ScheduledTask -CimSession $server.trim() | Where-Object {$_.author -match $user.trim() -or $_.Principal.userid -match $user.trim()} | Select-Object hostname, taskname, @{Name="Run As User"; Expression = {$_.Principal.userid}}, Author, URI
            foreach ($record in $data) {
                $record.hostname = $server.trim()
            }
            return $data
        } else {
            Write-Verbose -Message 'Running system command ''schtasks'''
            if ($server.trim() -match $env:COMPUTERNAME -or $server.trim() -eq "localhost") {
                try {
                    $tasks=Invoke-Expression "schtasks /query /fo csv /NH /v" -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Failed to invoke ""schtasks"": $_"
                }
            } else {
                try {
                    $tasks=Invoke-Expression "schtasks /query /s $server.trim() /NH /fo csv /v" -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Failed to invoke ""schtasks"": $_"
                }
            } 
            Write-Verbose -Message 'Filtering scheduled tasks'
            $header = "HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Author","Task To Run","Start In","Comment","Scheduled Task State","Idle Time","Power Management","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Schedule","Schedule Type","Start Time","Start Date","End Date","Days","Months","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running"
            return $tasks | ConvertFrom-Csv -Header $header | Where-Object {$_."Run As User" -match $user -or $_."Author" -match $user}| Select-Object hostname, @{Name="taskname"; Expression = {($_.TaskName).split("\")[-1]}}, "run as user", author, @{Name="URI"; Expression = {$_.TaskName}} -Unique
        } # end if
#>    
    
    }
}
