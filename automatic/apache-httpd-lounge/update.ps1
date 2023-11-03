Import-Module au

$baseUrl = "https://www.apachelounge.com"
$mostRecentRelease = "$baseUrl/download/"

function global:au_BeforeUpdate { Get-RemoteFiles -NoSuffix }

function global:au_GetLatest {
  $versionRegEx = '(?<=href=").*httpd\-([\d\.]+).*\-win64\-([Vv][Ss]\d{2}).*\.zip(?=")'

  $baseUri = [System.Uri]::new($baseUrl)

  $downloadPage = Invoke-WebRequest -Uri $mostRecentRelease -UseBasicParsing -HttpVersion 2.0 -UserAgent "Chocolatey Auto Update"
  $match = [regex]::match($downloadPage.Content, $versionRegEx)
  $version64 = [version]$match.Groups[1].Value
  $absolutePath64 = $match.Value
  $uri64 = [System.Uri]::new($baseUri, $absolutePath64)

  $versionRegEx = $versionRegEx -replace 'win64', 'win32'
  $match = [regex]::match($downloadPage.Content, $versionRegEx)
  $version32 = [version]$match.Groups[1].Value
  $absolutePath32 = $match.Value
  $uri32 = [System.Uri]::new($baseUri, $absolutePath32)

  if ($version32 -ne $version64) {
    throw "32bit and 64bit version do not match. Please check the update script."
  }

  return @{
    Url32   = $uri32.ToString()
    Url64   = $uri64.ToString()
    Version = $version64
  }
}

function global:au_SearchReplace {
  return @{
    ".\tools\chocolateyInstall.ps1" = @{
      "(?i)(^\s*file\s*=\s*`"[$]toolsDir\\).*"   = "`${1}$($Latest.FileName32)`""
      "(?i)(^\s*file64\s*=\s*`"[$]toolsDir\\).*" = "`${1}$($Latest.FileName64)`""
    }
    ".\legal\VERIFICATION.txt"      = @{
      "(?i)(listed on\s*)\<.*\>" = "`${1}<$releases>"
      "(?i)(32-Bit.+)\<.*\>"     = "`${1}<$($Latest.URL32)>"
      "(?i)(64-Bit.+)\<.*\>"     = "`${1}<$($Latest.URL64)>"
      "(?i)(checksum type:).*"   = "`${1} $($Latest.ChecksumType32)"
      "(?i)(checksum32:).*"      = "`${1} $($Latest.Checksum32)"
      "(?i)(checksum64:).*"      = "`${1} $($Latest.Checksum64)"
    }
  }
}

update -ChecksumFor None
