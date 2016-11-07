#---------------------------------------------------------------------------------------------------------------------------
# Poor Mans server Inventory
#---------------------------------------------------------------------------------------------------------------------------
$date = Get-Date -Format "dd/MM/yyyy HH:mm"

function get-nethost {
  switch -regex (NET.EXE VIEW) { "^\\\\(?<Name>\S+)\s+" {$matches.Name}}
  }

$folderPath = '\\path\to\folder'
#Also edit path on line 595

Remove-Item $folderPath\*.txt
Remove-Item $folderPath\*.html

$rtn = $null

$ADcomputers = (Get-ADComputer -Filter * -SearchBase "ou=mfg,dc=noam,dc=corp,dc=contoso,dc=com" )

ForEach ($ADcomputer in $ADcomputers) {

  echo $ADcomputer.Name | add-content "$folderPath\listall.txt"

  $rtn = Test-Connection -ComputerName $ADcomputer.name -BufferSize 16 -Count 1 -Quiet
  IF($rtn -match ‘TRUE’) 
  {echo $ADcomputer.Name |add-content "$folderPath\liston.txt"}
  else
  {echo $ADcomputer.Name |add-content "$folderPath\listoff.txt"}

}

$ComputerOnList = (get-content $folderPath\liston.txt | Sort-Object )

$ComputerList = (get-content $folderPath\listall.txt | Sort-Object )

$HtmlFilesFolder = "$folderPath"

#if (-not(Test-Path -Path "$HtmlFilesFolder")) {
#   $null = New-Item -Name Images -Path $HtmlFilesFolder -ItemType Directory -Force
#}

Set-Location  $folderPath
#Copy-Item  .\Images -Destination $HtmlFilesFolder -Recurse -Force

function Get-WindowsKey {
  ## function to retrieve the Windows Product Key from any PC
  ## by Jakob Bindslet (jakob@bindslet.dk)
  param ($targets = ".")
  $hklm = 2147483650
  $regPath = "Software\Microsoft\Windows NT\CurrentVersion"
  $regValue = "DigitalProductId"
  Foreach ($target in $targets) {
    $productKey = $null
    $win32os = $null
    $wmi = [WMIClass]"\\$target\root\default:stdRegProv"
    $data = $wmi.GetBinaryValue($hklm,$regPath,$regValue)
    $binArray = ($data.uValue)[52..66]
    $charsArray = "B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9"
    ## decrypt base24 encoded binary data
    For ($i = 24; $i -ge 0; $i--) {
      $k = 0
      For ($j = 14; $j -ge 0; $j--) {
        $k = $k * 256 -bxor $binArray[$j]
        $binArray[$j] = [math]::truncate($k / 24)
        $k = $k % 24
      } 
      $productKey = $charsArray[$k] + $productKey
      If (($i % 5 -eq 0) -and ($i -ne 0)) {
        $productKey = "-" + $productKey
      } 
    } 
    $win32os = Get-WmiObject Win32_OperatingSystem -computer $target 
    $obj = New-Object Object
    $obj | Add-Member Noteproperty Computer -value $target
    $obj | Add-Member Noteproperty Caption -value $win32os.Caption
    $obj | Add-Member Noteproperty CSDVersion -value $win32os.CSDVersion
    $obj | Add-Member Noteproperty OSArch -value $win32os.OSArchitecture
    $obj | Add-Member Noteproperty BuildNumber -value $win32os.BuildNumber
    $obj | Add-Member Noteproperty RegisteredTo -value $win32os.RegisteredUser
    $obj | Add-Member Noteproperty ProductID -value $win32os.SerialNumber
    $obj | Add-Member Noteproperty ProductKey -value $productkey
    $obj
  }
} 

