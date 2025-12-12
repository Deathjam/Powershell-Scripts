# System Information Inventory Script

## Overview

`sysinfo.ps1` is a comprehensive PowerShell inventory script that automatically collects detailed hardware and software information from computers in an Active Directory environment and generates professional HTML reports with an intuitive web interface.

## Features

### 🖥️ Hardware Information
- **System Details**: Manufacturer, model, serial number, BIOS version
- **Processor**: CPU model, speed, core count, architecture
- **Memory**: Total RAM, DIMM slot details, installed memory modules
- **Storage**: Physical disks with manufacturer, model, size, and interface type
- **Network Adapters**: All installed network cards with details
- **Monitor Information**: Connected displays with manufacturer, model, and serial numbers

### 💻 Operating System Information
- OS version, build number, and architecture (32/64-bit)
- Windows product key extraction
- Installation date and last boot time
- System uptime calculation
- Logged-on user and domain information
- Service pack level
- DNS hostname

### 🌐 Network Configuration
- IP addresses (IPv4/IPv6)
- DHCP status
- Gateway configuration
- DNS server settings
- MAC addresses
- Network adapter names and connection status

### 💾 Storage Details
- Logical drives and partitions
- Drive types (Fixed, Removable, Network)
- File system information
- Total and free space calculations
- Volume names

### ⚙️ Services Information
- Running Windows services
- Service status and startup type
- Service dependencies

## Functions

### `Get-WindowsKey`
Retrieves the Windows product key from local or remote computers by decrypting the DigitalProductId from the registry.

**Parameters:**
- `$targets` - Computer name(s) to query (default: local computer)

### `Get-Monitor`
Extracts monitor information using WMI EDID data, including manufacturer translation.

**Parameters:**
- `ComputerName` - Target computer(s) (accepts pipeline input)

**Features:**
- Translates manufacturer codes to full names (70+ manufacturers)
- Filters out all-in-one computer displays
- Retrieves model numbers and serial numbers

### `Get-Uptime`
Calculates system uptime and last reboot time.

**Parameters:**
- `computername` - Target computer(s) (default: local computer)

**Returns:**
- Computer name, username, uptime (days/hours/minutes/seconds), last reboot timestamp

## Output

The script generates a professional HTML-based inventory system with:

### 📊 Interactive Web Interface
- **Index Page**: Navigation menu listing all discovered computers
- **Hardware Page**: Complete hardware specifications
- **OS Page**: Operating system details and configuration
- **Storage Page**: Disk and volume information
- **Services Page**: Windows services status

### 🎨 Styling Features
- Modern, responsive design with Segoe UI font family
- Navigation bar for easy page switching
- Alternating row colors for better readability
- Previous/Next buttons for browsing between computers
- Home button for returning to index

### 📁 File Structure
```
[Output Folder]/
├── Index.html (main inventory list)
├── listall.txt (all computers from AD)
├── liston.txt (online computers)
├── listoff.txt (offline computers)
├── [ComputerName]/
│   ├── Index.html
│   ├── [ComputerName]-Hardware.html
│   ├── [ComputerName]-OperatingSystem.html
│   ├── [ComputerName]-Storage.html
│   └── [ComputerName]-Services.html
└── [Additional computers...]
```

## Configuration

### Required Modifications

Before running the script, you **must** configure the following variables:

#### Line 10: Output Folder Path
```powershell
$folderPath = '\\path\to\folder'
```
Set this to your desired output location for HTML reports.

#### Line 11: Duplicate Path Reference
Also update the path reference mentioned in the script comments (line 595).

#### Line 17: Active Directory Search Base
```powershell
$ADcomputers = (Get-ADComputer -Filter * -SearchBase "ou=mfg,dc=noam,dc=corp,dc=contoso,dc=com")
```
Update the SearchBase to match your AD organizational unit structure.

#### Line 595: Server Path for Home Button
```powershell
<a href="//path/to/server/Index.html">
```
Configure the web server path for the home button navigation.

### Optional Configurations

#### Monitor Filtering (Line ~230)
Filter out specific monitor models if needed:
```powershell
If ($Mon_Model -like "*800 AIO*" -or $Mon_Model -like "*8300 AiO*") {Break}
```

## Prerequisites

### PowerShell Modules
- **ActiveDirectory**: For querying AD computer objects
  ```powershell
  Import-Module ActiveDirectory
  ```

### Permissions Required
- **Active Directory**: Read access to computer objects
- **Network**: WMI access to target computers
- **Remote Management**: Firewall rules allowing WMI/DCOM
- **File System**: Write access to output folder location

### WMI Classes Used
- `Win32_ComputerSystem`
- `Win32_OperatingSystem`
- `Win32_Processor`
- `Win32_PhysicalMemory`
- `Win32_DiskDrive`
- `Win32_NetworkAdapter`
- `Win32_NetworkAdapterConfiguration`
- `Win32_LogicalDisk`
- `Win32_Service`
- `WMIMonitorID` (root\WMI namespace)

