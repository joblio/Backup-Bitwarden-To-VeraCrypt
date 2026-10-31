# Backup Bitwarden to VeraCrypt

This script automates the process of backing up your Bitwarden vault to a VeraCrypt encrypted volume.

## Prerequisites

- [VeraCrypt](https://www.veracrypt.fr/en/Downloads.html) installed
- [Bitwarden CLI](https://bitwarden.com/help/article/cli/) installed
- A VeraCrypt volume created and accessible
- Your Bitwarden password stored in a single-line text file within the VeraCrypt volume

## Configuration

Before running the script, update the following configuration variables in `backupBitwarden.bat`:

### Required Configuration Changes:
- `VC_VOLUME`: Path to your VeraCrypt volume file (e.g., `"D:\MySecrets\vault.hc"`)
- `BW_EMAIL`: Your Bitwarden email address (e.g., `user@example.com`)

### Optional Configuration:
- `VC_PATH`: Path to VeraCrypt executable (default: `"C:\Program Files\VeraCrypt\VeraCrypt.exe"`)
- `MOUNT_LETTER`: Drive letter to mount the VeraCrypt volume (default: `V`)
- `BW_PATH`: Bitwarden CLI command (default: `bw` - assumes it's in your PATH)
- `EXPORT_FILE`: Export destination folder (default: `V:\` - root of mounted volume)
- `PASSWORD_FILE`: Bitwarden password file location (default: `V:\password.txt`)
- `KEEP_EXPORTS`: Number of newest `bitwarden_export_*.json` files to keep after a successful export (default: `10`, `0` keeps everything)

Instead of editing `backupBitwarden.bat`, copy `backupBitwarden.local.example.bat` to `backupBitwarden.local.bat` (same folder) and set the values there. It is loaded automatically and ignored by git.

You also need an empty file named `.backup-volume` in the root of the VeraCrypt volume. The script uses it to confirm the drive letter is really your backup volume.

### Example Configuration:
```batch
set VC_VOLUME="D:\Secure\MyVault.hc"
set BW_EMAIL=john.doe@example.com
```

## Usage

You can run the script from the command line, explorer, or a scheduled task. When prompted, enter your VeraCrypt volume password.

The script will:

1. Check if the VeraCrypt volume is already mounted.
2. Mount the VeraCrypt volume if it is not already mounted.
3. Verify that the Bitwarden password file exists within the mounted volume.
4. Log into Bitwarden and retrieve a session key.
5. Sync the Bitwarden vault.
6. Export the Bitwarden vault in unencrypted JSON format to the specified location within the VeraCrypt volume.
7. Clear the Bitwarden session key.

## Setup Instructions

1. **Install Prerequisites**: Ensure VeraCrypt and Bitwarden CLI are installed
2. **Create VeraCrypt Volume**: Create an encrypted volume file
3. **Create Password File**: In your VeraCrypt volume, create a text file named `password.txt` containing only your Bitwarden password
4. **Configure Script**: Edit the configuration variables in `backupBitwarden.bat`
5. **Test Run**: Execute the script to verify everything works

## Troubleshooting

- **"VeraCrypt not found"**: Update `VC_PATH` to correct VeraCrypt installation path
- **"Bitwarden CLI not found"**: Install Bitwarden CLI or update `BW_PATH`
- **"Failed to mount"**: Check VeraCrypt volume path and password
- **"Password file not found"**: Ensure `password.txt` exists in your VeraCrypt volume
- **Configuration errors**: Make sure you've changed `CHANGE_ME_` placeholder values

## Security Notes

- The exported Bitwarden vault is in unencrypted JSON format within the encrypted VeraCrypt volume
- Password file should only contain your Bitwarden password on a single line
- Ensure VeraCrypt volume is dismounted when not in use
- Consider using Bitwarden API keys instead of passwords for enhanced security