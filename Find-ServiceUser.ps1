Function Find-ServiceUser {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true, position = 0)]
        [string[]]
        $computer,

        [parameter(mandatory = $false, position = 1)]
        [string]
        $user,

        [parameter(Mandatory = $false, HelpMessage = 'Turns on the search after the exact username.')]
        [switch]
        $Strict
    )
    $user = $user.trim()
    $computer = $computer.trim()
    try {
        Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose -Message "$computer offline?"
        Write-Information -MessageData "$computer offline?" -InformationAction Continue
        return $null
    }
    if ($Strict) {
        $filter = "startname = '$($user)'"
        #Write-Information $filter -InformationAction Continue
    }
    else {
        $filter = "startname LIKE '%$($user)%'"
    }
    Write-Verbose -Message "WMI query for system services."
    try {
        $service_ = Get-CimInstance -classname win32_service -filter "$filter" -ComputerName $computer -ErrorAction Stop
    } 
    catch {
        Write-Error -Message "Failed WMI query for system services with Service Logon Account as ""$user"": $_"
    }
    if ($service_) {
        Write-Verbose -Message "Return WMI query data"
        return $service_
    } 
}# end function Find-ServiceUser