## Usage

### Basic Execution

1. **Configure the script** with your environment-specific paths
2. **Run as Administrator** to ensure proper WMI access:

```powershell
# Navigate to script directory
cd C:\Scripts\Inventory

# Run the script
.\sysinfo.ps1
```

### Execution Flow

1. ✅ Queries Active Directory for computer objects
2. ✅ Tests connectivity to each computer (ping)
3. ✅ Creates lists of online/offline computers
4. ✅ Collects WMI data from online computers
5. ✅ Generates HTML reports for each system
6. ✅ Creates master index page with navigation
7. ✅ Outputs files to configured folder path

### Scheduling

To run automatically, create a scheduled task:

```powershell
# Example: Run daily at 2 AM
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File "C:\Scripts\Inventory\sysinfo.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Daily Inventory" -RunLevel Highest
```

## Output Examples

### Computer Lists Generated
- **listall.txt**: All computers found in AD
- **liston.txt**: Computers that responded to ping
- **listoff.txt**: Computers that did not respond

### HTML Report Features
- Responsive tables with alternating row colors
- Professional Segoe UI typography
- Navigation between computer reports
- Organized sections for different information types
- Clean, modern styling

## Troubleshooting

### Common Issues

#### ❌ WMI Access Denied
**Solution**: Ensure the account running the script has administrative privileges on target computers.

#### ❌ AD Query Fails
**Solution**: Verify Active Directory module is installed and SearchBase is correct:
```powershell
Get-Module -ListAvailable -Name ActiveDirectory
```

#### ❌ Monitor Information Missing
**Solution**: Some monitors don't provide EDID data via WMI. This is a hardware/driver limitation.

#### ❌ Empty Reports Generated
**Solution**: 
- Check firewall rules allow WMI traffic
- Verify computers are online
- Ensure WMI service is running on target computers

#### ❌ Path Not Found Errors
**Solution**: Update all path references in the script (lines 10, 11, 595)

### Testing Individual Functions

Test functions independently for troubleshooting:

```powershell
# Test uptime function
Get-Uptime -computername "COMPUTER01"

# Test monitor detection
Get-Monitor -ComputerName "COMPUTER01"

# Test Windows key extraction
Get-WindowsKey -targets "COMPUTER01"
```

## Performance Considerations

- **Large Environments**: Script processes computers sequentially; consider parallel execution for large AD environments
- **Network Latency**: Remote WMI calls can be slow; timeout settings may need adjustment
- **File Output**: Generating HTML for many computers creates numerous files
- **Resource Usage**: WMI queries are resource-intensive on target systems

### Optimization Tips

```powershell
# Filter to specific OUs to reduce scope
$ADcomputers = (Get-ADComputer -Filter * -SearchBase "ou=workstations,dc=domain,dc=com")

# Add timeout for slow connections
Test-Connection -ComputerName $computer -Count 1 -TimeToLive 10 -Quiet
```

## Customization

### Adding Custom Information

Extend the script by adding additional WMI queries:

```powershell
# Example: Add installed software
$Software = Get-WmiObject Win32_Product -ComputerName $Computer
```

### Modifying HTML Styling

Edit the CSS sections in the script:
- `$head` variable (line ~278): Main stylesheet
- `$invhead` variable (line ~920): Index page stylesheet

### Changing Report Layout

Modify the HTML sections:
- `$Header`: Navigation buttons and branding
- `$Nav`: Page navigation menu
- `$Footer`: Footer content

## Security Notes

- Script requires elevated privileges
- Stores Windows product keys in plain text HTML files
- Consider implementing access controls on output folder
- Sensitive data is not encrypted in reports
- Review compliance requirements before deploying

## Best Practices

1. ✅ Test in non-production environment first
2. ✅ Schedule during off-peak hours to minimize impact
3. ✅ Implement log rotation for output files
4. ✅ Set appropriate NTFS permissions on output folder
5. ✅ Document environment-specific configurations
6. ✅ Keep a backup copy of the original script
7. ✅ Review and update AD SearchBase regularly

## Version History

**Current Version**: 1.0 (Poor Man's Server Inventory)

### Known Limitations
- Sequential processing only (no parallel execution)
- Requires WMI (not compatible with PowerShell remoting only)
- Some hardware details may be unavailable on virtual machines
- Monitor detection depends on EDID data availability

## Additional Resources

- [PowerShell WMI Documentation](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/07-working-with-wmi)
- [Active Directory Module](https://docs.microsoft.com/en-us/powershell/module/activedirectory/)
- [HTML Report Generation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-html)

## Support

For issues or questions:
1. Review the troubleshooting section above
2. Check WMI connectivity to target computers
3. Verify all paths are correctly configured
4. Ensure proper AD permissions are granted

---

**Note**: This script is provided as-is. Always test thoroughly in your environment before production use.