Function Get-Monitor {
  <#

      .SYNOPSIS
      This powershell function gets information about the monitors attached to any computer. It uses EDID information provided by WMI. If this value is not specified it pulls the monitors of the computer that the script is being run on.

      .DESCRIPTION
      The function begins by looping through each computer specified. For each computer it gets a litst of monitors.
      It then gets all of the necessary data from each monitor object and converts and cleans the data and places it in a custom PSObject. It then adds
      the data to an array. At the end the array is displayed.

      .PARAMETER ComputerName
      Use this to specify the computer(s) which you'd like to retrieve information about monitors from.

      .EXAMPLE
      PS C:/> Get-Monitor.ps1 -ComputerName SSL1-F1102-1G2Z

      Manufacturer Model    SerialNumber AttachedComputer
      ------------ -----    ------------ ----------------
      HP           HP E241i CN12345678   SSL1-F1102-1G2Z 
      HP           HP E241i CN91234567   SSL1-F1102-1G2Z 
      HP           HP E241i CN89123456   SSL1-F1102-1G2Z

      .EXAMPLE
      PS C:/> $Computers = @("SSL7-F108F-9D4Z","SSL1-F1102-1G2Z","SSA7-F1071-0T7F")
      PS C:/> Get-Monitor.ps1 -ComputerName $Computers

      Manufacturer Model      SerialNumber AttachedComputer
      ------------ -----      ------------ ----------------
      HP           HP LA2405x CN12345678   SSL7-F108F-9D4Z
      HP           HP E241i   CN91234567   SSL1-F1102-1G2Z 
      HP           HP E241i   CN89123456   SSL1-F1102-1G2Z 
      HP           HP E241i   CN78912345   SSL1-F1102-1G2Z
      HP           HP ZR22w   CN67891234   SSA7-F1071-0T7F

  #>

  [CmdletBinding()]
  PARAM (
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [String[]]$ComputerName = $env:ComputerName
  )
  
  #List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for translating later down.
  $ManufacturerHash = @{ 
    "AAC" =	"AcerView";
    "ACR" = "Acer";
    "AOC" = "AOC";
    "AIC" = "AG Neovo";
    "APP" = "Apple Computer";
    "AST" = "AST Research";
    "AUO" = "Asus";
    "BNQ" = "BenQ";
    "CMO" = "Acer";
    "CPL" = "Compal";
    "CPQ" = "Compaq";
    "CPT" = "Chunghwa Pciture Tubes, Ltd.";
    "CTX" = "CTX";
    "DEC" = "DEC";
    "DEL" = "Dell";
    "DPC" = "Delta";
    "DWE" = "Daewoo";
    "EIZ" = "EIZO";
    "ELS" = "ELSA";
    "ENC" = "EIZO";
    "EPI" = "Envision";
    "FCM" = "Funai";
    "FUJ" = "Fujitsu";
    "FUS" = "Fujitsu-Siemens";
    "GSM" = "LG Electronics";
    "GWY" = "Gateway 2000";
    "HEI" = "Hyundai";
    "HIT" = "Hyundai";
    "HSL" = "Hansol";
    "HTC" = "Hitachi/Nissei";
    "HWP" = "HP";
    "IBM" = "IBM";
    "ICL" = "Fujitsu ICL";
    "IVM" = "Iiyama";
    "KDS" = "Korea Data Systems";
    "LEN" = "Lenovo";
    "LGD" = "Asus";
    "LPL" = "Fujitsu";
    "MAX" = "Belinea"; 
    "MEI" = "Panasonic";
    "MEL" = "Mitsubishi Electronics";
    "MS_" = "Panasonic";
    "NAN" = "Nanao";
    "NEC" = "NEC";
    "NOK" = "Nokia Data";
    "NVD" = "Fujitsu";
    "OPT" = "Optoma";
    "PHL" = "Philips";
    "REL" = "Relisys";
    "SAN" = "Samsung";
    "SAM" = "Samsung";
    "SBI" = "Smarttech";
    "SGI" = "SGI";
    "SNY" = "Sony";
    "SRC" = "Shamrock";
    "SUN" = "Sun Microsystems";
    "SEC" = "Hewlett-Packard";
    "TAT" = "Tatung";
    "TOS" = "Toshiba";
    "TSB" = "Toshiba";
    "VSC" = "ViewSonic";
    "ZCM" = "Zenith";
    "UNK" = "Unknown";
    "_YV" = "Fujitsu";
    }
	  
  
  #Takes each computer specified and runs the following code:
  ForEach ($Computer in $ComputerName) {
  
    #Grabs the Monitor objects from WMI
    $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $Computer -ErrorAction SilentlyContinue
	
    #Creates an empty array to hold the data
    $Monitor_Array = @()
	
	
    #Takes each monitor object found and runs the following code:
    ForEach ($Monitor in $Monitors) {
	  
      #Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
      If ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName) -ne $null) {
        $Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
      } else {
        $Mon_Model = $null
      }
      $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
      $Mon_Attached_Computer = ($Monitor.PSComputerName).Replace("$([char]0x0000)","")
      $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
	  
      #Filters out "non monitors". Place any of your own filters here. These two are all-in-one computers with built in displays. I don't need the info from these.
      If ($Mon_Model -like "*800 AIO*" -or $Mon_Model -like "*8300 AiO*") {Break}
	  
      #Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
      $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
      If ($Mon_Manufacturer_Friendly -eq $null) {
        $Mon_Manufacturer_Friendly = $Mon_Manufacturer
      }
	  
      #Creates a custom monitor object and fills it with 4 NoteProperty members and the respective data
      $Monitor_Obj = [PSCustomObject]@{
        Manufacturer     = $Mon_Manufacturer_Friendly
        Model            = $Mon_Model
        SerialNumber     = $Mon_Serial_Number
        AttachedComputer = $Mon_Attached_Computer
      }
	  
      #Appends the object to the array
      $Monitor_Array += $Monitor_Obj

    } #End ForEach Monitor
  
    #Outputs the Array
    $Monitor_Array
	
  } #End ForEach Computer
}

