$Source = "Client Setup.xlsx"

$Users = Import-Excel $Source
$UserList = @()
$NewRow = @()
ForEach ($User in $Users) {
    $NameSplit = $User.Name -split " "
    $FirstName = $NameSplit[0]
    $LastName = $NameSplit[1]
    $NewRow = $User."Mac ID" + "," + $User."Brand/Model Phone" + "," + $User.Extension + "," + $FirstName + "," + $LastName + "," + $User.'Email Address for Notification'
    $UserList += $NewRow
    }
$UserList | Out-file NewUsers.csv
