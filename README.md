# PowerShell Port Scanner

## Description

This "library" performs asynchronous scanning of TCP ports (asynchronism is the fastest solution for port scanning).

## Installation

Download the PortScan.ps1 and develop your script to the same directory (or import PortScan.ps1 with the full path).

## Usage

### Basic

```powershell
. "$PSScriptRoot\PortScan.ps1"

$scan=[ScanHost]::New("example.com", @(80, 443))       # Default timeout 1 second
$scan=[ScanHost]::New("example.com", @(80, 443), 2000) # Custom timeout (2 seconds)

$resolve=$scan.ResolveDns()                            # optional

if ($resolve) {
	$result=$scan.SyncScanPorts()
	# OR
	$result=$scan.AsyncScanPorts()                     # Faster
}

$scan.ToString()                                       # Formated report
```

### Inheritance

Write your class on the end of PortScan.ps1:

```powershell
class ScanWeb: ScanHost {
    ScanDsm([string] $_host) : base($_host, @(80, 443)) {}
}
```

Import and use it in your script:

```powershell
. "$PSScriptRoot\PortScan.ps1"

$scan=[ScanWeb]::New("example.com")
$resolve=$scan.ResolveDns()         # optional

if ($resolve) {
	$result=$scan.SyncScanPorts()
	# OR
	$result=$scan.AsyncScanPorts()  # Faster
}

$scan.ToString()
```

### Multiple scans

```powershell
. "$PSScriptRoot\PortScan.ps1"

$scan1=[ScanWeb]::New("example.com")
$scan2=[ScanHost]::New("example.com", @(80, 443))

$scan_array=@($scan1, $scan2)
$scans=[ScanAll]::New($scan_array)                # Default timeout is 1 second
$scans=[ScanAll]::New($scan_array, 2000)          # Custom timeout (2 seconds)

$scans.AsyncScans()                               # Formated result
```

or

```powershell
. "$PSScriptRoot\PortScan.ps1"

$scan1=[ScanWeb]::New("example.com")
$scan2=[ScanHost]::New("example.com", @(80, 443))

$scan_array=@($scan1, $scan2)
$scans=[ScanAll]::New()

$scans.AddScan($scan1)
$scans.AddScan($scan2)

$scans.AsyncScans()                               # Formated result
```

### Pre-implemented classes

```powershell
[ScanHost]

[ScanAll]

[ScanWeb]
[ScanDevWeb]
[ScanMail]
[ScanWindows]
[ScanLinux]
```

## License
Licensed under the [GPL, version 3](https://www.gnu.org/licenses/).
