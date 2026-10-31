# Backup Bitwarden to VeraCrypt

This script automates the process of backing up your Bitwarden vault to a VeraCrypt encrypted volume.

## Prerequisites

- Windows
- [VeraCrypt](https://www.veracrypt.fr/en/Downloads.html) installed
- [Bitwarden CLI](https://bitwarden.com/help/article/cli/) installed
- A VeraCrypt volume created and accessible
- Your Bitwarden password stored in a single-line text file within the VeraCrypt volume
- An empty file named `.backup-volume` in the root of the VeraCrypt volume (see [Setup Instructions](#setup-instructions))

## Configuration

Your personal settings go in a separate file so you never have to edit `backupBitwarden.bat`. Copy `backupBitwarden.local.example.bat` to `backupBitwarden.local.bat` (same folder) and set the values there. It is loaded automatically and ignored by git. Any variable from the configuration section of `backupBitwarden.bat` can be overridden in it.

The script refuses to run while the `CHANGE_ME_` placeholders are still in place.

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

### Example `backupBitwarden.local.bat`:
```batch
set VC_VOLUME="D:\Secure\MyVault.hc"
set BW_EMAIL=john.doe@example.com
```

## Usage

Run `backupBitwarden.bat` from the command line or by double-clicking it. The script is interactive, so it cannot run unattended (for example as a scheduled task): it asks for your VeraCrypt password and pauses at the end.

The script will:

1. Check that the configuration has been filled in and that VeraCrypt and the Bitwarden CLI are available.
2. Check whether the VeraCrypt volume is already mounted. If the drive letter is in use, the `.backup-volume` marker file must be present, otherwise the script stops so it never writes to the wrong drive.
3. Mount the volume if it is not already mounted, asking for the VeraCrypt password (the input is hidden).
4. Verify that the Bitwarden password file exists within the mounted volume.
5. Log into Bitwarden if needed (you will be prompted for a 2FA code if your account uses one), then unlock the vault and retrieve a session key.
6. Sync the Bitwarden vault.
7. Export the Bitwarden vault in unencrypted JSON format to the specified location within the VeraCrypt volume.
8. Delete the oldest exports so that only the newest `KEEP_EXPORTS` remain. This only happens after a successful export.
9. Lock the Bitwarden vault and clear the session key.
10. If the script mounted the volume itself, wait for a keypress (so you can work in the volume if you need to) and then dismount it. A volume that was already mounted when the script started is left mounted.

Steps 9 and 10 also run when something fails partway through.

## Setup Instructions

1. **Install Prerequisites**: Ensure VeraCrypt and Bitwarden CLI are installed
2. **Create VeraCrypt Volume**: Create an encrypted volume file
3. **Create Password File**: In your VeraCrypt volume, create a text file named `password.txt` containing only your Bitwarden password
4. **Create the Marker File**: With the volume mounted, create an empty file in its root, for example `New-Item V:\.backup-volume -ItemType File` in PowerShell. Then dismount the volume.
5. **Configure Script**: Copy `backupBitwarden.local.example.bat` to `backupBitwarden.local.bat` and edit the values
6. **Test Run**: Execute the script to verify everything works

## Troubleshooting

- **"Configuration still contains CHANGE_ME placeholders"**: Set `VC_VOLUME` and `BW_EMAIL` in `backupBitwarden.local.bat`
- **"VeraCrypt not found"**: Update `VC_PATH` to correct VeraCrypt installation path
- **"Bitwarden CLI not found"**: Install Bitwarden CLI or update `BW_PATH`
- **"Failed to mount"**: Check the VeraCrypt volume path and password. To see VeraCrypt's own error message, run `"C:\Program Files\VeraCrypt\VeraCrypt.exe" /q /v "<your volume path>" /l V` by hand.
- **"Drive V: exists but is not the backup volume"**: Another drive is using the letter, or `.backup-volume` is missing from the volume. Create the marker file, or change `MOUNT_LETTER`.
- **"Password file not found"**: Ensure `password.txt` exists in your VeraCrypt volume
- **"Failed to log into Bitwarden" / "Failed to retrieve Bitwarden session"**: Check `BW_EMAIL` and that `password.txt` contains only your Bitwarden password on one line
- **"Failed to dismount"**: Something still has a file open on the volume. Close it and dismount from VeraCrypt.

## Security Notes

- The exported Bitwarden vault is in unencrypted JSON format within the encrypted VeraCrypt volume
- Your Bitwarden master password is stored in plaintext in `password.txt`, also inside the volume. Anyone who can open the volume gets both.
- Password file should only contain your Bitwarden password on a single line
- The VeraCrypt password is passed to VeraCrypt on the command line, so it is briefly visible to other processes on the machine while the volume mounts. A `"` character in that password is not supported.
- The script dismounts the volume only if it mounted it. Dismount it yourself when you are done if you mounted it by hand.
- Consider exporting with `bw export --format encrypted_json` if you want the exports themselves encrypted as well
