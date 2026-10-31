param([string]$Root,[int]$Port=8137,[string]$BasePath='/',[string]$Proxy='')
$ErrorActionPreference='SilentlyContinue'
$mime=@{'.html'='text/html; charset=utf-8';'.htm'='text/html; charset=utf-8';'.js'='application/javascript';'.mjs'='application/javascript';'.css'='text/css';'.json'='application/json';'.wasm'='application/wasm';'.png'='image/png';'.jpg'='image/jpeg';'.jpeg'='image/jpeg';'.gif'='image/gif';'.webp'='image/webp';'.avif'='image/avif';'.svg'='image/svg+xml';'.ico'='image/x-icon';'.mp3'='audio/mpeg';'.ogg'='audio/ogg';'.wav'='audio/wav';'.m4a'='audio/mp4';'.woff'='font/woff';'.woff2'='font/woff2';'.ttf'='font/ttf';'.otf'='font/otf';'.glb'='model/gltf-binary';'.gltf'='model/gltf+json';'.txt'='text/plain';'.mp4'='video/mp4';'.webm'='video/webm'}
$l=New-Object Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
try{$l.Start()}catch{Write-Host "Could not start on port $Port (already running?)";Start-Sleep 5;exit}
Write-Host "Offline site at http://localhost:$Port/  - close this window to stop"
while($l.IsListening){
  $c=$l.GetContext();$res=$c.Response
  try{
    $rel=[Uri]::UnescapeDataString($c.Request.Url.AbsolutePath)
    if($rel -eq '/'){$rel='/index.html'}
    if($BasePath -ne '/' -and $rel.StartsWith($BasePath)){$rel=$rel.Substring($BasePath.Length-1)}
    if($rel.EndsWith('/')){$rel+='index.html'}
    if($rel -match '\.\.'){$res.StatusCode=400}else{
      $local=Join-Path $Root ($rel.TrimStart('/') -replace '/','\')
      if(-not (Test-Path -LiteralPath $local -PathType Leaf)){$alt=Join-Path $Root ('_root'+($rel -replace '/','\'));if(Test-Path -LiteralPath $alt -PathType Leaf){$local=$alt}}
      if(-not (Test-Path -LiteralPath $local -PathType Leaf) -and $Proxy){try{New-Item -ItemType Directory -Force -Path (Split-Path $local)|Out-Null;Invoke-WebRequest -Uri ($Proxy+$rel.TrimStart('/')) -OutFile $local -UseBasicParsing -ErrorAction Stop;Write-Host "[fetched] $rel"}catch{if(Test-Path -LiteralPath $local -PathType Leaf){Remove-Item -LiteralPath $local -Force}}}
      if(Test-Path -LiteralPath $local -PathType Leaf){
        $b=[IO.File]::ReadAllBytes($local);$e=[IO.Path]::GetExtension($local).ToLower()
        $ie=[IO.Path]::GetExtension([IO.Path]::GetFileNameWithoutExtension($local)).ToLower()
        if(($e -eq '.br' -or $e -eq '.gz') -and $ie){if($e -eq '.br'){$res.AddHeader('Content-Encoding','br')}else{$res.AddHeader('Content-Encoding','gzip')};$e=$ie}
        if($mime.ContainsKey($e)){$res.ContentType=$mime[$e]}else{$res.ContentType='application/octet-stream'}
        $res.ContentLength64=$b.Length;$res.OutputStream.Write($b,0,$b.Length)
      }else{$res.StatusCode=404;Write-Host "[missing] $rel"}
    }
  }catch{try{$res.StatusCode=500}catch{}}
  try{$res.OutputStream.Close()}catch{}
}
