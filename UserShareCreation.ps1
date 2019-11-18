<# UserShareCreation.ps1
 Jon Shults
 Binnacle Technologies, LLC
 
 This script is intended to be an alternative to configuring a user's Home folder in active directory.
 It is not a full replacement for the process as other processes or applications can read the Home folder
 location from Active Directory, vs all this script does is create the user's folder with correct permissions.
 You will want to invest the time to understand the difference and how that may impact your organization.
 
 To use, add this script as a logon powershell script to your drive map GPO, and be sure to set the GPO to run
 powershell scripts first. Be sure your UserShare directory exists with with proper permissions for users to create.
 
 We also populate the eventlog with failures, and have commented those lines out by default.

 Last Updated 11/18/2019
 #>

# Define the below

$UserShare = '\\Server\Usershare'
# $EventLogSource = "YourEventLogSource"

# Do not modify anything below

$access = $Null

# Checks if the event log source exists, and if not, creates it.

<# if (![System.Diagnostics.EventLog]::SourceExists($EventLogSource))
    {
        New-EventLog -LogName Application -Source $EventLogSource
        Write-EventLog -LogName Application -Source $EventLogSource -EntryType Information -EventID 1 -Message "EventLog Source $($EventLogSource) created."
    }
#>

# Checks if the user folder exists, and if not, creates it. Exits script if for some reason the creation fails.

If (!(Test-Path "$($userShare)\$env:Username")) {
    New-Item -Path "$($userShare)\$env:Username" -ItemType Directory
    If (!(Test-Path "$($userShare)\$env:Username")) {
        # Write-EventLog -LogName Application -Source $EventLogSource -EntryType Error -category 1 -EventID 2 -Message "$($userShare)\$($env:Username) folder did not exist and creating it failed."
        Break
    }

    # Pulls the newly created  folder permissions

    $acl = Get-Acl "$($userShare)\$env:Username"

    # Removes Enheritance, and does not copy existing permissions

    $acl.SetAccessRuleProtection($True, $False)

    # Adds default permissions of SYSTEM and Administrators having full access

    $AR1 = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","Allow")
    $AR2 = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","Allow")

    # Adds the user with Full Control

    $AR3 = New-Object System.Security.AccessControl.FileSystemAccessRule($env:Username,"FullControl","Allow")
    
    # Prepares to set the user as folder owner

    $Owner = New-Object System.Security.Principal.NTAccount($env:USERDOMAIN, $env:Username)

    # Compiles all of the rules for one file system call

    $acl.SetOwner($Owner)
    $acl.SetAccessRule($AR1)
    $acl.SetAccessRule($AR2)
    $acl.SetAccessRule($AR3)
    
    # Executes permission change

    Set-Acl "$($userShare)\$env:Username" $acl

    # Pulls fresh permission list for logging

    $acl = Get-Acl "$($userShare)\$env:Username"

    # Parses and outputs permissions into an eventlog entry

    $access = "Folder $($userShare)$($env:Username) created successfully. `n`nFolder owner is $($acl.owner).`n"
    Foreach ($entry in $acl.Access) {
        $access = $access + "$($entry.IdentityReference) has $($entry.FileSystemRights) access.  `n"
    }

    # Write-EventLog -LogName Application -Source $EventLogSource -EntryType Information -EventID 1 -Message $access
}
