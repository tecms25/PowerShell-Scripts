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
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes:
    Disallows the upgrade offer to Windows 11 to appear to users
    (c) 2023 NinjaOne
    By using this script, you indicate your acceptance of the following legal terms as well as our Terms of Use at https://www.ninjaone.com/terms-of-use.
    Ownership Rights: NinjaOne owns and will continue to own all right, title, and interest in and to the script (including the copyright). NinjaOne is giving you a limited license to use the script in accordance with these legal terms. 
    Use Limitation: You may only use the script for your legitimate personal or internal business purposes, and you may not share the script with another party. 
    Republication Prohibition: Under no circumstances are you permitted to re-publish the script in any script library or website belonging to or under the control of any other software provider. 
    Warranty Disclaimer: The script is provided “as is” and “as available”, without warranty of any kind. NinjaOne makes no promise or guarantee that the script will be free from defects or that it will meet your specific needs or expectations. 
    Assumption of Risk: Your use of the script is at your own risk. You acknowledge that there are certain inherent risks in using the script, and you understand and assume each of those risks. 
    Waiver and Release: You will not hold NinjaOne responsible for any adverse or unintended consequences resulting from your use of the script, and you waive any legal or equitable rights or remedies you may have against NinjaOne relating to your use of the script. 
    EULA: If you are a NinjaOne customer, your use of the script is subject to the End User License Agreement applicable to you (EULA).
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