Function Get-Uptime {
  Param(
    [Parameter(Position = 0,ValuefromPipeline = $true)][array]$computername = $env:COMPUTERNAME
  )

  @(foreach ($cpu in $computername) 
    {
      $objResult = '' | Select-Object -Property ComputerName, Username, Uptime, LastReboot
      $objOS = Get-WmiObject -ComputerName $cpu -Class Win32_OperatingSystem -Property CSName, LastBootUpTime
      $objCS = Get-WmiObject -ComputerName $cpu -Class Win32_ComputerSystem -Property UserName
      $now = Get-Date
      $then = $objOS.ConvertToDateTime($objOS.LastBootUpTime)
      $uptime = $now - $then
      $d = $uptime.days
      $h = $uptime.hours
      $m = $uptime.Minutes
      $s = $uptime.Seconds
      $objResult.ComputerName = $objOS.CSName
      $objResult.Username = $objCS.UserName
      $objResult.Uptime = "${d}d ${h}h ${m}m ${s}s"
      $objResult.LastReboot = $then
      $objResult
  }) #| Format-Table -AutoSize
}
## -------------------------------------------------------------------------------------------------------------------------------------
## ----------------------------------------------------------------------- SCRIPT ------------------------------------------------------

#region Head Style
$head = @"
<style>
#header {
	color:Black;
	text-align:center;
	padding:5px;
	font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
}
#infoname {
	color:Black;
	text-align:center;
	padding:5px;
	font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
}
#nav {
	line-height:30px;
	background-color:#E6E6E6;
	height:500px;
	width:Auto;
	float:left;
	padding:5px;
	font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;	      
}
#section {
	width:350px;
	float:left;
	padding:10px;
	font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;	 	 
}
#footer {
	background-color:black;
	color:white;
	clear:both;
	text-align:center;
	padding:5px;
	font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;	 	 
}

TH{
   width:100%; 
   font-size:0.9em;
   color:White;
   border-width:1px;
   padding: 2px;
   border-style: solid;
   border-color: #ADADAD;
   background-color:#666666};
   font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;

TD {
	width:100%;
	border-width: 1px;
	padding: 2px;
	border-style: solid;
	border-color: black;
	background-color: White};
	font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
</style>

<!-- Table Style even and odd -->
<style type="text/css">
	.TFtable{
		border-collapse:collapse;
		width: 100%;
		table-layout: auto;
		white-space: nowrap;
	}
	.TFtable td{ 
		padding:5px; border:#ADADAD 1px solid;
	}
	/* provide some minimal visual accomodation for IE8 and below */
	.TFtable tr{
		background: #CFCFCF;
	}
	/*  Define the background color for all the ODD background rows  */
	.TFtable tr:nth-child(odd){ 
		background: #CFCFCF;
	}
	/*  Define the background color for all the EVEN background rows  */
	.TFtable tr:nth-child(even){
		background: #FFFFFF;
	}
</style>


<!-- Navigation bar -->
<style>
/* @import url(http://fonts.googleapis.com/css?family=Lato:300,400,700); */
/* Starter CSS for Flyout Menu */
#cssmenu,
#cssmenu ul,
#cssmenu ul li,
#cssmenu ul ul {
  float:left;
  list-style: none;
  margin: 0;
  padding: 0;
  border: 0;
  font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
}
#cssmenu ul {
  position: relative;
  z-index: 597;
  float: left;
}
#cssmenu ul li {
  float: left;
  min-height: 1px;
  line-height: 1em;
  vertical-align: middle;
}
#cssmenu ul li.hover,
#cssmenu ul li:hover {
  position: relative;
  z-index: 599;
  cursor: default;
}
#cssmenu ul ul {
  margin-top: 1px;
  visibility: hidden;
  position: absolute;
  top: 1px;
  left: 99%;
  z-index: 598;
  width: 100%;
}
#cssmenu ul ul li {
  float: none;
}
#cssmenu ul ul ul {
  top: 1px;
  left: 99%;
}
#cssmenu ul li:hover > ul {
  visibility: visible;
}
#cssmenu ul li {
  float: none;
}
#cssmenu ul ul li {
  font-weight: normal;
}
/* Custom CSS Styles */
#cssmenu {
  font-family: font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
  font-size: 18px;
  width: 600px;
}
#cssmenu ul a,
#cssmenu ul a:link,
#cssmenu ul a:visited {
  display: block;
  color: #848889;
  text-decoration: none;
  font-weight: 300;
}
#cssmenu > ul {
  float: none;
}
#cssmenu ul {
  background: #fff;
}
#cssmenu > ul > li {
  border-left: 3px solid #d7d8da;
}
#cssmenu > ul > li > a {
  padding: 10px 20px;
}
#cssmenu > ul > li:hover {
  border-left: 3px solid #3dbd99;
}
#cssmenu ul li:hover > a {
  color: #3dbd99;
}
#cssmenu > ul > li:hover {
  background: #f6f6f6;
}
/* Sub Menu */
#cssmenu ul ul a:link,
#cssmenu ul ul a:visited {
  font-weight: 400;
  font-size: 14px;
}
#cssmenu ul ul {
  width: 180px;
  background: none;
  border-left: 20px solid transparent;
}
#cssmenu ul ul a {
  padding: 8px 0;
  border-bottom: 1px solid #eeeeee;
}
#cssmenu ul ul li {
  padding: 0 20px;
  background: #fff;
}
#cssmenu ul ul li:last-child {
  border-bottom: 3px solid #d7d8da;
  padding-bottom: 10px;
}
#cssmenu ul ul li:first-child {
  padding-top: 10px;
}
#cssmenu ul ul li:last-child > a {
  border-bottom: none;
}
#cssmenu ul ul li:first-child:after {
  content: '';
  display: block;
  width: 0;
  height: 0;
  position: absolute;
  left: -20px;
  top: 13px;
  border-left: 10px solid transparent;
  border-right: 10px solid #fff;
  border-bottom: 10px solid transparent;
  border-top: 10px solid transparent;
}
} 
</style>
"@
#endregion Head Style
$workingcomputers = @()
$nonresponding = @()

