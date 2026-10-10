$ErrorActionPreference = "Stop"

$path = Join-Path $PSScriptRoot "..\lib\screens\home\dashboard_screen.dart"
$path = [System.IO.Path]::GetFullPath($path)

if (-not (Test-Path $path)) {
    throw "Could not find: $path"
}

$text = [System.IO.File]::ReadAllText($path)

$salesPattern = '(?ms)\s*if\s*\(!saleSnapshot\.hasData\)\s*\{\s*return\s+const\s+Center\s*\(\s*child:\s*CircularProgressIndicator\(\)\s*\)\s*;\s*\}\s*final\s+sales\s*=\s*saleSnapshot\.data!;'
$salesReplacement = @'

        final sales =
            saleSnapshot.data ?? const <Sale>[];
'@

$paymentPattern = '(?ms)\s*if\s*\(!paymentSnapshot\.hasData\)\s*\{\s*return\s+const\s+Center\s*\(\s*child:\s*CircularProgressIndicator\(\)\s*\)\s*;\s*\}\s*final\s+payments\s*=\s*paymentSnapshot\.data!;'
$paymentReplacement = @'

            final payments =
                paymentSnapshot.data ?? const <CustomerPayment>[];
'@

$newText = [regex]::Replace($text, $salesPattern, $salesReplacement, 1)
if ($newText -eq $text) {
    throw "Could not find the Sales loading-spinner block. No file was changed."
}

$text2 = [regex]::Replace($newText, $paymentPattern, $paymentReplacement, 1)
if ($text2 -eq $newText) {
    throw "Could not find the Payments loading-spinner block. No file was changed."
}

$backup = "$path.before_startup_polish.bak"
Copy-Item -Force $path $backup

[System.IO.File]::WriteAllText(
    $path,
    $text2,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "MomBiz dashboard startup spinner patch applied." -ForegroundColor Green
Write-Host "Backup: $backup"
Write-Host ""
Write-Host "Next: flutter analyze"
