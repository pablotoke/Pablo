param(
    [string]$RequestedListPath = "C:\Users\Pablo Henrique\.codex\attachments\9086e9c8-2aa2-40aa-8e5c-f7a41ed6af4e\pasted-text.txt",
    [string]$InventoryJsonPath = "",
    [string]$InventoryCsvPath = "",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputDir) -or [string]::IsNullOrWhiteSpace($InventoryJsonPath) -or [string]::IsNullOrWhiteSpace($InventoryCsvPath)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    if ([string]::IsNullOrWhiteSpace($OutputDir)) {
        $OutputDir = Join-Path $workspaceRoot "Inventario_APPMAQ"
    }
    if ([string]::IsNullOrWhiteSpace($InventoryJsonPath)) {
        $InventoryJsonPath = Join-Path $OutputDir "appmaq_tratores_com_manuais.json"
    }
    if ([string]::IsNullOrWhiteSpace($InventoryCsvPath)) {
        $InventoryCsvPath = Join-Path $OutputDir "appmaq_tratores_com_manuais.csv"
    }
}

function Normalize-Text {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $normalized = $Text.Trim().Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($char in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }

    return $builder.ToString().ToUpperInvariant()
}

function Normalize-Key {
    param([string]$Text)
    (Normalize-Text $Text) -replace "[^A-Z0-9]", ""
}

function Read-RequestedModels {
    param([string]$Path)

    $text = Get-Content -Raw -LiteralPath $Path
    $lines = $text -split "`r?`n"
    $currentBrand = $null
    $items = New-Object System.Collections.Generic.List[object]

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if ($trimmed -match "^### 12\.1") {
            $currentBrand = "NEW HOLLAND"
            continue
        }
        if ($trimmed -match "^### 12\.2") {
            $currentBrand = "MASSEY FERGUSON"
            continue
        }
        if ($trimmed -match "^### 12\.3") {
            $currentBrand = "VALTRA"
            continue
        }
        if ($trimmed -match "^### " -or ($trimmed -match "^---" -and $currentBrand)) {
            $currentBrand = $null
            continue
        }

        if ($currentBrand -and $trimmed -and $trimmed -notmatch "^#" -and $trimmed -notmatch "^---") {
            $items.Add([pscustomobject]@{
                marca = $currentBrand
                modelo = $trimmed
                marca_key = Normalize-Key $currentBrand
                modelo_key = Normalize-Key $trimmed
            })
        }
    }

    $items
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$requested = @(Read-RequestedModels $RequestedListPath)
$inventory = @(Import-Csv -LiteralPath $InventoryCsvPath)

$inventoryExpanded = @(
    foreach ($item in $inventory) {
        [pscustomobject]@{
            marca = $item.marca
            modelo = $item.modelo
            marca_key = Normalize-Key $item.marca
            modelo_key = Normalize-Key $item.modelo
            quantidade_manuais_appmaq = $item.quantidade_manuais_appmaq
            modelo_id = $item.modelo_id
        }
    }
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($requestedItem in $requested) {
    $brandModels = @($inventoryExpanded | Where-Object { $_.marca_key -eq $requestedItem.marca_key })
    $exact = $brandModels | Where-Object { $_.modelo_key -eq $requestedItem.modelo_key } | Select-Object -First 1

    $candidates = @()
    if (-not $exact) {
        $candidates = @(
            $brandModels |
                Where-Object {
                    $_.modelo_key.StartsWith($requestedItem.modelo_key) -or
                    $requestedItem.modelo_key.StartsWith($_.modelo_key)
                } |
                Sort-Object modelo |
                Select-Object -First 5
        )
    }

    $results.Add([pscustomobject]@{
        marca = $requestedItem.marca
        modelo_solicitado = $requestedItem.modelo
        status = if ($exact) { "JA_APARECE_COM_MANUAL_NO_APPMAQ" } else { "NAO_APARECE_COM_MANUAL_NA_CONSULTA_PUBLICA" }
        modelo_appmaq_correspondente = if ($exact) { $exact.modelo } else { "" }
        quantidade_manuais_appmaq = if ($exact) { $exact.quantidade_manuais_appmaq } else { 0 }
        candidatos_parecidos = if ($candidates.Count) { ($candidates.modelo -join "; ") } else { "" }
        observacao = if ($exact) { "Encontrado por marca e modelo normalizados." } elseif ($candidates.Count) { "Ha modelo parecido na Appmaq; validar sufixo/versao antes de considerar cadastrado." } else { "Nao apareceu na consulta publica de manuais." }
    })
}

$csvPath = Join-Path $OutputDir "comparativo_lista_solicitada_vs_appmaq.csv"
$mdPath = Join-Path $OutputDir "comparativo_lista_solicitada_vs_appmaq.md"

$results | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$found = @($results | Where-Object { $_.status -eq "JA_APARECE_COM_MANUAL_NO_APPMAQ" })
$missing = @($results | Where-Object { $_.status -ne "JA_APARECE_COM_MANUAL_NO_APPMAQ" })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Comparativo - lista solicitada x APPMAQ publico")
$lines.Add("")
$lines.Add("Total na lista solicitada: $($results.Count)")
$lines.Add("Ja aparecem com manual no APPMAQ: $($found.Count)")
$lines.Add("Nao apareceram na consulta publica de manuais: $($missing.Count)")
$lines.Add("")

$lines.Add("## Nao apareceram na consulta publica")
$lines.Add("")
$missing |
    Group-Object marca |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("### $($_.Name)")
        foreach ($item in ($_.Group | Sort-Object modelo_solicitado)) {
            $suffix = if ($item.candidatos_parecidos) { " | parecido: $($item.candidatos_parecidos)" } else { "" }
            $lines.Add("- $($item.modelo_solicitado)$suffix")
        }
        $lines.Add("")
    }

$lines.Add("## Ja aparecem com manual no APPMAQ")
$lines.Add("")
$found |
    Group-Object marca |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("### $($_.Name)")
        foreach ($item in ($_.Group | Sort-Object modelo_solicitado)) {
            $lines.Add("- $($item.modelo_solicitado): $($item.quantidade_manuais_appmaq) manual(is)")
        }
        $lines.Add("")
    }

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    requested = $results.Count
    found = $found.Count
    missing = $missing.Count
    csv = $csvPath
    markdown = $mdPath
} | ConvertTo-Json -Depth 4
