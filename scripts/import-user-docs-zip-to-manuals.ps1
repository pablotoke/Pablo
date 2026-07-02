param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [Parameter(Mandatory = $true)]
    [string]$InventoryCsvPath,

    [string]$RootDir = "E:\",

    [string]$LogDir = "",

    [switch]$WhatIfOnly,

    [switch]$IncludeGeneralDocuments
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    $LogDir = Join-Path $workspaceRoot "Inventario_APPMAQ\Arquivos_Usuario"
}

function ConvertTo-SafeFolderName {
    param([string]$Name)
    $safe = if ([string]::IsNullOrWhiteSpace($Name)) { "_sem_nome" } else { $Name.Trim() }
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, "_")
    }
    $safe -replace "\s+", " "
}

function ConvertTo-SafeFileName {
    param([string]$Name)
    $safe = if ([string]::IsNullOrWhiteSpace($Name)) { "_sem_nome.pdf" } else { $Name.Trim() }
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, "_")
    }
    $safe -replace "\s+", " "
}

$baseDir = Join-Path $RootDir "MANUAIS_APPMAQ"
$tractorDir = Join-Path $baseDir "Trator Agricola"
$rows = @(Import-Csv -LiteralPath $InventoryCsvPath)
$rowsToImport = @(
    $rows | Where-Object {
        $_.escopo -eq "modelo" -or ($IncludeGeneralDocuments -and $_.escopo -eq "geral")
    }
)

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
$entries = @{}
try {
    foreach ($entry in $zip.Entries) {
        $entries[$entry.FullName] = $entry
    }

    $actions = New-Object System.Collections.Generic.List[object]

    foreach ($row in $rowsToImport) {
        if (-not $entries.ContainsKey($row.caminho_zip)) {
            $actions.Add([pscustomobject]@{
                action = "missing_in_zip"
                marca = $row.marca
                modelo = $row.modelo
                tipo_documento = $row.tipo_documento
                source = $row.caminho_zip
                destination = ""
                bytes = 0
                status = "erro"
                observacao = "Entrada nao encontrada no ZIP."
            })
            continue
        }

        $entry = $entries[$row.caminho_zip]
        $brandFolder = ConvertTo-SafeFolderName $row.marca
        $modelFolder = ConvertTo-SafeFolderName $row.modelo
        $targetFolder = ConvertTo-SafeFolderName $row.pasta_sugerida
        $fileName = ConvertTo-SafeFileName $row.nome_arquivo

        $destinationDir = Join-Path (Join-Path (Join-Path $tractorDir $brandFolder) $modelFolder) $targetFolder
        $destinationPath = Join-Path $destinationDir $fileName

        $status = "copy"
        if (Test-Path -LiteralPath $destinationPath) {
            $existing = Get-Item -LiteralPath $destinationPath
            if ($existing.Length -eq $entry.Length) {
                $status = "skip_existing_same_size"
            }
            else {
                $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                $ext = [System.IO.Path]::GetExtension($fileName)
                $destinationPath = Join-Path $destinationDir ("$base - usuario_zip_$ext")
                $status = "copy_renamed_collision"
            }
        }

        if (-not $WhatIfOnly -and $status -ne "skip_existing_same_size") {
            New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $false)
        }

        $actions.Add([pscustomobject]@{
            action = if ($WhatIfOnly) { "preview" } else { $status }
            marca = $row.marca
            modelo = $row.modelo
            tipo_documento = $row.tipo_documento
            source = $row.caminho_zip
            destination = $destinationPath
            bytes = $entry.Length
            status = $status
            observacao = $row.observacao
        })
    }
}
finally {
    $zip.Dispose()
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $LogDir "importacao_zip_valtra_$stamp.csv"
$actions | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
    mode = if ($WhatIfOnly) { "preview" } else { "executed" }
    source_zip = $ZipPath
    documents_considered = $rowsToImport.Count
    will_copy_or_copied = @($actions | Where-Object { $_.status -match "^copy" }).Count
    skipped_same_size = @($actions | Where-Object { $_.status -eq "skip_existing_same_size" }).Count
    missing_in_zip = @($actions | Where-Object { $_.status -eq "erro" }).Count
    total_bytes_to_copy = (@($actions | Where-Object { $_.status -match "^copy" }) | Measure-Object bytes -Sum).Sum
    total_mb_to_copy = [math]::Round(((@($actions | Where-Object { $_.status -match "^copy" }) | Measure-Object bytes -Sum).Sum / 1MB), 2)
    log = $logPath
} | ConvertTo-Json -Depth 4
