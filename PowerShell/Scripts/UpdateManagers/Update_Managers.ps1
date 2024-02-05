# Import the Active Directory module
Import-Module ActiveDirectory

# Define the path to your CSV file
$csvFilePath = "C:\Users\ssteelman\PowerShell\Scripts\UpdateManagers\SupervisorChange.csv"

# Import the CSV with explicit column headers
$csvData = Import-Csv $csvFilePath -Header "SamAccountName", "ManagerSamAccountName"

# Loop through the CSV file and update the Manager field for each user
foreach ($row in $csvData) {
    $userSamAccountName = $row."SamAccountName"
    $managerSamAccountName = $row."ManagerSamAccountName"

    $user = Get-ADUser -Filter {SamAccountName -eq $userSamAccountName}
    $manager = Get-ADUser -Filter {SamAccountName -eq $managerSamAccountName}

    if ($user -ne $null -and $manager -ne $null) {
        # Update the Manager field
        Set-ADUser -Identity $user -Manager $manager
        Write-Host "Updated Manager for $($user.SamAccountName) to $($manager.SamAccountName)"
    } else {
        Write-Host "User or Manager not found for $userSamAccountName or $managerSamAccountName"
    }
}
