param(
    [string]$CoverageCsvPath = "",
    [string]$RootDir = "E:\",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($CoverageCsvPath) -or [string]::IsNullOrWhiteSpace($OutputDir)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    if ([string]::IsNullOrWhiteSpace($CoverageCsvPath)) {
        $CoverageCsvPath = Join-Path $workspaceRoot "Inventario_APPMAQ\appmaq_admin_cobertura_modelos_solicitados.csv"
    }
    if ([string]::IsNullOrWhiteSpace($OutputDir)) {
        $OutputDir = Join-Path $workspaceRoot "Inventario_APPMAQ"
    }
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

function Test-TrueString {
    param([string]$Value)
    return $Value -eq "True" -or $Value -eq "true" -or $Value -eq "1"
}

function Get-LocalDocumentCount {
    param(
        [string]$ModelDir,
        [string]$Folder
    )

    $path = Join-Path $ModelDir $Folder
    if (-not (Test-Path -LiteralPath $path)) {
        return 0
    }

    @(
        Get-ChildItem -LiteralPath $path -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Extension -match "^\.(pdf|doc|docx|xls|xlsx|zip|rar)$"
            }
    ).Count
}

$definitions = @(
    [pscustomobject]@{
        tipo = "manual_operador"
        pasta = "01_manual_operador"
        campo_admin = "tem_manual_operador"
        prioridade = 1
        consulta = "{marca} {modelo} manual operador operator manual"
    }
    [pscustomobject]@{
        tipo = "manual_servico_oficina"
        pasta = "02_manual_servico_oficina"
        campo_admin = "tem_manual_servico_oficina"
        prioridade = 1
        consulta = "{marca} {modelo} manual servico oficina service workshop repair"
    }
    [pscustomobject]@{
        tipo = "catalogo_pecas"
        pasta = "03_catalogo_pecas"
        campo_admin = "tem_catalogo_pecas"
        prioridade = 1
        consulta = "{marca} {modelo} catalogo pecas parts catalog"
    }
    [pscustomobject]@{
        tipo = "manual_manutencao"
        pasta = "04_manual_manutencao"
        campo_admin = "tem_manual_manutencao"
        prioridade = 2
        consulta = "{marca} {modelo} manual manutencao maintenance"
    }
    [pscustomobject]@{
        tipo = "manual_eletrico_hidraulico"
        pasta = "05_manual_eletrico_hidraulico"
        campo_admin = "tem_manual_eletrico_hidraulico"
        prioridade = 2
        consulta = "{marca} {modelo} manual eletrico hidraulico diagrama electrical hydraulic"
    }
    [pscustomobject]@{
        tipo = "treinamento_diagnostico"
        pasta = "06_boletim_treinamento_diagnostico"
        campo_admin = "tem_treinamento_diagnostico"
        prioridade = 3
        consulta = "{marca} {modelo} treinamento diagnostico calibracao training diagnostic"
    }
    [pscustomobject]@{
        tipo = "ficha_tecnica_folheto"
        pasta = "07_ficha_tecnica_folheto"
        campo_admin = "tem_ficha_tecnica_folheto"
        prioridade = 3
        consulta = "{marca} {modelo} ficha tecnica especificacoes folheto brochure specifications"
    }
    [pscustomobject]@{
        tipo = "manual_complementar"
        pasta = "08_manual_complementar"
        campo_admin = ""
        prioridade = 4
        consulta = "{marca} {modelo} manual complementar guia tecnico"
    }
    [pscustomobject]@{
        tipo = "catalogo_pecas_complementar"
        pasta = "09_catalogo_pecas_complementar"
        campo_admin = ""
        prioridade = 4
        consulta = "{marca} {modelo} catalogo pecas complementar spare parts"
    }
)

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$baseDir = Join-Path $RootDir "MANUAIS_APPMAQ"
$tractorDir = Join-Path $baseDir "Trator Agricola"
$rows = @(Import-Csv -LiteralPath $CoverageCsvPath)
$queue = New-Object System.Collections.Generic.List[object]

foreach ($row in $rows) {
    $brand = $row.marca
    $model = $row.modelo
    $modelDir = Join-Path (Join-Path $tractorDir (ConvertTo-SafeFolderName $brand)) (ConvertTo-SafeFolderName $model)
    $totalAdmin = [int]$row.total_manuais_admin

    foreach ($definition in $definitions) {
        $hasAdmin = $false
        $requiredByAdmin = $true

        if (-not [string]::IsNullOrWhiteSpace($definition.campo_admin)) {
            $hasAdmin = Test-TrueString ($row.($definition.campo_admin))
        }
        else {
            $requiredByAdmin = $totalAdmin -eq 0 -or -not [string]::IsNullOrWhiteSpace($row.faltam_prioritarios)
        }

        $localCount = Get-LocalDocumentCount -ModelDir $modelDir -Folder $definition.pasta
        $shouldCollect = $requiredByAdmin -and -not $hasAdmin

        if ($shouldCollect) {
            $priority = $definition.prioridade
            if ($totalAdmin -eq 0 -and $definition.prioridade -le 3) {
                $priority = 1
            }
            elseif ($localCount -gt 0) {
                $priority = [Math]::Max(5, $priority)
            }

            $queue.Add([pscustomobject]@{
                prioridade = $priority
                marca = $brand
                modelo = $model
                tipo_documento = $definition.tipo
                pasta_destino = Join-Path $modelDir $definition.pasta
                total_manuais_admin = $totalAdmin
                existe_no_admin = $hasAdmin
                arquivos_locais = $localCount
                status_coleta = if ($localCount -gt 0) { "baixado_local_validar_appmaq" } else { "pesquisar" }
                consulta_sugerida = ($definition.consulta -replace "\{marca\}", $brand -replace "\{modelo\}", $model)
                candidatos_parecidos_appmaq = $row.candidatos_parecidos
            })
        }
    }
}

$csvPath = Join-Path $OutputDir "fila_coleta_documentos_tratores.csv"
$mdPath = Join-Path $OutputDir "fila_coleta_documentos_tratores.md"

$queue |
    Sort-Object prioridade, marca, modelo, tipo_documento |
    Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Fila de coleta de documentos - tratores")
$lines.Add("")
$lines.Add("Modelos avaliados: $($rows.Count)")
$lines.Add("Itens na fila: $($queue.Count)")
$lines.Add("")
$lines.Add("## Por prioridade")
$queue |
    Group-Object prioridade |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("- Prioridade $($_.Name): $($_.Count)")
    }
$lines.Add("")
$lines.Add("## Por tipo")
$queue |
    Group-Object tipo_documento |
    Sort-Object Name |
    ForEach-Object {
        $lines.Add("- $($_.Name): $($_.Count)")
    }
$lines.Add("")
$lines.Add("## Primeiros itens")
$queue |
    Sort-Object prioridade, marca, modelo, tipo_documento |
    Select-Object -First 80 |
    ForEach-Object {
        $lines.Add("- P$($_.prioridade) | $($_.marca) $($_.modelo) | $($_.tipo_documento) | $($_.status_coleta)")
    }

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    modelos = $rows.Count
    itens_fila = $queue.Count
    csv = $csvPath
    markdown = $mdPath
} | ConvertTo-Json -Depth 3
