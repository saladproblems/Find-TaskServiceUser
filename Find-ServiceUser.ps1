Function Find-ServiceUser {
    [CmdletBinding()]
    param (
        [parameter(mandatory,ValueFromPipelineByPropertyName,position = 0)]
        [string[]]
        $ComputerName,

        [parameter(position = 1)]
        [string[]]
        $User,

        [parameter(HelpMessage = 'Turns on the search after the exact username.')]
        [switch]
        $Strict
    )

    begin {
        $filterString = if ($Strict.IsPresent){
            'StartName Like "%{0}%"'
        }
        else {
            'Startname = "{0}"'
        }

        $cimParam = @{
            Filter = $User.ForEach({ $filterString -f $PSItem.trim() }) -join ' OR '
        }
    }

    process {
        Get-CimInstance -ComputerName $ComputerName @cimParam
    }
}
