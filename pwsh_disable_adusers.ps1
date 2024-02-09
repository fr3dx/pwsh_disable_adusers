# A szkript letiltja a felhasznalot, 
# kitolti a description mezot es 
# csak a Domain Users csoporttagsaga marad

# Parancssori argumentum: POBoxValue, értéke adószám, példa: .\pwsh_disable_adusers.ps1 -POBoxValue 00000000
param(
    [Parameter(Mandatory=$true)]
    [int]$POBoxValue
)

# Adószám és formátum ellenorzés
if (-not ($POBoxValue -match '^\d{8}$')) {
    Write-Host "Hibás adószám formátum. Az adószámnak 8 számjegybol kell állnia!" -ForegroundColor Red
    Write-Host "Elfogadott formátum példa: .\pwsh_disable_adusers.ps1 -POBoxValue 00000000" -ForegroundColor Green
    exit
}

# Felhasználó keresés
$ADuser = Get-ADUser -Filter {POBox -eq $POBoxValue} -Properties * | Select-Object -Property Name, SamAccountName, UserPrincipalName, DistinguishedName, POBox, MemberOf, Enabled

# Felhasználó fiók ellenorzés
if ($ADuser) {
    # Felhasználó státusz ellenorzés
    if (-not $ADuser.Enabled) {
        Write-Host "A felhasználó már le van tiltva." -ForegroundColor Yellow
        exit
    }
    Write-Host "Megtaláltam a felhasználót:`n$ADuser"

    # Interaktív prompt
    $Confirmation = Read-Host "Biztosan le akarod tiltani a felhasználót? (I/N)"
    
    if ($Confirmation -eq "I") {
        # Felhasználó letiltás
        Disable-ADAccount -Identity $ADuser.SamAccountName

        # Felhasználó description mezo frissítés
        $descriptionField = "Letiltva: $(Get-Date -Format 'yyyy.MM.dd')"
        Set-ADUser -Identity $ADuser.SamAccountName -Description $descriptionField

        Write-Host "A felhasználó sikeresen letiltva és a description mezo frissítve." -ForegroundColor Yellow

	# Felhasználó eltávolítása minden csoportból, kivéve a Domain Users
	$UserGroups = Get-ADPrincipalGroupMembership -Identity $ADuser.SamAccountName | Select-Object -ExpandProperty Name

	foreach ($Group in $UserGroups) {
    		if ($Group -ne "Domain Users") {
        	Write-Host "A felhasználó eltávolítva a következo csoportból: $Group"
        	Remove-ADGroupMember -Identity $Group -Members $ADuser.SamAccountName -Confirm:$false
    	}
}
    } else {
        Write-Host "A felhasználó letiltása megszakítva." -ForegroundColor Red
    }
} else {
    Write-Host "Nem találtam felhasználót: $AdoSzam adószámmal."
}
