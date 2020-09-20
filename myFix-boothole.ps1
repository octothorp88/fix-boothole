


# if (test-connection 'NGSDWK912M42396' -count 1) { write-host "connectable" }

function fix-boothole {

    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='low')]
    param(
        [parameter(ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        #[Alias('hostname')]
        # [ValidateLength(1,20)]
        [string[]]$name = @("."),
        [switch]$logfile
    )


    BEGIN{}
    
    
    PROCESS{
        foreach ($computer in $name) {
            if (test-connection $computer -count 1 -ErrorAction SilentlyContinue) {
                write-host -ForegroundColor Green "[+] $computer Online"
                $path = "SDNG"
                try {
                        if(!( test-path "\\$computer\c$\SDNG")) {
                            write-host -ForegroundColor Green "[+] Creating SDNG staging"
                            new-item -ItemType Directory -Force -Path \\$computer\c$\SDNG
                        } else {
                            write-host -ForegroundColor Yellow "[+] SDNG staging path exists "
                        }

                        if ((test-path "\\$computer\c$\SDNG\")) {
                            write-host -ForegroundColor Green "[+] copying source files to $computer"
                            try { copy-item -Recurse -Force C:\pmet\boothole "\\$computer\c$\SDNG\"
                            } catch { write-host -ForegroundColor Red "[!] Error copying, Bailing"
                                      continue
                               } 
                        }
                        
                        write-host -ForegroundColor Green "[+] Checking if script will Brick Device "
                                
                        invoke-command -ComputerName $computer { 

                            if (Confirm-SecureBootUEFI)    {
	                            Write-Host -ForegroundColor Green "[+] Secure boot is Enabled"
                                } else {
	                            Write-Host -ForegroundColor Red "[+] Secure boot is Disabled"
                                continue
                                }
                        
                            if ([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Microsoft Corporation UEFI CA 2011' ) {
                                write-host -ForegroundColor Green "[+] WOOT! UEFI CA is trusted"
                            } else {
                                write-host -ForegroundColor Red "[+] ERROR! UEFI CA is NOT"
                                continue
                            }

                            if ((test-path C:\sdng\boothole\content.bin) -and (test-path c:\sdng\boothole\signature.p7))  {

                                write-host -ForegroundColor Green "[+] BootyHole (O) Plugging initiated"
                                write-host "-----------------------------"

                                $output = Set-SecureBootUefi -Name dbx -ContentFilePath c:\sdng\boothole\content.bin -SignedFilePath c:\sdng\boothole\signature.p7 -Time 2010-03-06T19:17:21Z -AppendWrite
                                $output

                                write-host "-----------------------------"
                                write-host ""
                                write-host -ForegroundColor Green "[+] BootyHole (@) Plugging completed!"

                                if (get-process 'logonui' -ea SilentlyContinue) { 
                                    if (New-TimeSpan (Get-Process logonui).starttime) {
                                        write-host -ForegroundColor Green "[+] $env:computername No user Present";
                                        quser 2> $null
                                        # (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | ft
                                        write-host -ForegroundColor Green "[+] RESTARTING $env:computername"
                                        restart-computer -force
                                    } 
                                 } else {
                                        write-host -ForegroundColor Green "[+] $env:computername NOT LOCKED"
                                        quser 2> $null
                                        (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | ft
                                        write-host -ForegroundColor Yellow "[+] User Logged on to $env:computername restart Aborted"

                                        }

 
                            
                            } else {

                              write-host -ForegroundColor Red "[!] Files missing on host"
                            }
                        
                        
                        }
                        
                        $hostip=([system.net.dns]::GetHostByName($computer)).addresslist[0].ipaddresstostring

                        write-host -ForegroundColor Green "[+] $computer with $hostip complete"


                        
                    } catch {
                            $continue = $false
                            Write-Host  "ERROR Connecting to $computer" -ForegroundColor Red
                            Continue
                    }
                
                } else { 
                    write-host -ForegroundColor Red "[-] $computer Offline"
                    Continue
                }
            }
        }
    END{}

}

# fix-boothole NGSDWK210M42408