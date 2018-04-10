<#

    Author: Phil Wray
    Version:1
    Version History:none

    Purpose:Get Users who have which Office 365 license

#>

$date = (Get-Date -Format yyyy-MM-dd-hh-mm)


#365 connection
Function no365 
{
  Get-PSSession |
  Where-Object -FilterScript {
    $_.ComputerName -like '*.outlook.com' -or $_.ComputerName -like '*.lync.com' -or $_.ComputerName -like '*.office365.com'
  } |
  Remove-PSSession |
  Disconnect-SPOService
}


function MSOLConnected 
{
  $null = Get-MsolDomain -ErrorAction SilentlyContinue
  $result = $?
  return $result
}

if (-not (MSOLConnected))
{ 
  $credential = (Get-Credential -Message 'Enter Office 365 Admin login')
  Import-Module -Name MsOnline
  Connect-MsolService -Credential $credential
}

Function Get-Licenses 
{
  Get-MsolAccountSku |
  Select-Object -Property AccountSkuId, ActiveUnits, ConsumedUnits, @{
    Name       = 'Remaining'
    Expression = {
      $_.ActiveUnits - $_.ConsumedUnits
    }   
  } |
  Sort-Object -Property AccountSkuId    
}
  
function ToArray
{
  begin
  {
    $output = @() 
  }
  process
  {
    $output += $_ 
  }
  end
  {
    return ,$output 
  }
}
  

 
#region XAML window definition
# Right-click XAML and choose WPF/Edit... to edit WPF Design
# in your favorite WPF editing tool
$xaml = @'
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   xmlns:d="http://schemas.microsoft.com/expression/blend/2008" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="d"
   MinWidth="200"
   Width ="800"
   Title="Office 365 Licenses"
   Topmost="True" Height="671.411">
    <Grid Margin="10,40,10,10">

        <ListView x:Name="list365License" Height="230" Margin="10,10,10,0" VerticalAlignment="Top">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="License" DisplayMemberBinding ="{Binding AccountSkuId}" Width="250"/>
                    <GridViewColumn Header="ActiveUnits" DisplayMemberBinding ="{Binding ActiveUnits}" Width="150"/>
                    <GridViewColumn Header="ConsumedUnits" DisplayMemberBinding ="{Binding ConsumedUnits}" Width="150"/>
                    <GridViewColumn Header="Remaining" DisplayMemberBinding ="{Binding Remaining}" Width="150"/>
                </GridView>
            </ListView.View>
        </ListView>
        <TextBlock x:Name="textBlock" HorizontalAlignment="Left" Margin="0,-25,0,0" TextWrapping="Wrap" Text="Please select a license:" VerticalAlignment="Top"/>
        <DataGrid x:Name="dataGrid" Margin="10,250,10,10"/>
        <Button x:Name="export_UsersDG_btn" Content="Export Users with licenses" HorizontalAlignment="Right" Margin="0,-27,10,0" Width="146" Height="27" VerticalAlignment="Top"/>
        <Button x:Name="export_licenseDG_btn" Content="Export Licenses" Margin="0,-27,164,0" HorizontalAlignment="Right" Width="146" Height="27" VerticalAlignment="Top"/>
    </Grid>
</Window>
'@

function Convert-XAMLtoWindow
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $xaml,
    
    [string[]]
    $NamedElement = $null,
    
    [switch]
    $PassThru
  )
  
  Add-Type -AssemblyName PresentationFramework
  
  $reader = [XML.XMLReader]::Create([System.IO.StringReader]$xaml)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  foreach($Name in $NamedElement)
  {
    $result | Add-Member -MemberType NoteProperty -Name $Name -Value $result.FindName($Name) -Force
  }
  
  if ($PassThru)
  {
    $result
  }
  else
  {
    $null = $window.Dispatcher.InvokeAsync{
      $result = $window.ShowDialog()
      Set-Variable -Name result -Value $result -Scope 1
    }.Wait()
    $result
  }
}

function Show-WPFWindow
{
  param
  (
    [Parameter(Mandatory)]
    [Windows.Window]
    $window
  )
  
  $result = $null
  $null = $window.Dispatcher.InvokeAsync{
    $result = $window.ShowDialog()
    Set-Variable -Name result -Value $result -Scope 1
  }.Wait()
  $result
  no365
}

$window = Convert-XAMLtoWindow -xaml $xaml -NamedElement 'dataGrid', 'export_licenseDG_btn', 'export_UsersDG_btn', 'list365License', 'textBlock' -PassThru


$ListBox = $window.list365License

$DG = $window.dataGrid
$ListBox.Items.Clear()
$DG.ItemsSource = ''


Get-Licenses | Where-Object -FilterScript {
  $window.list365License.AddChild($_)
}
$window.list365License.ItemBindingGroup

$window.list365License.add_SelectionChanged{
  # remove param() block if access to event information is not required
  param
  (
    [Parameter(Mandatory)][Object]$sender,
    [Parameter(Mandatory)][Windows.Controls.SelectionChangedEventArgs]$e
  )
  
  $window.Cursor = [System.Windows.Input.Cursors]::Wait 
  $License = $ListBox.SelectedItem.AccountSkuId 
  
  $dgsrc = Get-MsolUser -All |
  Select-Object -Property userprincipalname, islicensed, @{
    Name       = 'AccountSkuId'
    Expression = {
      $_.Licenses.AccountSkuId
    }
  } |
  Where-Object -FilterScript {
    $_.AccountSkuId -eq $License
  } |
  Sort-Object -Property userprincipalname
  
  $DG.ItemsSource = $dgsrc | ToArray
  $window.Cursor = [System.Windows.Input.Cursors]::Arrow
}

$window.export_UsersDG_btn.add_Click{
  # remove param() block if access to event information is not required
  param
  (
    [Parameter(Mandatory)][Object]$sender,
    [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
  )
  if($DG.Items.IsEmpty)
  {
    [System.Windows.MessageBox]::Show('No Data, try selecting a license first!')
  }
  else
  {
    $DG.Items |
    Export-Csv -Path "$ENV:UserProfile\Documents\Users_with_licenses_$date.csv" -NoTypeInformation |
    Format-Table
    [System.Windows.MessageBox]::Show('Export Completed')
    Invoke-Item -Path "$ENV:UserProfile\Documents"
  }
}

$window.export_licenseDG_btn.add_Click{
  # remove param() block if access to event information is not required
  param
  (
    [Parameter(Mandatory)][Object]$sender,
    [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
  )
  
  Get-Licenses |
  Export-Csv -Path "$ENV:UserProfile\Documents\Office365_licenses_$date.csv" -NoTypeInformation |
  Format-Table
  [System.Windows.MessageBox]::Show('Export Completed')
  Invoke-Item -Path "$ENV:UserProfile\Documents"
}



$null = Show-WPFWindow -window $window
