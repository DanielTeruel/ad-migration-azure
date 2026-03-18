# AD Structure Setup — daniel.local
# Creates OUs, moves users, assigns groups and attributes

Import-Module ActiveDirectory

# Create OUs
New-ADOrganizationalUnit -Name "Admin_NoSync" -Path "OU=DANIEL,DC=daniel,DC=local" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "Service_Accounts" -Path "OU=DANIEL,DC=daniel,DC=local" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "Servers" -Path "OU=DANIEL,DC=daniel,DC=local" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "General" -Path "OU=Departamentos,OU=DANIEL,DC=daniel,DC=local" -ProtectedFromAccidentalDeletion $false

# Move users to department OUs
Move-ADObject -Identity (Get-ADUser "user1_it").DistinguishedName -TargetPath "OU=IT,OU=Departamentos,OU=DANIEL,DC=daniel,DC=local"
Move-ADObject -Identity (Get-ADUser "user2_hr").DistinguishedName -TargetPath "OU=HR,OU=Departamentos,OU=DANIEL,DC=daniel,DC=local"
Move-ADObject -Identity (Get-ADUser "user3_admin").DistinguishedName -TargetPath "OU=Admin_NoSync,OU=DANIEL,DC=daniel,DC=local"
Move-ADObject -Identity (Get-ADUser "user4_general").DistinguishedName -TargetPath "OU=General,OU=Departamentos,OU=DANIEL,DC=daniel,DC=local"
Move-ADObject -Identity (Get-ADUser "App01Admin").DistinguishedName -TargetPath "OU=Admin_NoSync,OU=DANIEL,DC=daniel,DC=local"
Move-ADObject -Identity (Get-ADComputer "APP01").DistinguishedName -TargetPath "OU=Servers,OU=DANIEL,DC=daniel,DC=local"

# Assign users to security groups
Add-ADGroupMember -Identity "Sec_IT" -Members "user1_it"
Add-ADGroupMember -Identity "Sec_HR" -Members "user2_hr"
Add-ADGroupMember -Identity "Sec_Admins" -Members "user3_admin"

# Set user attributes
Set-ADUser "user1_it" -GivenName "User1" -Surname "IT" -Department "IT" -Title "IT Technician" -EmailAddress "user1_it@daniel.local"
Set-ADUser "user2_hr" -GivenName "User2" -Surname "HR" -Department "HR" -Title "HR Specialist" -EmailAddress "user2_hr@daniel.local"
Set-ADUser "user3_admin" -GivenName "User3" -Surname "Admin" -Department "Admin" -Title "System Administrator" -EmailAddress "user3_admin@daniel.local"
Set-ADUser "user4_general" -GivenName "User4" -Surname "General" -Department "General" -Title "General User" -EmailAddress "user4_general@daniel.local"

# Remove empty OUs
Remove-ADOrganizationalUnit -Identity "OU=Usuarios,OU=DANIEL,DC=daniel,DC=local" -Recursive -Confirm:$false
Remove-ADOrganizationalUnit -Identity "OU=Test,OU=DANIEL,DC=daniel,DC=local" -Recursive -Confirm:$false
