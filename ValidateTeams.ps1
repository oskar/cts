param (
    [Parameter(Mandatory=$true)]
    [string]
    $Path
)

$CurrentYear = Get-Date -Format yyyy
$ClassPattern = "HD90|HD110"

function GetName($TeamEntryPerson) {
  $Name = $TeamEntryPerson.Person.Name
  "$($Name.Given) $($Name.Family)"
}

function GetAge($TeamEntryPerson) {
  $BirthYear = $TeamEntryPerson.Person.BirthDate.Substring(0, 4)
  [int]($CurrentYear - $BirthYear)
}

function GetRunner($TeamEntryPerson) {
  $Age = GetAge $TeamEntryPerson
  $Gender = $TeamEntryPerson.Person.sex
  @{ Name = GetName $TeamEntryPerson;
     Age = $Age;
     Gender = $Gender;
     CompensatedAge = $Age + $(if ($Gender -eq "F") { 10 } else { 0 })}
}

Write-Host "Checking classes: $ClassPattern"

$EntriesXml = [xml](Get-Content $Path)

$Teams = $EntriesXml.EntryList.TeamEntry | Where-Object { $_.Class.Name -match $ClassPattern}

Write-Host "Found $($Teams.Count) teams"

$InvalidTeams = $Teams | Select-Object `
    @{Name="Class"; Expression={$_.Class.Name}}, `
    Name, `
    @{Name="Leg1"; Expression={GetRunner $_.TeamEntryPerson[0]}}, `
    @{Name="Leg2"; Expression={GetRunner $_.TeamEntryPerson[1]}} `
  | Where-Object { ($_.Leg1.CompensatedAge + $_.Leg2.CompensatedAge) -lt [int]$_.Class.Substring(2) }`
  | Select-Object `
    Class, `
    Name, `
    @{Name="Leg1Name"; Expression={$_.Leg1.Name}}, `
    @{Name="Leg1Age"; Expression={$_.Leg1.Age}}, `
    @{Name="Leg2Name"; Expression={$_.Leg2.Name}}, `
    @{Name="Leg2Age"; Expression={$_.Leg2.Age}} `

if ($InvalidTeams) {
  $InvalidTeams
} else {
  Write-Host "No invalid teams"
}