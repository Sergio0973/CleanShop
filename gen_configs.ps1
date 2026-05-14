$base = "C:\Proyecto Personales\CSharp\netcore-main\netcore-main\SistemaGestionTiquetesAereos"
$legacy = "c:\Users\sergi\OneDrive\Escritorio\ProyectoAPI\SistemaGestionTiquetesAereos"
$configDir = "$base\Infrastructure\Configurations"

if (!(Test-Path $configDir)) { New-Item -ItemType Directory -Force -Path $configDir }

$legacyConfigs = Get-ChildItem -Path $legacy -Filter "*Configuration.cs" -Recurse

foreach ($lc in $legacyConfigs) {
    $raw = Get-Content $lc.FullName -Raw
    $entName = ""
    if ($lc.Name -match "^(\w+)(?:Entity)?Configuration\.cs$") { $entName = $matches[1] }
    if ($entName -eq "StaffMember") { $entName = "Staff" }
    if ($entName -eq "StaffAvailabilityBlock") { $entName = "StaffAvailability" }
    
    $entFile = "$base\Domain\Entities\$($entName)Entity.cs"
    if (!(Test-Path $entFile)) { continue }
    
    $entContent = Get-Content $entFile -Raw
    $idVO = if ($entContent -match "BaseEntity<(\w+)>") { $matches[1] } else { "" }
    $table = if ($raw -match "builder\.ToTable\(\s*[`"']([^`"']+)`") { $matches[1] } else { $entName.ToLower() }
    
    $uList = New-Object System.Collections.Generic.List[string]
    $uList.Add("us" + "ing Domain.Entities;")
    $uList.Add("us" + "ing Microsoft.EntityFrameworkCore;")
    $uList.Add("us" + "ing Microsoft.EntityFrameworkCore.Metadata.Builders;")
    
    $body = "        builder.ToTable(`"$table`");`n        builder.HasKey(x => x.Id);`n"
    $body += "        builder.Property(x => x.Id).HasConversion(id => id.Value, v => $idVO.Create(v)).HasColumnName(`"id`").ValueGeneratedOnAdd();`n"
    
    $propMatches = [regex]::Matches($entContent, "public (\w+(?:\.\w+)*) (\w+) \{ get; set; \}")
    $mappings = [regex]::Matches($raw, "\.Property\(x => x\.(\w+)\)\s*\.HasColumnName\(\s*[`"']([^`"']+)`")
    
    foreach ($pMatch in $propMatches) {
        $pType = $pMatch.Groups[1].Value
        $pName = $pMatch.Groups[2].Value
        if ($pName -eq "Id") { continue }
        
        $colName = $pName.ToLower()
        foreach ($m in $mappings) {
            if ($m.Groups[1].Value.ToLower() -eq $pName.ToLower() -or $pName.Contains($m.Groups[1].Value)) {
                $colName = $m.Groups[2].Value
                break
            }
        }
        
        $voClass = $pType.Split('.')[-1]
        if ($pType -match "\.") {
            $ns = $pType.Substring(0, $pType.LastIndexOf('.'))
            $line = "us" + "ing $ns;"
            if (!$uList.Contains($line)) { $uList.Add($line) }
        }
        $body += "        builder.Property(x => x.$pName).HasConversion(v => v!.Value, v => $voClass.Create(v)).HasColumnName(`"$colName`");`n"
    }

    $finalUsings = [string]::Join("`n", $uList)
    $fileContent = "$finalUsings`n`nnamespace Infrastructure.Configurations;`n`npublic class $($entName)Configuration : IEntityTypeConfiguration<$($entName)Entity>`n{`n    public void Configure(EntityTypeBuilder<$($entName)Entity> builder)`n    {`n$body    }`n}"
    Set-Content -Path "$configDir\$($entName)Configuration.cs" -Value $fileContent
}
