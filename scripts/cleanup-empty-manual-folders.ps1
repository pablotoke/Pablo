param(
    [string]$RootDir = "E:\",
    [switch]$WhatIfOnly
)

$ErrorActionPreference = "Stop"

$baseDir = Join-Path $RootDir "MANUAIS_APPMAQ"
$tractorDir = Join-Path $baseDir "Trator Agricola"

if (-not (Test-Path -LiteralPath $tractorDir)) {
    throw "Pasta nao encontrada: $tractorDir"
}

$managedFolders = @(
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

function Get-ChildItemSafe {
    param([string]$Path)
    @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
}

function Test-OnlyGeneratedStatusReport {
    param([string]$Path)

    $children = Get-ChildItemSafe $Path
    if ($children.Count -ne 1) {
        return $false
    }

    return (-not $children[0].PSIsContainer) -and $children[0].Name -eq "status_inicial.txt"
}

$actions = New-Object System.Collections.Generic.List[object]

$brandDirs = @(Get-ChildItem -LiteralPath $tractorDir -Directory -ErrorAction SilentlyContinue)
foreach ($brandDir in $brandDirs) {
    $modelDirs = @(Get-ChildItem -LiteralPath $brandDir.FullName -Directory -ErrorAction SilentlyContinue)
    foreach ($modelDir in $modelDirs) {
        foreach ($folderName in $managedFolders) {
            $folder = Join-Path $modelDir.FullName $folderName
            if (-not (Test-Path -LiteralPath $folder)) {
                continue
            }

            $children = Get-ChildItemSafe $folder
            $remove = $children.Count -eq 0
            if (-not $remove -and $folderName -eq "00_relatorio") {
                $remove = Test-OnlyGeneratedStatusReport $folder
            }

            if ($remove) {
                $actions.Add([pscustomobject]@{
                    action = "remove_folder"
                    path = $folder
                    reason = if ($folderName -eq "00_relatorio") { "relatorio_automatico" } else { "pasta_vazia" }
                })
            }
        }
    }
}

if (-not $WhatIfOnly) {
    foreach ($action in $actions) {
        Remove-Item -LiteralPath $action.path -Force -Recurse
    }
}

$removedModelDirs = New-Object System.Collections.Generic.List[object]
$brandDirs = @(Get-ChildItem -LiteralPath $tractorDir -Directory -ErrorAction SilentlyContinue)
foreach ($brandDir in $brandDirs) {
    $modelDirs = @(Get-ChildItem -LiteralPath $brandDir.FullName -Directory -ErrorAction SilentlyContinue)
    foreach ($modelDir in $modelDirs) {
        $children = Get-ChildItemSafe $modelDir.FullName
        if ($children.Count -eq 0) {
            $removedModelDirs.Add([pscustomobject]@{
                action = "remove_model_folder"
                path = $modelDir.FullName
                reason = "modelo_sem_documentos_encontrados"
            })
            if (-not $WhatIfOnly) {
                Remove-Item -LiteralPath $modelDir.FullName -Force
            }
        }
    }
}

if (-not $WhatIfOnly) {
    $brandDirs = @(Get-ChildItem -LiteralPath $tractorDir -Directory -ErrorAction SilentlyContinue)
    foreach ($brandDir in $brandDirs) {
        $children = Get-ChildItemSafe $brandDir.FullName
        if ($children.Count -eq 0) {
            Remove-Item -LiteralPath $brandDir.FullName -Force
        }
    }
}

[pscustomobject]@{
    mode = if ($WhatIfOnly) { "preview" } else { "executed" }
    removed_managed_folders = $actions.Count
    removed_empty_model_folders = $removedModelDirs.Count
    sample = @($actions + $removedModelDirs | Select-Object -First 20)
} | ConvertTo-Json -Depth 5
