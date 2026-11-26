param([Parameter(Mandatory=$true)][ValidatePattern('^COM[0-9]+$')][string]$Port)

$ErrorActionPreference = 'Stop'
$serial = [System.IO.Ports.SerialPort]::new($Port,115200)
$serial.ReadTimeout = 350
$serial.NewLine = "`n"
$serial.DtrEnable = $false
$serial.RtsEnable = $false
$udp = [System.Net.Sockets.UdpClient]::new()
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$lastAck = -1000
$remote = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Loopback, 0)
try {
    $udp.Connect([System.Net.IPAddress]::Loopback, 24653)
    $serial.Open()
    Write-Host "Listening on $Port. Keep Suvarna open. Press Ctrl+C to close the bridge."
    while ($serial.IsOpen) {
        try { $line = $serial.ReadLine().Trim() } catch [System.TimeoutException] { continue }
        if ($line -notmatch '^SV1,\d{1,4},\d{1,4},[01],[01],[01],[01]$') { continue }
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($line)
        $null = $udp.Send($bytes, $bytes.Length)
        $acknowledged = $false
        while ($udp.Available -gt 0) {
            if ([System.Text.Encoding]::ASCII.GetString($udp.Receive([ref]$remote)) -eq 'OK') {
                $acknowledged = $true
            }
        }
        if ($acknowledged -and $stopwatch.ElapsedMilliseconds - $lastAck -gt 350) {
            $serial.WriteLine('1')
            $lastAck = $stopwatch.ElapsedMilliseconds
        }
    }
} finally {
    $serial.Dispose()
    $udp.Dispose()
}
