<#
.SYNOPSIS
    Disables Windows 11 upgrade.
.DESCRIPTION
    Disables Windows 11 upgrade by locking the TargetReleaseVersion and TargetReleaseVersionInfo to the currently installed version.
.EXAMPLE
    No parameters needed
    Disables Windows 11 upgrade.
.OUTPUTS
    None
#>
[CmdletBinding()]
param ()

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        # Do not output errors and continue
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        if (-not $(Test-Path -Path $Path)) {
            # Check if path does not exist and create the path
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name)) {
            # Update property and print out what it was changed from and changed to
            $CurrentValue = Get-ItemProperty -Path $Path -Name $Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "$Path$Name changed from $CurrentValue to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        else {
            # Create property with value
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "Set $Path$Name to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Get Current Version
    $release = (Get-ItemProperty -Path "HKLM:SOFTWAREMicrosoftWindows NTCurrentVersion" -Name ReleaseId).ReleaseId
    $ver = (Get-ItemProperty -Path "HKLM:SOFTWAREMicrosoftWindows NTCurrentVersion" -Name DisplayVersion).DisplayVersion
    $TargetReleaseVersion = if ($release -eq '2009') { $ver } Else { $release }

    # Block Windows 11 Upgrade by changing the target release version to the current version
    try {
        Set-ItemProp -Path "HKLM:SOFTWAREPoliciesMicrosoftWindowsWindowsUpdate" -Name "TargetReleaseVersion" -Value 1 -PropertyType DWord
        Set-ItemProp -Path "HKLM:SOFTWAREPoliciesMicrosoftWindowsWindowsUpdate" -Name "TargetReleaseVersionInfo" -Value "$TargetReleaseVersion" -PropertyType String
        Set-ItemProp -Path "HKLM:SOFTWAREMicrosoftWindowsUpdateUXSettings" -Name "SvOfferDeclined" -Value 1646085160366 -PropertyType QWord
    }
    catch {
        Write-Error $_
        Write-Host "Failed to block Windows 11 Upgrade."
        exit 1
    }
    exit 0
}
end {}