#Create Folder for every Computer
foreach ($pc in $ComputerList) {
    if (-not(Test-Path -Path "$HtmlFilesFolder\$pc")) {
       $null = New-Item -Name $pc -Path $HtmlFilesFolder -ItemType Directory -Force
    }
}

foreach ($Computer in $ComputerOnList) {

  write-host $computer
  $workingcomputers += $Computer

  #region Main Folder Path
  $ComputerFolderPath = "{0}\{1}" -f $HtmlFilesFolder, $Computer
  #endregion Main Folder Path
  $title = "Status of $Computer"

  #region Individual html file Path
  #if (-not(Test-Path -Path "$HtmlFilesFolder\$Computer")) {
  #   $null = New-Item -Name $Computer -Path $HtmlFilesFolder -ItemType Directory -Force
  #}

  #$indexFile = 'Index.html'
  #$indexFileNamePath = Join-Path -Path $ComputerFolderPath -ChildPath $indexFile

  #$HardWareFile =  $Computer + '-Hardware.html'
  $HardWareFile =  'Index.html'
  $HarWareNamePath = Join-Path -Path $ComputerFolderPath -ChildPath $HardWareFile

  $OSFile =  $Computer + '-OS.html'
  $OSFileNamePath = Join-Path -Path $ComputerFolderPath -ChildPath $OSFile

  $DiskFile =  $Computer + '-Disk.html'
  $DiskFileNamePath = Join-Path -Path $ComputerFolderPath -ChildPath $DiskFile

  $ServicesFile =  $Computer + '-Services.html'
  $ServicesFileNamePath = Join-Path -Path $ComputerFolderPath -ChildPath $ServicesFile

  #endregion Individual html file Path

  #region Indexing for Nextbutton and previousbutton
  $Index = [array]::IndexOf($ComputerList, $computer) 


  #$previous = $ComputerList[($Index - 1)]
  #$previousbutton = "..\{0}\{1}-Hardware.html" -f $Computerlist[$Index - 1], $Computerlist[$Index - 1]
  $previousbutton = "..\{0}\Index.html" -f $Computerlist[$Index - 1], $Computerlist[$Index - 1]


  #$Next = $ComputerList[($Index + 1)]
  #if (($ComputerList.count - 1) -eq $Index) {
  #	$Nextbutton = "..\{0}\{1}-Hardware.html" -f $Computerlist[0], $Computerlist[0]
  #}
  #else {
  #	$Nextbutton = "..\{0}\{1}-Hardware.html" -f $Computerlist[$Index + 1], $Computerlist[$Index + 1]
  #}

  if (($ComputerList.count - 1) -eq $Index) {
    $Nextbutton = "..\{0}\Index.html" -f $Computerlist[0], $Computerlist[0]
  }
  else {
    $Nextbutton = "..\{0}\Index.html" -f $Computerlist[$Index + 1], $Computerlist[$Index + 1]
  }
  ##endregion Indexing for Nextbutton and previousbutton



  #region navigation and footer
  $Nav = @"
<div id='cssmenu'>
<ul>
   <li><a href="./$HardWareFile"><span>HARDWARE</span></a></li>
   <li class='active has-sub'><a href="./$OSFile"><span>Operating System</span></a></li>
   <li><a href=./$DiskFile><span>Storage</span></a></li>
   <li><a href=./$ServicesFile><span>Services</span></a></li>
</ul>
</div>
"@

  $Footer = @"
<div id="footer">



</div>
"@  
  #endregion navigation and footer

  #region Header button
  $Header = @"
<div id="header">
<p>
<a href="//path/to/server/Index.html">
  <img src="..\HomeButton.png" alt="Home" style="width:70px;height:70px;border:0;align="middle";;margin: 0px 0px 30px 30px;">
</a>
<a href="$previousbutton">
  <img src="..\Button-Previous-icon.png" alt="Previous" style="width:70px;height:70px;border:0;align="middle";margin: 0px 0px 30px 30px;">
</a> 
<a href="..\Index.html">
  <img src="..\Inventory-Button.png" alt="Inventory" style="width:70px;height:70px;border:0;align="middle";;margin: 0px 0px 30px 30px;">
</a>
<a href=$Nextbutton>
  <img src="..\Button-Next-icon.png" alt="Next" style="width:70px;height:70px;border:0;align="middle";;margin: 0px 0px 30px 30px;">
</a>

</p>
</div>
"@


  $infoname = @"
<div id ="infoname">
<h1><a href='rdp://$computer`:3389'>$Computer Information</a><br/></h1>
Generated: $date
</div> 
"@
  #endregion Header button

  #region Basic index File
  if (-not(Test-Path -Path $folderPath\basic-Index.html)) {
    $BasicIndex = $Header + $Footer  
    ConvertTo-Html -Body $BasicIndex -Head $head | Out-File $folderPath\basic-Index.html
  }
  #endregion Basic index File
   
  #region HardwareInfo   
  $BiosInfo = Get-WmiObject win32_bios -ComputerName $Computer 

  $HardwareInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer 
  $ProcessorInfo = Get-WmiObject -Class Win32_Processor -ComputerName $Computer 

  $DIMMSlots = Get-WmiObject -Class win32_PhysicalMemoryArray -ComputerName $Computer 
  $DIMMRAMs = Get-WmiObject -Class win32_PhysicalMemory -ComputerName $Computer 

  $NicInfo = Get-WmiObject -Class win32_networkadapter -ComputerName $Computer -Filter "PhysicalAdapter='True'" 

  #Monitors
  $Monitorsinfo = Get-Monitor -ComputerName $Computer 
    if ($Monitorsinfo)
    { 
        $MonitorsObj0 = New-Object PSObject
        $MonitorsObj0 | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $Monitorsinfo.Manufacturer[0] 
        $MonitorsObj0 | Add-Member -MemberType NoteProperty -Name Model -Value $Monitorsinfo.Model[0] 
        $MonitorsObj0 | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $Monitorsinfo.SerialNumber[0] 
        $MonitorsObjObjHTML0 = ($MonitorsObj0 | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'

        $MonitorsObj1 = New-Object PSObject
        $MonitorsObj1 | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $Monitorsinfo.Manufacturer[1] 
        $MonitorsObj1 | Add-Member -MemberType NoteProperty -Name Model -Value $Monitorsinfo.Model[1] 
        $MonitorsObj1 | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $Monitorsinfo.SerialNumber[1] 
        $MonitorsObjObjHTML1 = ($MonitorsObj1 | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'
    }
    else
    {
        $MonitorsObj0 = New-Object PSObject
        $MonitorsObj0 | Add-Member -MemberType NoteProperty -Name Manufacturer -Value "No Monitor"  
        $MonitorsObjObjHTML0 = ($MonitorsObj0 | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'  
    }

  #Motherboard
  $MotherBoxObj = New-Object PSObject
  $MotherBoxObj | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $HardwareInfo.Name
  $MotherBoxObj | Add-Member -MemberType NoteProperty -Name Model -Value $HardwareInfo.Model
  $MotherBoxObj | Add-Member -MemberType NoteProperty -Name "Serial Number" -Value $BiosInfo.SerialNumber
  $MotherBoxObjHTML = ($MotherBoxObj | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'

  #Processor
  $ProcObj =  New-Object PSObject
  $ProcObj | Add-Member -MemberType NoteProperty -Name Processor -Value $ProcessorInfo.Name
  $ProcObj | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $ProcessorInfo.Manufacturer
  $ProcObj | Add-Member -MemberType NoteProperty -Name "Socket Designation" -Value $ProcessorInfo.SocketDesignation
  $ProcObj | Add-Member -MemberType NoteProperty -Name "L2 Cache" -Value $ProcessorInfo.L2CacheSize
  $ProcObj | Add-Member -MemberType NoteProperty -Name "L3 Cache" -Value $ProcessorInfo.L3CacheSize
  $ProcObj | Add-Member -MemberType NoteProperty -Name "Max Clock Speed" -Value $ProcessorInfo.MaxClockSpeed
  $ProcObj | Add-Member -MemberType NoteProperty -Name "Current Clock Speed" -Value $ProcessorInfo.CurrentClockSpeed
  $ProcObj | Add-Member -MemberType NoteProperty -Name "Cores" -Value $ProcessorInfo.NumberOfCores
  $ProcObj | Add-Member -MemberType NoteProperty -Name "Logical Processors" -Value $ProcessorInfo.NumberOfLogicalProcessors
  $ProcObj | Add-Member -MemberType NoteProperty -Name "Virtulization Enabled" -Value $ProcessorInfo.VirtualizationFirmwareEnabled
  $ProcObjHTML = ($ProcObj | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'

  #Physical Memory slots
  $MemoryObj = New-Object PSObject
  $MemoryObj | Add-Member -MemberType NoteProperty -Name "Installed Memory" -Value ("{0:n2} GB" -f ($HardwareInfo.TotalPhysicalMemory / 1GB))
  $MemoryObj | Add-Member -MemberType NoteProperty -Name "Total Supported Max Memory" -Value ("{0:n2} GB" -f ($DIMMSlots.MaxCapacity / 1MB))
  $MemoryObj | Add-Member -MemberType NoteProperty -Name "DIMM Slots" -Value $DIMMSlots.MemoryDevices
  $MemoryObj | Add-Member -MemberType NoteProperty -Name "Filled Slots" -Value $DIMMRAMs.Count
  $MemoryObjHTML = ($MemoryObj | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'

  #Physical Memory -as table
  $DIMMReport = @()
  foreach ($Dimm in $DIMMRAMs) {
    $RamObj = New-Object PSObject
    $RamObj | Add-Member -MemberType NoteProperty -Name "Memory Tag" -Value $DIMM.tag
    $RamObj | Add-Member -MemberType NoteProperty -Name "Memory Serial" -Value $DIMM.SerialNumber
    $RamObj | Add-Member -MemberType NoteProperty -Name "Memory Speed" -Value $DIMM.Speed
    $RamObj | Add-Member -MemberType NoteProperty -Name "Memory GB" -Value ("{0:n2} GB" -f ($DIMM.Capacity / 1GB))
    $RamObj | Add-Member -MemberType NoteProperty -Name "DIMM Label" -Value $DIMM.BankLabel
    $RamObj | Add-Member -MemberType NoteProperty -Name "DIMM Location" -Value $DIMM.DeviceLocator
    $RamObj | Add-Member -MemberType NoteProperty -Name "Memory PartNumber" -Value $DIMM.PartNumber
    $DIMMReport += $RamObj
  }
  $DIMMReportHTML = ($DIMMReport | ConvertTo-Html -Fragment) -replace '<table>', '<table class="TFtable">'

  $NICreport = @()
  #Physical Nic Info as table
  foreach ($nic in $NicInfo) {
    $NICObj = New-Object PSObject
    $NICObj | Add-Member -MemberType NoteProperty -Name "Adapter Name" -Value $nic.Name
    $NICObj | Add-Member -MemberType NoteProperty -Name "Drivers" -Value $nic.ServiceName
    $NICObj | Add-Member -MemberType NoteProperty -Name "Device ID" -Value $nic.DeviceID
    $NICObj | Add-Member -MemberType NoteProperty -Name "Speed MB" -Value ("{0:n2} MB" -f ($nic.Speed / 1MB))
    $NICObj | Add-Member -MemberType NoteProperty -Name "IPAddress" -Value ($NICIP.IPAddress[0] | Out-String)
    $NICObj | Add-Member -MemberType NoteProperty -Name "MAC Address" -Value $nic.MACAddress
    $NICObj | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value $nic.Manufacturer
    $NICObj | Add-Member -MemberType NoteProperty -Name "Product Name" -Value $nic.ProductName 
    $NICReport +=$NICObj
  }
  $NicObjHTML = ($NICReport | ConvertTo-Html -Fragment) -replace '<table>', '<table class="TFtable">'

  #HDD Info
  $PhysicalDiskInfo = Get-WmiObject Win32_DiskDrive -ComputerName $Computer
  $PhysicalDiskobjReport = @()
  foreach ($PhysicalDisk in $PhysicalDiskInfo) {
    $PhysicalDiskobj =  New-Object PSObject
    $PhysicalDiskobj | Add-Member -MemberType NoteProperty -Name Name -Value $PhysicalDisk.Name
    $PhysicalDiskobj | Add-Member -MemberType NoteProperty -Name Model -Value $PhysicalDisk.Model
    $PhysicalDiskobj | Add-Member -MemberType NoteProperty -Name Size -Value ("{0:N2} GB" -f ($PhysicalDisk.Size / 1GB))
    $PhysicalDiskobj | Add-Member -MemberType NoteProperty -Name "SerialNumber" -Value $PhysicalDisk.SerialNumber
    $PhysicalDiskobjReport += $PhysicalDiskobj
  }

  $PhysicalDiskHTML = ($PhysicalDiskobjReport | ConvertTo-Html -Fragment) -replace '<table>', '<table class="TFtable">'

  $HardwareSection = @"
<div id="section">
<h3>Monitors</h3>
<p>
$MonitorsObjObjHTML0 ----- $MonitorsObjObjHTML1
</p>
<h3>MotherBoard</h3>
<p>
$MotherBoxObjHTML
</p>
<h3>Processor</h3>
<p>
$ProcObjHTML
</p>
<h3>DIMM Slots</h3>
<p>
$MemoryObjHTML
</p>
<h3>Installed Memory</h3>
<p>
$DIMMReportHTML
</p>
<h3>Network Adapters</h3>
<p>
$NicObjHTML
</p>
<h3>Physical Disks</h3>
<p>
$PhysicalDiskHTML
</p>
</div>
"@

  $HWbody = $Header + $infoname + $Nav + $HardwareSection + $Footer  
  ConvertTo-Html -Body $HWbody -Head $head | Out-File $HarWareNamePath -Force
  #endregion Hardware Info

  #region OS info
  $OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer 
  $OSKey = Get-WindowsKey -targets $Computer 
  $OSUptime = Get-Uptime -computername $Computer 
  $NicIPinfo = Get-WmiObject win32_NetworkAdapterConfiguration -ComputerName $Computer -Filter "IPEnabled='True'" 
  $OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer 
  $OSKey = Get-WindowsKey -targets $Computer
  $OSUptime = Get-Uptime -computername $Computer 
  $NicIPinfo = Get-WmiObject win32_NetworkAdapterConfiguration -ComputerName $Computer -Filter "IPEnabled='True'" 

  ##Operating System -as list
  $OSobj =  New-Object PSObject
  $OSObj | Add-Member -MemberType NoteProperty -Name "Operating System" -Value $OSInfo.Caption
  $OSObj | Add-Member -MemberType NoteProperty -Name "Build Number" -Value $OSInfo.BuildNumber
  $OSobj | Add-Member -MemberType NoteProperty -Name "Product Key" -Value $OSKey.ProductKey
  $OSObj | Add-Member -MemberType NoteProperty -Name "Computer Name" -Value $OSInfo.CSName
  $OSObj | Add-Member -MemberType NoteProperty -Name "OS Install Date" -Value $OSInfo.ConverttoDateTime($OSInfo.InstallDate)
  $OSObj | Add-Member -MemberType NoteProperty -Name "Last Boot Time" -Value $OSInfo.ConverttoDateTime($OSInfo.LastBootUpTime)
  $OSObj | Add-Member -MemberType NoteProperty -Name "Uptime" -Value $OSUptime.Uptime | Out-String
  $OSObj | Add-Member -MemberType NoteProperty -Name "32 / 64 Bit" -Value $OSInfo.OSArchitecture 
  $OSObj | Add-Member -MemberType NoteProperty -Name "Service Pack" -Value $OSInfo.ServicePackMajorVersion
  $OSObj | Add-Member -MemberType NoteProperty -Name "Windows Directory" -Value $OSInfo.WindowsDirectory
  $OSObj | Add-Member -MemberType NoteProperty -Name "DNS HostName" -Value $HardwareInfo.DNSHostName 
  $OSObj | Add-Member -MemberType NoteProperty -Name "Logged on User" -Value $HardwareInfo.UserName
  $OSObj | Add-Member -MemberType NoteProperty -Name "Domain" -Value $HardwareInfo.Domain
  $OSObjHTML = ($OSObj | ConvertTo-Html -Fragment -As List) -replace '<table>', '<table class="TFtable">'
	

  $NicIPReport = @()
  #Network IP info
  foreach ($nicip in $NicIPinfo) {
    $NICIPobj =  New-Object PSObject
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "NIC Adapter" -Value $NICIP.Description
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "Index" -Value $NICIP.Index
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "DHCP" -Value $NICIP.DHCPEnabled
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "IPAddress" -Value ($NICIP.IPAddress[0] | Out-String)
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "Gateway" -Value ($NICIP.DefaultIPGateway | Out-String)  
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "DNS IP" -Value ($NICIP.DNSServerSearchOrder | Out-String)
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "MacAddress" -Value $NICIP.MACAddress
    $NICIPobj | Add-Member -MemberType NoteProperty -Name "Nic Name" -Value ($NicInfo | where {$_.Index -match $nicip.index} | select -ExpandProperty NetConnectionID)
    $NicIPReport += $NICIPobj
  }
  $NICIPReportHTML = ($NicIPReport | ConvertTo-Html -Fragment) -replace '<table>', '<table class="TFtable">'


  $OSSection = @"
<div id="section">
<h2>Operating System</h2>
<p>
$OSObjHTML
</p>
<h2>IP Address</h2>
<p>
$NICIPReportHTML
</p>
</div>
"@

  $OSbody = $Header + $infoname + $Nav + $OSSection + $Footer  
  ConvertTo-Html -Body $OSbody -Head $head | Out-File $OSFileNamePath
  #endregion OS info

  #region Disk Info
  $Logicaldiskreport = @()
  $LogicalDiskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $computer
  foreach ($LogicalDisk in $LogicalDiskInfo) {
    $LogicalDiskObj = New-Object PSObject
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name Name -Value $LogicalDisk.Name
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name Description -Value $LogicalDisk.Description
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name "Drive Type" -Value $LogicalDisk.DriveType
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name "File System" -Value $LogicalDisk.FileSystem
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name "Total Space" -Value ("{0:n2} MB" -f ($LogicalDisk.Size / 1GB))
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name "Free Space" -Value ("{0:n2} MB" -f ($LogicalDisk.FreeSpace / 1GB))
    $LogicalDiskObj | Add-Member -MemberType NoteProperty -Name "Volume Name" -Value $LogicalDisk.VolumeName
    $Logicaldiskreport += $LogicalDiskObj
  }
  $LogicaldiskHTML = ($Logicaldiskreport | ConvertTo-Html -Fragment) -replace '<table>', '<table class="TFtable">'
  
  $StorageSection = @"
<div id="section">
<h2>Storage Drives</h2>
<p>
$LogicaldiskHTML
</p>
</div>
"@ 

  $Storagebody = $Header + $infoname + $Nav + $StorageSection + $Footer  
  ConvertTo-Html -Body $Storagebody -Head $head | Out-File $DiskFileNamePath
  #endregion Disk Info

  #region services Info
  $ServiceReport =@()
  $ServiceInfo =  Get-WmiObject win32_Service -ComputerName $computer | Sort-Object State, StartMode
  Foreach ($Service in $ServiceInfo) {
    $ServiceObj = New-Object PSObject
    $serviceObj | Add-Member -Name DisplayName -MemberType NoteProperty -Value $Service.DisplayName
    $serviceObj | Add-Member -Name Name -MemberType NoteProperty -Value $Service.Name
    $serviceObj | Add-Member -Name StartMode -MemberType NoteProperty -Value $Service.StartMode
    $serviceObj | Add-Member -Name Started -MemberType NoteProperty -Value $Service.Started
    $serviceObj | Add-Member -Name State -MemberType NoteProperty -Value $Service.State
    $ServiceReport += $serviceObj
  }
  $ServicesHTML = ($ServiceReport  | ConvertTo-Html -Fragment) -replace '<table>', '<table class="TFtable">'
  $ServiceSection = @"
<div id="section">
<h2>Services</h2>
<p>
$ServicesHTML
</p>
</div>
"@ 

  $Servicesbody = $Header + $infoname + $Nav + $ServiceSection + $Footer  
  ConvertTo-Html -Body $Servicesbody -Head $head | Out-File $ServicesFileNamePath
}
#endregion services Info

$workingReport = @()
#ForEach ($working in $workingcomputers) {
ForEach ($working in $ComputerList) {
  $rtn = Test-Connection -ComputerName $working -BufferSize 16 -Count 1 -Quiet
  IF($rtn -match ‘TRUE’) {
        $workingObj = "<li></p><a href=./$working/Index.html>$working</a></p></li>"
        }
        else {
        $workingObj = "<li></p><a href=./$working/Index.html>$working - OFFLINE</a></p></li>"
        }
        $workingReport += $workingObj

  #Create basic index.html for computers if not running
  if (-not(Test-Path -Path $folderPath\$working\Index.html))
    {
        Copy-Item -Path $folderPath\basic-Index.html -Destination $folderPath\$working\Index.html -Force
    }
}

$invhead = @"
<style>
body {
	background-repeat: no-repeat;
	background-position: right top;
	margin-right: 200px;
	background-attachment: fixed;
}
/* @import url(http://fonts.googleapis.com/css?family=Lato:300,400,700); */
/* Starter CSS for Flyout Menu */
#invlist,
#invlist ul,
#invlist ul li,
#invlist ul ul {
  float:left;
  list-style: none;
  margin: 0;
  padding: 0;
  border: 0;
  font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
}
#invlist ul {
  position: relative;
  z-index: 597;
  float: left;
}
#invlist ul li {
  float: left;
  min-height: 1px;
  line-height: 1em;
  vertical-align: middle;
}
#invlist ul li.hover,
#invlist ul li:hover {
  position: relative;
  z-index: 599;
  cursor: default;
}
#invlist ul ul {
  margin-top: 1px;
  visibility: hidden;
  position: absolute;
  top: 1px;
  left: 99%;
  z-index: 598;
  width: 100%;
}
#invlist ul ul li {
  float: none;
}
#invlist ul ul ul {
  top: 1px;
  left: 99%;
}
#invlist ul li:hover > ul {
  visibility: visible;
}
#invlist ul li {
  float: none;
}
#invlist ul ul li {
  font-weight: normal;
}
/* Custom CSS Styles */
#invlist {
  font-family: font-family: Segoe UI,Frutiger,Frutiger Linotype,Dejavu Sans,Helvetica Neue,Arial,sans-serif;
  font-size: 18px;
  width: 600px;
}
#invlist ul a,
#invlist ul a:link,
#invlist ul a:visited {
  display: block;
  color: ##4B4579;
  text-decoration: none;
  font-weight: 300;
}
#invlist > ul {
  float: none;
}
#invlist ul {
  background: #fff;
}
#invlist > ul > li {
  border-left: 3px solid #d7d8da;
}
#invlist > ul > li > a {
  padding: 10px 20px;
}
#invlist > ul > li:hover {
  border-left: 3px solid #3dbd99;
}
#invlist ul li:hover > a {
  color: #3dbd99;
}
#invlist > ul > li:hover {
  background: #f6f6f6;
}
/* Sub Menu */
#invlist ul ul a:link,
#invlist ul ul a:visited {
  font-weight: 400;
  font-size: 14px;
}
#invlist ul ul {
  width: 180px;
  background: none;
  border-left: 20px solid transparent;
}
#invlist ul ul a {
  padding: 8px 0;
  border-bottom: 1px solid #eeeeee;
}
#invlist ul ul li {
  padding: 0 20px;
  background: #fff;
}
#invlist ul ul li:last-child {
  border-bottom: 3px solid #d7d8da;
  padding-bottom: 10px;
}
#invlist ul ul li:first-child {
  padding-top: 10px;
}
#invlist ul ul li:last-child > a {
  border-bottom: none;
}
#invlist ul ul li:first-child:after {
  content: '';
  display: block;
  width: 0;
  height: 0;
  position: absolute;
  left: -20px;
  top: 13px;
  border-left: 10px solid transparent;
  border-right: 10px solid #fff;
  border-bottom: 10px solid transparent;
  border-top: 10px solid transparent;
}
} 
</style>
<h2> Inventory List </h2>
"@


$InventoryFile = "$HtmlFilesFolder\Index.html"
$Inventorybody = "<div id='invlist'><ul>$workingReport</ul></div>" + $Footer  
ConvertTo-Html -Body $Inventorybody -Head $invhead | Out-File $InventoryFile  

#Invoke-Item $InventoryFile

