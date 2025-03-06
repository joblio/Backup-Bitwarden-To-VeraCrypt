# Backup Bitwarden to VeraCrypt

This script automates the process of backing up your Bitwarden vault to a VeraCrypt encrypted volume.

## Prerequisites

- [VeraCrypt](https://www.veracrypt.fr/en/Downloads.html) installed
- [Bitwarden CLI](https://bitwarden.com/help/article/cli/) installed
- A VeraCrypt volume created and accessible
- Your Bitwarden password stored in a single-line text file within the VeraCrypt volume

## Configuration

Before running the script, update the following configuration variables in `backupBitwarden.bat`:

- `VC_PATH`: Path to the VeraCrypt executable
- `VC_VOLUME`: Path to your VeraCrypt volume
- `MOUNT_LETTER`: Drive letter to mount the VeraCrypt volume
- `BW_PATH`: Path to the Bitwarden CLI executable (usually just `bw` if it's in your PATH)
- `BW_EMAIL`: Your Bitwarden email address
- `PASSWORD_FILE`: Path to the Bitwarden password file within the mounted VeraCrypt volume

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

## Notes

- The exported Bitwarden vault is in unencrypted JSON format. Handle it with care and ensure it is stored securely within the VeraCrypt volume.
- This is a rough batch file, and does not check for certain things, such as:
 - If bw is already logged in, this will fail
 - It does not check if you are out of disk space in the encrypted volume