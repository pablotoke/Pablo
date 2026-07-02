param(
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    $OutputDir = Join-Path $workspaceRoot "Inventario_APPMAQ"
}

$apiBase = "https://api.appmaq.com.br"
$headers = @{
    Accept = "application/json"
    "User-Agent" = "AppMaq manual inventory collector"
}

function Get-AppMaqJson {
    param([Parameter(Mandatory = $true)][string]$Path)

    $uri = if ($Path.StartsWith("http")) { $Path } else { "$apiBase$Path" }
    Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 60
}

function ConvertTo-SafeName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return "_sem_nome"
    }

    $safe = $Name.Trim()
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, "_")
    }
    $safe = $safe -replace "\s+", " "
    return $safe
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$types = Get-AppMaqJson "/vehicles/public/types/actives-with-children/?destination=2"
$tractorType = $types | Where-Object {
    $_.slug -eq "trator-agricola" -or $_.description -like "Trator Agr*"
} | Select-Object -First 1

if (-not $tractorType) {
    throw "Tipo 'Trator Agricola' nao encontrado na API publica."
}

$brands = Get-AppMaqJson "/vehicles/public/brands/types/$($tractorType.id)/actives-with-children?destination=1"
$inventory = New-Object System.Collections.Generic.List[object]

foreach ($brand in $brands) {
    Write-Host "Marca: $($brand.name)"
    $models = Get-AppMaqJson "/vehicles/public/models/types/$($tractorType.id)/brands/$($brand.id)/actives-with-children?destination=1"

    foreach ($model in $models) {
        Write-Host "  Modelo: $($model.model)"
        $manuals = Get-AppMaqJson "/vehicles/public/manuals/models/$($model.id)"
        if (-not $manuals) {
            $manuals = @()
        }

        $inventory.Add([pscustomobject]@{
            categoria = $tractorType.description
            categoria_slug = $tractorType.slug
            categoria_id = $tractorType.id
            marca = $brand.name
            marca_id = $brand.id
            modelo = $model.model
            modelo_id = $model.id
            quantidade_manuais_appmaq = @($manuals).Count
            manuais_appmaq = @($manuals)
        })
    }
}

$jsonPath = Join-Path $OutputDir "appmaq_tratores_com_manuais.json"
$csvPath = Join-Path $OutputDir "appmaq_tratores_com_manuais.csv"
$mdPath = Join-Path $OutputDir "appmaq_tratores_com_manuais.md"

$inventory |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $jsonPath -Encoding UTF8

$inventory |
    Select-Object categoria, marca, modelo, quantidade_manuais_appmaq, categoria_id, marca_id, modelo_id |
    Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Inventario publico APPMAQ - Tratores com manuais")
$lines.Add("")
$lines.Add("Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")
$lines.Add("Categoria: $($tractorType.description)")
$lines.Add("Total de marcas: $(@($brands).Count)")
$lines.Add("Total de modelos com manuais: $($inventory.Count)")
$lines.Add("Total de documentos listados: $(($inventory | Measure-Object -Property quantidade_manuais_appmaq -Sum).Sum)")
$lines.Add("")

$inventory |
    Group-Object marca |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("## $($_.Name)")
        $lines.Add("")
        $_.Group |
            Sort-Object modelo |
            ForEach-Object {
                $lines.Add("- $($_.modelo): $($_.quantidade_manuais_appmaq) manual(is) no APPMAQ")
                foreach ($manual in $_.manuais_appmaq) {
                    $manualName = if ($manual.name) { $manual.name } else { "(sem nome)" }
                    $lines.Add("  - $manualName")
                }
            }
        $lines.Add("")
    }

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    outputDir = $OutputDir
    json = $jsonPath
    csv = $csvPath
    markdown = $mdPath
    brands = @($brands).Count
    models = $inventory.Count
    manuals = ($inventory | Measure-Object -Property quantidade_manuais_appmaq -Sum).Sum
} | ConvertTo-Json -Depth 5
