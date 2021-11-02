param(
    [Parameter(Mandatory)]
    [string]
    $AccountName,

    [Parameter(Mandatory)]
    [string]
    $AccountKey,

    [Parameter(Mandatory)]
    [string]
    $Container,

    [Parameter()]
    [ValidateSet(1, 10, 100, 1000)]
    [Int32]
    $BatchSize = 1,

    [Parameter()]
    [ValidateRange(1, 50)]
    [Int32]
    $BatchCount = 1,

    [switch]
    $DryRun
)

function Assert-Success([string]$ErrorMessage) {
    if (!$?) {
        throw  $ErrorMessage
    }
}

$ErrorActionPreference = "Stop";

Write-Host -ForegroundColor Cyan "Uploading $BatchCount batches of $BatchSize blobs to Storage"

# Detect login/token expiration here
$acct = az account get-access-token;
if ($ForceLogin -or !$acct) {
    Write-Host $(If ($ForceLogin) { "" } else { "Not logged in (or token expired) -" }) "Logging in now..."
    az login | Out-Null
    Assert-Success "Error Logging In."
}

# upload here
$pattern = "";
switch ($BatchSize) {
    1 { $pattern = "img0000.png" }
    10 { $pattern = "img000?.png" }
    100 { $pattern = "img00??.png" }
    1000 { $pattern = "img0???.png" }
    default {
        throw "No Match Found for Batch Size $BatchSize"
    }
}

Write-Host "Each batch ($BatchCount batches) is Uploading $BatchSize records with pattern '$pattern'"

1..$BatchCount | ForEach-Object -Parallel {
    if ($using:DryRun) {
        Write-Output "Dry Run, skipping upload $_."
    }
    else {
        try {
            # Write-Output "Uploading Batch $_`n"

            az storage blob upload-batch `
                --auth-mode key `
                --account-name $using:AccountName `
                --account-key $using:AccountKey `
                -d $using:Container `
                -s ./blobs `
                --pattern $using:pattern `
                | Out-Null
                # $using:Assert-Success "Error Uploading Blobs"
        }
        catch {
            Write-Output "Error Uploading", $_
        }
    }
} -ThrottleLimit 6 -AsJob | Wait-Job | Receive-Job