param(
    [string]$RequestedListPath = "C:\Users\Pablo Henrique\.codex\attachments\9086e9c8-2aa2-40aa-8e5c-f7a41ed6af4e\pasted-text.txt",
    [string]$AdminTractorCsvPath = "",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputDir) -or [string]::IsNullOrWhiteSpace($AdminTractorCsvPath)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    if ([string]::IsNullOrWhiteSpace($OutputDir)) {
        $OutputDir = Join-Path $workspaceRoot "Inventario_APPMAQ"
    }
    if ([string]::IsNullOrWhiteSpace($AdminTractorCsvPath)) {
        $AdminTractorCsvPath = Join-Path $OutputDir "appmaq_admin_manuais_tratores.csv"
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

function Classify-Manual {
    param([string]$Title)

    $text = Normalize-Text $Title
    $types = New-Object System.Collections.Generic.List[string]

    if ($text -match "OPERADOR|OPERACAO|OPERACIONAL|GUIA DE REFERENCIA RAPIDA|GUIA RAPIDO") {
        $types.Add("manual_operador")
    }
    if ($text -match "CATALOGO.*PECA|CATALOGO.*PECAS|PECAS DE REPOSICAO|REPOSICAO.*PECA|PARTS") {
        $types.Add("catalogo_pecas")
    }
    if ($text -match "SERVICO|OFICINA|REPARACAO|REPARO|WORKSHOP|SERVICE MANUAL") {
        $types.Add("manual_servico_oficina")
    }
    if ($text -match "MANUTENCAO|MANUTENCAO E INSPECAO|MAINTENANCE") {
        $types.Add("manual_manutencao")
    }
    if ($text -match "ELETRIC|ELETRICO|ELETRICA|HIDRAULIC|HIDRAULICO|HIDRAULICA|DIAGRAMA|CIRCUITO") {
        $types.Add("manual_eletrico_hidraulico")
    }
    if ($text -match "FICHA|FOLHETO|ESPECIFICACAO|ESPECIFICACOES|TECNICA|TECNICO|RELATORIO TECNICO") {
        $types.Add("ficha_tecnica_folheto")
    }
    if ($text -match "TREINAMENTO|DIAGNOSTICO|CALIBRACAO|CODIGO|FALHA") {
        $types.Add("treinamento_diagnostico")
    }

    if ($types.Count -eq 0) {
        $types.Add("outros")
    }

    $types
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$requested = @(Read-RequestedModels $RequestedListPath)
$adminRows = @(Import-Csv -LiteralPath $AdminTractorCsvPath)
$adminRowsExpanded = @(
    foreach ($row in $adminRows) {
        $classes = @(Classify-Manual ($row.nome + " " + $row.descricao))
        [pscustomobject]@{
            marca = $row.marca
            modelo = $row.modelo
            nome = $row.nome
            descricao = $row.descricao
            tem_pdf = $row.tem_pdf
            pdf_url = $row.pdf_url
            marca_key = Normalize-Key $row.marca
            modelo_key = Normalize-Key $row.modelo
            classes = $classes
        }
    }
)

$coverage = New-Object System.Collections.Generic.List[object]

foreach ($item in $requested) {
    $matches = @($adminRowsExpanded | Where-Object {
        $_.marca_key -eq $item.marca_key -and $_.modelo_key -eq $item.modelo_key
    })

    $sameBrand = @($adminRowsExpanded | Where-Object { $_.marca_key -eq $item.marca_key })
    $similar = @()
    if ($matches.Count -eq 0) {
        $similar = @(
            $sameBrand |
                Where-Object {
                    $_.modelo_key.StartsWith($item.modelo_key) -or
                    $item.modelo_key.StartsWith($_.modelo_key)
                } |
                Select-Object -ExpandProperty modelo -Unique |
                Sort-Object |
                Select-Object -First 5
        )
    }

    $allClasses = @($matches | ForEach-Object { $_.classes } | ForEach-Object { $_ }) | Sort-Object -Unique
    $hasOperator = $allClasses -contains "manual_operador"
    $hasParts = $allClasses -contains "catalogo_pecas"
    $hasService = $allClasses -contains "manual_servico_oficina"
    $hasMaintenance = $allClasses -contains "manual_manutencao"
    $hasElectricHydraulic = $allClasses -contains "manual_eletrico_hidraulico"
    $hasSpec = $allClasses -contains "ficha_tecnica_folheto"
    $hasTrainingDiagnostic = $allClasses -contains "treinamento_diagnostico"

    $missingCore = New-Object System.Collections.Generic.List[string]
    if (-not $hasOperator) { $missingCore.Add("manual_operador") }
    if (-not $hasService) { $missingCore.Add("manual_servico_oficina") }
    if (-not $hasParts) { $missingCore.Add("catalogo_pecas") }

    $coverage.Add([pscustomobject]@{
        marca = $item.marca
        modelo = $item.modelo
        total_manuais_admin = $matches.Count
        tem_manual_operador = $hasOperator
        tem_manual_servico_oficina = $hasService
        tem_catalogo_pecas = $hasParts
        tem_manual_manutencao = $hasMaintenance
        tem_manual_eletrico_hidraulico = $hasElectricHydraulic
        tem_ficha_tecnica_folheto = $hasSpec
        tem_treinamento_diagnostico = $hasTrainingDiagnostic
        faltam_prioritarios = ($missingCore -join "; ")
        candidatos_parecidos = ($similar -join "; ")
        titulos_admin = (($matches | Select-Object -ExpandProperty nome) -join " | ")
    })
}

$csvPath = Join-Path $OutputDir "appmaq_admin_cobertura_modelos_solicitados.csv"
$mdPath = Join-Path $OutputDir "appmaq_admin_cobertura_modelos_solicitados.md"

$coverage | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$missingAnyCore = @($coverage | Where-Object { $_.faltam_prioritarios })
$missingAll = @($coverage | Where-Object { $_.total_manuais_admin -eq 0 })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Cobertura Admin APPMAQ - Modelos Solicitados")
$lines.Add("")
$lines.Add("Total de modelos solicitados: $($coverage.Count)")
$lines.Add("Modelos sem nenhum manual no admin: $($missingAll.Count)")
$lines.Add("Modelos que ainda faltam algum prioritario (operador/servico/pecas): $($missingAnyCore.Count)")
$lines.Add("")

$lines.Add("## Sem nenhum manual no admin")
$lines.Add("")
$missingAll |
    Group-Object marca |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("### $($_.Name)")
        foreach ($row in ($_.Group | Sort-Object modelo)) {
            $suffix = if ($row.candidatos_parecidos) { " | parecido no admin: $($row.candidatos_parecidos)" } else { "" }
            $lines.Add("- $($row.modelo)$suffix")
        }
        $lines.Add("")
    }

$lines.Add("## Faltam documentos prioritarios")
$lines.Add("")
$missingAnyCore |
    Group-Object marca |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("### $($_.Name)")
        foreach ($row in ($_.Group | Sort-Object modelo)) {
            $lines.Add("- $($row.modelo): faltam $($row.faltam_prioritarios) | cadastrados: $($row.total_manuais_admin)")
        }
        $lines.Add("")
    }

$lines.Add("## Cobertura por modelo")
$lines.Add("")
$coverage |
    Group-Object marca |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("### $($_.Name)")
        foreach ($row in ($_.Group | Sort-Object modelo)) {
            $flags = @(
                "operador=$($row.tem_manual_operador)",
                "servico=$($row.tem_manual_servico_oficina)",
                "pecas=$($row.tem_catalogo_pecas)",
                "manutencao=$($row.tem_manual_manutencao)",
                "eletrico_hidraulico=$($row.tem_manual_eletrico_hidraulico)",
                "ficha=$($row.tem_ficha_tecnica_folheto)"
            ) -join "; "
            $lines.Add("- $($row.modelo): $($row.total_manuais_admin) manual(is) | $flags")
        }
        $lines.Add("")
    }

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    requested = $coverage.Count
    no_manuals = $missingAll.Count
    missing_core = $missingAnyCore.Count
    csv = $csvPath
    markdown = $mdPath
} | ConvertTo-Json -Depth 4
