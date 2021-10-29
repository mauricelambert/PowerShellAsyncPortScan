. "$PSScriptRoot\PortScan.ps1"

$scan1=[ScanHost]::New("www.google.com", @(80, 443), 2000)
$scan2=[ScanHost]::New("1.1.1.1", @(80, 443), 2000)
$scan3=[ScanHost]::New("failed.failed.failed.failed", @(45512, 44301), 2000)
$scan4=[ScanHost]::New("failed.failed.failed.failed", @(45512, 44301), 2000)

Write-Host("Scan 1")
$resolve=$scan1.ResolveDns()
$result=$scan1.SyncScanPorts()

Write-Host("Scan 2")
$resolve=$scan2.ResolveDns()
$result=$scan2.AsyncScanPorts()

Write-Host("Scan 3")
$result=$scan3.AsyncScanPorts()

Write-Host("Scan 4")
$resolve=$scan4.ResolveDns()
$result=$scan4.SyncScanPorts()

Write-Host("AsyncScans")
$scans_=@($scan1, $scan2, $scan3, $scan4)
$scans=[ScanAll]::New($scans_, 2000)
$scans=[ScanAll]::New($scans_)
$scans=[ScanAll]::New()

$scans.AddScan($scan1)
$scans.AddScan($scan2)

Write-Host("Results...")
$scans.AsyncScans()
$scan3.ToString()
$scan4.ToString()