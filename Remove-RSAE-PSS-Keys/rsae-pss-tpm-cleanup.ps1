# Define the registry path and the multi-string value name
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\SSL\00010003"
$valueName = "Functions"
$entriesToDelete = @("RSAE-PSS/SHA256", "RSAE-PSS/SHA384", "RSAE-PSS/SHA512")  

# Define a flag for success
$success = $true

try {
    # Read the current multi-string value
    $currentValues = Get-ItemProperty -Path $registryPath -Name $valueName | Select-Object -ExpandProperty $valueName

    # Remove the specified entries
    $updatedValues = $currentValues | Where-Object { $_ -notin $entriesToDelete }

    # Write the updated multi-string value back to the registry
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $updatedValues

    Write-Output "Updated the multi-string value '$valueName' at '${registryPath}'."
} catch {
    # Write the error to the console and mark failure
    Write-Error "An error occurred: {$_}"
    $success = $false
}

# Exit with the appropriate status code
if ($success) {
    exit 0
} else {
    exit 1
}