###################
#    Library to scan TCP port in PowerShell.
#    Copyright (C) 2021  Maurice Lambert

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
###################

function AddInListProperty{
    [CmdletBinding()]
	param(
		[Parameter()]
		[PSObject] $Object,
        [Parameter()]
		[PSObject] $Value,
        [Parameter()]
		[string] $attribute
	)

    $temp = [System.Collections.Generic.List[PSObject]]::New()

    foreach($v in $Object.$attribute) {
        $temp.Add($v)
    }

    $temp.Add($Value)

    $Object.$attribute=$temp
}

function AddInteger{
    [CmdletBinding()]
	param(
		[Parameter()]
		[int[]] $list,
        [Parameter()]
		[int] $value
	)

    $temp = [System.Collections.Generic.List[int]]::New()

    foreach($v in $list) {
        $temp.Add($v)
    }

    $temp.Add($Value)
    return $temp
}

class ScannedPort {
    [int]  $port
    [bool] $state

    ScannedPort([int] $port, [bool] $state) {
        $this.port=$port
        $this.state=$state
    }
    
    [string]ToString(){
        if ($this.state) {
            $_state="Open"
        } else {
            $_state="Close"
        }
        return "{0}`t{1}" -f $this.port, $_state
    }
}

class ScanHost {
    [string] $_host
    [int[]]  $ports
    [bool[]] $resolve
    [int]    $timeout = 1000
    hidden [ScannedPort[]] $_ports
    hidden [int[]] $_opened_ports=[System.Collections.ArrayList]::new()
    hidden [System.Net.Sockets.TcpClient[]] $_tcp_clients=[System.Collections.Generic.List[PSObject]]::New()
    
    ScanHost([string] $_host, [int[]] $ports, [int] $timeout) {
        $this._host=$_host
        $this.ports=$ports
        $this.timeout=$timeout
    }
    
    ScanHost([string] $_host, [int[]] $ports) {
        $this._host=$_host
        $this.ports=$ports
    }

    [bool]ResolveDns(){
        try {
            $resolve_ = Resolve-DnsName $this._host
            $this.resolve=$?
            return $this.resolve
        } catch {
            $this.resolve=$false
            return $this.resolve
        }
    }

    [string[]]SyncScanPorts(){
        foreach ($port in $this.ports) {
            [ScannedPort]$_port=[ScannedPort]::new($port, $this.ScanPort($port))
            AddInListProperty -Object $this -Value $_port -attribute "_ports"
        }
        
        return $this._ports
    }

    [System.Net.Sockets.TcpClient[]]StartAll(){
        foreach ($port in $this.ports) {
            $client=$this.StartConnection($port)
            AddInListProperty -Object $this -Value $client -attribute "_tcp_clients"
        }

        return $this._tcp_clients
    }

    [int[]]CloseAll() {
        [int[]]$opened_ports=@()

        foreach($client in $this._tcp_clients) {
            $port=$this.CloseConnection($client)
            if ($port) {
                $opened_ports=AddInteger -list $opened_ports -value $port
            }
        }

        return $opened_ports
    }

    [string[]]GetAsyncPortsStatus() {
        foreach ($port in $this.ports) {
            
            if ($this._opened_ports.Contains($port)) {
                [ScannedPort]$_port=[ScannedPort]::new($port, $true)
            } else {
                [ScannedPort]$_port=[ScannedPort]::new($port, $false)
            }

            AddInListProperty -Object $this -Value $_port -attribute "_ports"
        }
        
        return $this._ports
    }

    [string[]]AsyncScanPorts() {
        $clients=$this.StartAll()

        Start-Sleep -milli $this.timeOut

        $opened_ports=$this.CloseAll()
        $scanResult=$this.GetAsyncPortsStatus()
        
        return $this._ports
    }

    [System.Net.Sockets.TcpClient]StartConnection([int] $port){
        [System.Net.Sockets.TcpClient] $client = New-Object System.Net.Sockets.TcpClient
        $beginConnect = $client.BeginConnect($this._host, $port, $null, $null)
        return $client
    }

    [int]CloseConnection([System.Net.Sockets.TcpClient] $client) {
        $port=$client.Client.RemoteEndPoint.port
        $client.Close()
        return $port
    }

    [bool]ScanPort([int] $port) {
        $client = $this.StartConnection($port)
        
        Start-Sleep -milli $this.timeOut
        $open=$client.Connected
        $client.Close()

        return $open
    }

    [string]ToString() {
        if ($this.resolve -eq $null) {
            $opened="Not tempted to resolve: {0}" -f $this._host
        } elseif ($this.resolve -eq $true) {
            $opened="Successfully resolving: {0}" -f $this._host
        } else {
            return "`nUnable to resolve: {0}" -f $this._host
        }

        $opened+="`n{0}`n`tOpen: " -f $this._host
        $closed="`tClose: "

        foreach ($port in $this._ports) { 
            if ($port.state) {
                $opened+="`n`t`t - $port"
            } else {
                $closed+="`n`t`t - $port"
            }
        }

        return "`n$opened`n`n$closed`n"
    }
}

class ScanAll {
    [ScanHost[]] $scans
    [int]        $timeout = 1000

    ScanAll([ScanHost[]]$scans, [int] $timeout) {
        $this.scans=$scans
        $this.timeout=$timeout
    }

    ScanAll([ScanHost[]]$scans) {
        $this.scans=$scans
    }

    ScanAll() {
        $this.scans=[System.Collections.Generic.List[PSObject]]::New()
    }

    [void]AddScan ([ScanHost]$scan) {
        AddInListProperty -Object $this -Value $scan -attribute "scans"
    }

    [string[]]AsyncScans () {
        [System.Net.Sockets.TcpClient[]]$clients=[System.Collections.Generic.List[PSObject]]::New()

        foreach ($scan in $this.scans) {
            $scan.StartAll()
        }

        Start-Sleep -milli $this.timeOut

        foreach ($scan in $this.scans) {
            $scan.CloseAll()
            $scan.GetAsyncPortsStatus()
        }

        return $this.scans
    }
}

class ScanWeb: ScanHost {
    ScanWeb([string] $_host) : base($_host, @(80, 443)) {}
}

class ScanDevWeb: ScanHost {
    ScanDevWeb([string] $_host) : base($_host, @(80,443,5000,8000,8888)) {}
}

class ScanMail: ScanHost {
    ScanMail([string] $_host) : base($_host, @(25,465,587,110,995,143,220,585,993)) {}
}

class ScanWindows: ScanHost {
    ScanWindows([string] $_host) : base($_host, @(135,137,139,445,49664,49668,49672)) {}
}

class ScanLinux: ScanHost {
    ScanLinux([string] $_host) : base($_host, @(21,22)) {}
}