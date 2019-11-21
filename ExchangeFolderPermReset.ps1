<# ExchangeFolderPermReset.ps1
 Jon Shults
 Binnacle Technologies, LLC
 
 We come into many situations where user share permissions on mailbox folders are all over the place.
 This script strips all explicit-user permissions from the listed folder and assigns Default and Anonymous
 permissions the values specified. If the Default or Anonymous accounts have been removed, it adds them
 back with the permission values specified. This gives us a clean starting point to then make any corrections.

 This script has been tested against Office365 and Exchange 2016.

 Last Updated 11/21/2019
 #>

# This script should work with any folder assigned, but has only been tested against Calendar and Contacts.
$Folder = "Contacts"

# Assign the desired permissions for Default and Anonymous below
$DefaultPerm = "Reviewer"
$AnonymousPerm = "None"

Get-Mailbox -ResultSize Unlimited | ForEach {
    $UserPerms = (Get-MailboxFolderPermission -Identity "$($_.PrimarySMTPAddress):\$($Folder)")
    Write-Output "-= Now checking $($_.Identity) =-"
    ForEach ($Entry in $userperms) {
        # First we remove any explicitely-assigned permissions that aren't Default or Anonymous
        If ($Entry.user.DisplayName -notlike "Default" -AND $Entry.user.DisplayName -notlike "Anonymous") {
            Write-Output "User is $($Entry.user) and not default or anonymous, removing..."
            Remove-MailboxFolderPermission -Identity "$($_.Identity):\$($Folder)" -User $Entry.user.DisplayName -confirm:$false
        # Then we verify that Default has an entry, and that the permissions are what we want
        } Elseif ($Entry.user.DisplayName -like "Default") {
            Write-Output "Default user is present. Verifying correct Default setting"
            $DefaultUserPresent = $True
            Write-Output "User $($Entry.user.DisplayName) currently has AccessRights of $($Entry.AccessRights)"
            If ($Entry.AccessRights -notlike $DefaultPerm) {
                Write-Output "Incorrect permission setting, fixing..."
                Set-MailboxFolderPermission -Identity "$($_.Identity):\$($Folder)" -User Default -AccessRights $DefaultPerm
            }
        # Same with Anonymous, we set a flag that it exists, and the permissions match what we want
        } Elseif ($Entry.user.DisplayName -like "Anonymous") {
            Write-Output "Anonymous user is present. Verifying correct Anonymous setting"
            $AnonymousUserPresent = $True
            Write-Output "User $($Entry.user.DisplayName) currently has AccessRights of $($Entry.AccessRights)"
            If ($Entry.AccessRights -notlike $AnonymousPerm) {
                Write-Output "Incorrect permission setting, fixing..."
                Set-MailboxFolderPermission -Identity "$($_.Identity):\$($Folder)" -User Default -AccessRights $AnonymousPerm
            }  
        } 
    }
    # If the Default User doesn't exist, we create it, and assign the appropriate permissions
    If (!$DefaultUserPresent) {
        Write-Output "Default User not found, Creating..."
        Add-MailboxFolderPermission -Identity "$($_.Identity):\$($Folder)" -User Default -AccessRights $DefaultPerm
    }
    # If the Anonymous User doesn't exist, we create it, and assign the appropriate pemrissions
    If (!$AnonymousUserPresent) {
        Write-Output "Anonymous User not found, Creating..."
        Add-MailboxFolderPermission -Identity "$($_.Identity):\$($Folder)" -User Anonymous -AccessRights $AnonymousPerm
    }
    # Reset the Default and Anonmyous exist flags for the next $_.Identity
    $DefaultUserPresent = $False
    $AnonymousUserPresent = $false
    Write-Output "`n"
}
