param(
    [Parameter(Mandatory = $true)]
    [string]$RootDir,

    [string]$ComparisonCsvPath = "",

    [switch]$OnlyMissing,

    [switch]$CreateDocumentFolders,

    [switch]$CreateStatusReport
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ComparisonCsvPath)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    $ComparisonCsvPath = Join-Path $workspaceRoot "Inventario_APPMAQ\comparativo_lista_solicitada_vs_appmaq.csv"
}

function ConvertTo-SafeFolderName {
    param([string]$Name)

    $safe = if ([string]::IsNullOrWhiteSpace($Name)) { "_sem_nome" } else { $Name.Trim() }
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, "_")
    }
    $safe = $safe -replace "\s+", " "
    return $safe
}

$documents = @(
    "00_relatorio",
    "01_manual_operador",
    "02_manual_servico_oficina",
    "03_catalogo_pecas",
    "04_manual_manutencao",
    "05_manual_eletrico_hidraulico",
    "06_boletim_treinamento_diagnostico",
    "07_ficha_tecnica_folheto",
    "08_manual_complementar",
    "09_catalogo_pecas_complementar",
    "10_outros_documentos",
    "99_complementar_validar"
)

$rows = @(Import-Csv -LiteralPath $ComparisonCsvPath)
if ($OnlyMissing) {
    $rows = @($rows | Where-Object { $_.status -ne "JA_APARECE_COM_MANUAL_NO_APPMAQ" })
}

$baseDir = Join-Path $RootDir "MANUAIS_APPMAQ"
$tractorDir = Join-Path $baseDir "Trator Agricola"
$originalsDir = Join-Path $baseDir "_ARQUIVOS_ORIGINAIS"
$inventoryDir = Join-Path $baseDir "_INVENTARIO"

New-Item -ItemType Directory -Force -Path $tractorDir, $originalsDir, $inventoryDir | Out-Null

$created = 0
foreach ($row in $rows) {
    $brandDir = Join-Path $tractorDir (ConvertTo-SafeFolderName $row.marca)
    $modelDir = Join-Path $brandDir (ConvertTo-SafeFolderName $row.modelo_solicitado)
    New-Item -ItemType Directory -Force -Path $modelDir | Out-Null

    if ($CreateDocumentFolders) {
        foreach ($docFolder in $documents) {
            New-Item -ItemType Directory -Force -Path (Join-Path $modelDir $docFolder) | Out-Null
        }
    }

    if ($CreateStatusReport) {
        $reportDir = Join-Path $modelDir "00_relatorio"
        New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
        $readmePath = Join-Path $reportDir "status_inicial.txt"
        @(
            "Marca: $($row.marca)"
            "Modelo: $($row.modelo_solicitado)"
            "Status APPMAQ: $($row.status)"
            "Modelo correspondente APPMAQ: $($row.modelo_appmaq_correspondente)"
            "Quantidade de manuais no APPMAQ: $($row.quantidade_manuais_appmaq)"
            "Candidatos parecidos: $($row.candidatos_parecidos)"
            "Observacao: $($row.observacao)"
        ) | Set-Content -LiteralPath $readmePath -Encoding UTF8
    }

    $created++
}

[pscustomobject]@{
    root = $baseDir
    models = $created
    mode = if ($OnlyMissing) { "Somente ausentes no APPMAQ publico" } else { "Todos os modelos do comparativo" }
    document_folders = [bool]$CreateDocumentFolders
    status_reports = [bool]$CreateStatusReport
} | ConvertTo-Json -Depth 3
