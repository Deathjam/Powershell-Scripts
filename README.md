# PowerShell Scripts Collection

A comprehensive collection of PowerShell scripts for various system administration and automation tasks including AWS management, Office 365 administration, FileZilla FTP management, and general utilities.

## 📋 Table of Contents

- [Overview](#overview)
- [Root Scripts](#root-scripts)
- [AWS Scripts](#aws-scripts)
- [FileZilla Management](#filezilla-management)
- [Inventory Scripts](#inventory-scripts)
- [Office 365 Scripts](#office-365-scripts)
- [Requirements](#requirements)
- [Usage](#usage)
- [Contributing](#contributing)

## Overview

This repository contains automation scripts for Windows system administrators, focusing on cloud services, FTP management, and Office 365 administration. Each script is designed to simplify common administrative tasks and improve workflow efficiency.

## Root Scripts

### `Generate-Password.ps1`
Generates secure random passwords using a dictionary-based approach.

**Features:**
- Generates multiple passwords at once
- Optional symbol inclusion
- Uses a word list for memorable passwords
- Automatically downloads required word list if missing

**Usage:**
```powershell
Generate-Password -Count 5
Generate-Password -Count 5 -symbol
```

### `Credentials-CreateKey.ps1`
Creates and manages encrypted credential keys for secure script authentication.

### `Fix-Edge.ps1`
Utility script for troubleshooting and fixing Microsoft Edge browser issues.

### `Reload-MDT.ps1`
Reloads and updates Microsoft Deployment Toolkit (MDT) Windows PE boot images.

**Features:**
- Updates WDS boot images (x86 and x64)
- Automated deployment share synchronization
- Imports MDT PowerShell module

### `fourlist.txt`
Dictionary word list used by the password generation script (5000+ four-letter words).

## AWS Scripts

Located in the `/AWS/` directory.

### `Get-AWSServers.ps1`
Retrieves information about AWS EC2 instances.

### `Get-Ebsmaps.ps1`
Maps and displays AWS EBS (Elastic Block Store) volumes and their attachments.

## FileZilla Management

Located in the `/FileZilla/` directory. These scripts enable user-friendly FTP account management without requiring direct access to the FileZilla Server console.

### Key Features:
- ✅ Allow users to create FTP accounts in a standardized way
- ✅ Create FTP accounts with minimal permissions
- ✅ Reset FTP account passwords without administrator intervention
- ✅ Automatic account disabling after inactivity period
- ✅ Automated archiving and cleanup of disabled accounts
- ✅ Email notifications for account expiration warnings

### Scripts:

#### `FTP_NewFileZillaUser.ps1`
Creates new FileZilla FTP user accounts with standardized settings.

#### `FTP_ResetFileZillaUserPassword.ps1`
Resets passwords for existing FileZilla FTP accounts and reactivates disabled accounts.

#### `FTP_UserMaintenance.ps1`
Automated maintenance script that:
- Monitors account last usage dates
- Sends warning emails before disabling accounts
- Automatically disables inactive accounts
- Archives folders for disabled accounts
- Cleans up old accounts

#### `ReloadConfig.ps1`
Reloads the FileZilla Server configuration after making changes.

#### `setPsSessionConfigurationForFZAdmin.ps1`
Configures PowerShell session permissions for FileZilla administration.

**Note:** See `/FileZilla/ReadMe.md` for detailed setup instructions.

**Credits:** Scripts adapted from [FileZilla Forum](https://forum.filezilla-project.org/viewtopic.php?t=33069)

## Inventory Scripts

Located in the `/Inventory/` directory.

### `sysinfo.ps1`
Comprehensive system information gathering script.

**Features:**
- Hardware inventory collection
- Monitor manufacturer detection
- System configuration reporting
- Network adapter information

## Office 365 Scripts

Located in the `/Office365/` directory. Scripts for managing Microsoft 365 environments.

### `365-license-check.ps1`
Interactive GUI tool for checking Office 365 license usage and availability.

**Features:**
- Visual display of license consumption
- Shows remaining licenses
- Active Units vs. Consumed Units comparison
- Sorted by SKU

### `365.ps1`
General Office 365 management utilities.

### `Add-Remove MailBox Access.ps1`
Manages mailbox delegation and access permissions.

### `Connect-Office365.ps1`
Simplified connection script for Office 365 PowerShell sessions.

### `Install-Check.ps1`
Verifies Office 365 module installation and prerequisites.

### `mailbox-access.ps1`
Advanced mailbox permission management utility (Version 1.0).

### `Remove-365Users.ps1`
Batch removal utility for Office 365 user accounts.

## Requirements

### General Requirements:
- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (for most scripts)
- Appropriate module dependencies per script category

### Office 365 Scripts:
- MSOnline PowerShell Module or Microsoft.Graph modules
- Office 365 administrator credentials

### AWS Scripts:
- AWS Tools for PowerShell
- Configured AWS credentials

### FileZilla Scripts:
- FileZilla Server installed
- Remote PowerShell enabled
- Appropriate permissions configured

### MDT Scripts:
- Microsoft Deployment Toolkit installed
- Windows Deployment Services (WDS) access

## Usage

1. **Clone or download** this repository to your local machine
2. **Review** the script you want to use for any required parameters
3. **Execute** scripts with appropriate permissions:

```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Navigate to script directory
cd path\to\Powershell-Scripts

# Execute desired script
.\ScriptName.ps1 -Parameter Value
```

## Best Practices

- Always test scripts in a non-production environment first
- Review script parameters and required permissions
- Keep scripts updated with your environment-specific configurations
- Maintain secure credential storage practices
- Document any customizations made to scripts

## Security Notes

- Never commit credentials or API keys to the repository
- Use secure credential storage mechanisms (e.g., `Credentials-CreateKey.ps1`)
- Review scripts before execution in production environments
- Follow principle of least privilege when assigning permissions

## Contributing

Contributions are welcome! If you have improvements or additional scripts:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Please review individual scripts for specific licensing information. Scripts adapted from external sources maintain their original licenses and attributions.

## Acknowledgments

- FileZilla forum community for FTP management scripts
- Microsoft documentation and examples
- AWS PowerShell documentation
- Community contributors

---

**Note:** Always ensure scripts are compatible with your environment and organization's policies before deployment.
