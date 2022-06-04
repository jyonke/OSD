function Test-MicrosoftUpdateCatalog {
    [CmdletBinding()]
    param ()

    $StatusCode = (Invoke-WebRequest -Uri 'https://www.catalog.update.microsoft.com' -UseBasicParsing -Method Head -ErrorAction Ignore).StatusCode

    if ($StatusCode -eq 200) {
        Return $true
    }
    else {
        Return $false
    }
}
