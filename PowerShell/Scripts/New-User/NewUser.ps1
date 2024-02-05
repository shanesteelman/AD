# Specify the path to the CSV file containing user data
$csvFilePath = "C:\Users\ssteelman\PowerShell\Scripts\New-User\New_user_data.csv"

# Read user data from the CSV file
$userData = Import-Csv $csvFilePath

# Define the DistinguishedName of the target group
$groupDN = "CN=Intranet_Epsilon_Users,OU=Groups,OU=SanDiego-CA,DC=epsilonsystems,DC=com"

# Initialize an array to store user creation results
$userCreationResults = @()

# Loop through each row in the CSV and create users
foreach ($user in $userData) {
    $firstName = $user.FirstName
    $lastName = $user.LastName

    # Generate the user logon name (first initial + last name)
    $logonName = ($firstName.Substring(0, 1) + $lastName).ToLower()
    $originalLogonName = $logonName
    $ouPath = $user.OU

    # Construct the full name
    $fullName = "$firstName $lastName"

    # Retrieve the Employee ID from the CSV file (make sure you have an "EmployeeID" column)
    $employeeID = $user.EmployeeID

    # Generate a password with two dollar signs and the employee ID
    $password = "E`$`$$employeeID!@"

    # Check if the logon name is already in use, and if so, append the next character in the first name
    $i = 1
    while (Get-ADUser -Filter {SamAccountName -eq $logonName}) {
        $logonName = $originalLogonName + $firstName.Substring($i, 1)
        $i++
    }

    # Additional user attributes
    $description = $user.Description
    $office = $user.Office

    # Add debugging output
    Write-Host "Creating user: $firstName $lastName with logon name: $logonName"

    # Create the user in the specified OU with additional attributes and email address
    $newUser = New-ADUser -Name $fullName -GivenName $firstName -Surname $lastName -SamAccountName $logonName -UserPrincipalName "$logonName@epsilonsystems.com" -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Enabled $true -Path $ouPath -Description $description -Office $office -EmailAddress "$logonName@epsilonsystems.com" -DisplayName $fullName

    if ($newUser) {
        Write-Host "User object created for $logonName"
        Enable-ADAccount -Identity $newUser

        # Add the user to the target security group using the DistinguishedName
        Add-ADGroupMember -Identity $groupDN -Members $newUser.DistinguishedName
        Write-Host "Added $logonName to the target group."
    } else {
        Write-Host "Error: User object is null, unable to create user for $firstName $lastName"
    }

    # Store user creation results in an object
    $userResult = New-Object PSObject -Property @{
        "FullName" = $fullName
        "LogonName" = $logonName
        "Password" = $password
        "Email" = "$logonName@epsilonsystems.com"
    }
    $userCreationResults += $userResult
}

# Output the results
foreach ($result in $userCreationResults) {
    Write-Host "User created: $($result.FullName)"
    Write-Host "Logon Name: $($result.LogonName)"
    Write-Host "Password: $($result.Password)"
    Write-Host "Email: $($result.Email)"
    Write-Host ""
}

Write-Host "Users created successfully."
