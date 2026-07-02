param(
    [string]$QueueCsvPath = "",
    [string]$CacheDir = "",
    [int]$BatchSize = 5,
    [int]$MaxPriority = 1
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptRoot

if ([string]::IsNullOrWhiteSpace($QueueCsvPath)) {
    $QueueCsvPath = Join-Path $workspaceRoot "Inventario_APPMAQ\fila_coleta_documentos_tratores.csv"
}
if ([string]::IsNullOrWhiteSpace($CacheDir)) {
    $CacheDir = Join-Path $workspaceRoot "Inventario_APPMAQ\Pesquisa_Cache"
}

if (-not (Test-Path -LiteralPath $CacheDir)) {
    & (Join-Path $scriptRoot "initialize-research-cache.ps1") -OutputDir $CacheDir | Out-Null
}

function Import-CacheKeys {
    param(
        [string]$Path,
        [string]$StatusColumn
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{}
    }

    $table = @{}
    $rows = @(Import-Csv -LiteralPath $Path)
    foreach ($row in $rows) {
        if (-not $row.marca -or -not $row.modelo -or -not $row.tipo_documento) {
            continue
        }
        $key = "$($row.marca)|$($row.modelo)|$($row.tipo_documento)"
        if (-not $table.ContainsKey($key)) {
            $table[$key] = New-Object System.Collections.Generic.List[string]
        }
        $status = if ($StatusColumn -and $row.PSObject.Properties.Name -contains $StatusColumn) { $row.$StatusColumn } else { "" }
        $table[$key].Add($status)
    }
    return $table
}

$candidateKeys = Import-CacheKeys -Path (Join-Path $CacheDir "candidatos_documentos.csv") -StatusColumn "status"
$validationKeys = Import-CacheKeys -Path (Join-Path $CacheDir "validacoes_documentos.csv") -StatusColumn "resultado"
$downloadKeys = Import-CacheKeys -Path (Join-Path $CacheDir "downloads_documentos.csv") -StatusColumn "status"
$rejectedKeys = Import-CacheKeys -Path (Join-Path $CacheDir "rejeitados_documentos.csv") -StatusColumn "motivo"

$queue = @(Import-Csv -LiteralPath $QueueCsvPath)
$selected = New-Object System.Collections.Generic.List[object]

foreach ($row in ($queue | Sort-Object {[int]$_.prioridade}, marca, modelo, tipo_documento)) {
    if ([int]$row.prioridade -gt $MaxPriority) {
        continue
    }
    if ($row.status_coleta -ne "pesquisar") {
        continue
    }

    $key = "$($row.marca)|$($row.modelo)|$($row.tipo_documento)"
    $hasUsefulCache =
        $downloadKeys.ContainsKey($key) -or
        $validationKeys.ContainsKey($key) -or
        $candidateKeys.ContainsKey($key)

    if ($hasUsefulCache) {
        continue
    }

    $selected.Add($row)
    if ($selected.Count -ge $BatchSize) {
        break
    }
}

$batchId = "batch_" + (Get-Date).ToString("yyyyMMdd_HHmmss")
$batchPath = Join-Path $CacheDir "$batchId.csv"
$selected | Export-Csv -LiteralPath $batchPath -NoTypeInformation -Encoding UTF8

$lotRow = [pscustomobject]@{
    data_lote = (Get-Date).ToString("s")
    batch_id = $batchId
    tamanho_lote = $selected.Count
    status = "selecionado"
    observacao = "Lote selecionado ignorando itens com cache local."
}
$lotRow | Export-Csv -LiteralPath (Join-Path $CacheDir "lotes_pesquisa.csv") -Append -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
    batch_id = $batchId
    batch_size = $selected.Count
    batch_file = $batchPath
    items = $selected
} | ConvertTo-Json -Depth 5
