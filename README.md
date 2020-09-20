This is just a little ps1 cmdlet to patch the boothole vuln on my systems at
work.

Below are just some notes I pulled from Microsoft, uefi.org and the interwebs.

``` powershell
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Microsoft Corporation UEFI CA 2011'
```



## Applying a DBX update on Windows
After you read the warnings and verify that your device is compatible, follow these steps to update the Secure Boot DBX:

Download the appropriate UEFI Revocation List File (Dbxupdate.bin) for your platform from https://uefi.org/revocationlistfile. 
You will have to split the Dbxupdate.bin file into the necessary components in order to apply them by using PowerShell cmdlets. To do this, follow these steps

Download the PowerShell script from https://aka.ms/DbxSplitScript.

Run the following PowerShell script on the Dbxupdate.bin file:

``` powershell
   SplitDbxAuthInfo.ps1 “c:\path\to\file\dbxupdate.bin”         
```
## Verify that the command created the following files:

Content.bin update contents

Signature.p7 signature authorizing the update process
In an administrative PowerShell session, run the Set-SecureBootUefi cmdlet to apply the DBX update:

```
Set-SecureBootUefi -Name dbx -ContentFilePath .\content.bin -SignedFilePath .\signature.p7 -Time 2010-03-06T19:17:21Z -AppendWrite
```

Restart the device to complete the process
For more information about the Secure Boot configuration cmdlet and how to use it for DBX updates, see Set-SecureBootUEFI.
