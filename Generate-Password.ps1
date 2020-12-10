Function Generate-Password
<#
.Synopsis
   Generate passwords
.EXAMPLE
   Generate-Password -Count 5
.EXAMPLE
   Generate-Password -Count 5 -symbol
#>
{
  param
  (
    [Parameter(Mandatory = $true)]
    [Int]$Count,
    [Parameter(Mandatory = $false )]
    [Switch]$symbol 
  )
  #Region Symbols
  if(!($symbol))
  {
    $PasswordCount = 0
    Do 
    {  
      $path = 'c:\temp\fourlist.txt'
      if (!( Test-Path $path))
      {
        New-Item -ItemType Directory -Path C:\temp\ -force
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Deathjam/Powershell-Scripts/master/fourlist.txt' -OutFile $path 
        Start-Sleep -Seconds 2
      }
      $four = Get-Content -Path $path
      #$symbolarr = @("$", '^', '&', '£', '%')
      #$sym = Get-Random -Maximum $symbolarr
      $first = Get-Random -Maximum  $four
      $second = Get-Random -Maximum $four
      $last = Get-Random -Minimum 100 -Maximum 999 
      $Password = $first+$second+$last
      if($four.Length -gt 3)
      {
        New-Object -TypeName PSObject -Property @{
          Password = -join $Password
        }
      }
      $PasswordCount++
    }
    until ($PasswordCount -eq $Count)
  }
  else 
  {
    $PasswordCount = 0
    Do 
    {  
      $path = 'c:\temp\fourlist.txt'
      if (!( Test-Path $path))
      {
        New-Item -ItemType Directory -Path C:\temp\ -force
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Deathjam/Powershell-Scripts/master/fourlist.txt' -OutFile $path 
        Start-Sleep -Seconds 2
      }
      $four = Get-Content -Path $path
      $symbolarr = @("$", '^', '&', '£', '%')
      $sym = Get-Random -Maximum $symbolarr
      $first = Get-Random -Maximum  $four
      $second = Get-Random -Maximum $four
      $last = Get-Random -Minimum 100 -Maximum 999 
      $Password = $sym+$first+$second+$last
      if($four.Length -gt 3)
      {
        New-Object -TypeName PSObject -Property @{
          Password = -join $Password
        }
      }
      $PasswordCount++
    }
    until ($PasswordCount -eq $Count)
  }  
  #EndRegion Symbols
}
