param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    $OutputDir = Join-Path $workspaceRoot "Inventario_APPMAQ\Arquivos_Usuario"
}

function Normalize-Text {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $normalized = $Text.Trim().Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($char in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }
    $builder.ToString().ToUpperInvariant()
}

function Get-DocumentType {
    param([string]$Name)

    $text = Normalize-Text $Name
    if ($text -match "CATALOGO.*PECA|PECAS|PARTS") { return "catalogo_pecas" }
    if ($text -match "SERVICO|OFICINA|WORKSHOP|REPARO|REPARACAO") { return "manual_servico_oficina" }
    if ($text -match "OPERADOR|OPERACAO|INSTRUCOES SOBRE OPERACAO|OPERATOR") { return "manual_operador" }
    if ($text -match "ELETRIC|ELETRICA|ELETRICO|HIDRAULIC|HIDRAULICA|HIDRAULICO|SENSOR|DIAGRAMA|CIRCUITO") { return "manual_eletrico_hidraulico" }
    if ($text -match "MANUTENCAO|PERIODICA|LUBRIFICACAO|MAINTENANCE") { return "manual_manutencao" }
    if ($text -match "TREINAMENTO|CONCEITOS|DIAGNOSTICO|CALIBRACAO|TRAINING") { return "treinamento_diagnostico" }
    if ($text -match "FOLHETO|FICHA|ESPECIFICAC|TECNICA|TECNICO|BROCHURE") { return "ficha_tecnica_folheto" }
    if ($text -match "MANUAL") { return "manual_complementar" }
    return "outros_documentos"
}

function Get-TargetFolder {
    param([string]$DocumentType)

    switch ($DocumentType) {
        "manual_operador" { "01_manual_operador" }
        "manual_servico_oficina" { "02_manual_servico_oficina" }
        "catalogo_pecas" { "03_catalogo_pecas" }
        "manual_manutencao" { "04_manual_manutencao" }
        "manual_eletrico_hidraulico" { "05_manual_eletrico_hidraulico" }
        "treinamento_diagnostico" { "06_boletim_treinamento_diagnostico" }
        "ficha_tecnica_folheto" { "07_ficha_tecnica_folheto" }
        "manual_complementar" { "08_manual_complementar" }
        default { "10_outros_documentos" }
    }
}

function Get-LanguageHint {
    param([string]$Name)
    $text = Normalize-Text $Name
    if ($text -match "ESPANHOL|ESPANOL|SPANISH| ES ") { return "ES" }
    if ($text -match "INGLES|ENGLISH| EN ") { return "EN" }
    return "PT"
}

function ConvertTo-SafeFolderName {
    param([string]$Name)
    $safe = if ([string]::IsNullOrWhiteSpace($Name)) { "_sem_modelo" } else { $Name.Trim() }
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, "_")
    }
    $safe -replace "\s+", " "
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
try {
    $rows = New-Object System.Collections.Generic.List[object]
    $rootName = $null
    foreach ($entry in $zip.Entries) {
        $parts = $entry.FullName -split "/"
        if (-not $rootName -and $parts.Count -gt 0) {
            $rootName = $parts[0]
        }
        if ($entry.FullName.EndsWith("/")) {
            continue
        }
        if ($entry.Length -eq 0) {
            continue
        }

        $relativeParts = @($parts | Select-Object -Skip 1)
        $model = ""
        $fileName = Split-Path -Leaf $entry.FullName
        $scope = "modelo"
        if ($relativeParts.Count -gt 1) {
            $model = $relativeParts[0]
        }
        else {
            $model = "_GERAL_VALTRA"
            $scope = "geral"
        }

        $docType = Get-DocumentType ($fileName + " " + $entry.FullName)
        $rows.Add([pscustomobject]@{
            marca = "VALTRA"
            modelo = $model
            escopo = $scope
            tipo_documento = $docType
            pasta_sugerida = Get-TargetFolder $docType
            idioma_sugerido = Get-LanguageHint $fileName
            nome_arquivo = $fileName
            caminho_zip = $entry.FullName
            tamanho_bytes = $entry.Length
            compactado_bytes = $entry.CompressedLength
            status_validacao = "candidato_por_pasta_usuario"
            observacao = if ($scope -eq "geral") { "Documento geral no nivel raiz do ZIP; mapear por serie antes de copiar para modelos." } else { "Documento estava dentro da pasta do modelo no ZIP do usuario." }
        })
    }
}
finally {
    $zip.Dispose()
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $OutputDir "inventario_zip_valtra_$stamp.csv"
$jsonPath = Join-Path $OutputDir "inventario_zip_valtra_$stamp.json"
$mdPath = Join-Path $OutputDir "resumo_zip_valtra_$stamp.md"

$rows | Sort-Object modelo, tipo_documento, nome_arquivo | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
$rows | Sort-Object modelo, tipo_documento, nome_arquivo | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Inventario ZIP usuario - Valtra")
$lines.Add("")
$lines.Add("Arquivo: $ZipPath")
$lines.Add("Total de documentos: $($rows.Count)")
$lines.Add("Modelos/pastas com documentos: $(@($rows | Where-Object {$_.escopo -eq 'modelo'} | Select-Object -ExpandProperty modelo -Unique).Count)")
$lines.Add("Documentos gerais no raiz: $(@($rows | Where-Object {$_.escopo -eq 'geral'}).Count)")
$lines.Add("")
$lines.Add("## Por tipo")
$rows | Group-Object tipo_documento | Sort-Object Name | ForEach-Object {
    $lines.Add("- $($_.Name): $($_.Count)")
}
$lines.Add("")
$lines.Add("## Por modelo")
$rows | Where-Object {$_.escopo -eq "modelo"} | Group-Object modelo | Sort-Object Name | ForEach-Object {
    $types = ($_.Group | Group-Object tipo_documento | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
    $lines.Add("- $($_.Name): $($_.Count) documento(s) | $types")
}
$lines.Add("")
$lines.Add("## Documentos gerais")
$rows | Where-Object {$_.escopo -eq "geral"} | Sort-Object tipo_documento, nome_arquivo | ForEach-Object {
    $lines.Add("- $($_.tipo_documento) | $($_.nome_arquivo)")
}
$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    total_documentos = $rows.Count
    modelos_com_documentos = @($rows | Where-Object {$_.escopo -eq "modelo"} | Select-Object -ExpandProperty modelo -Unique).Count
    documentos_gerais = @($rows | Where-Object {$_.escopo -eq "geral"}).Count
    csv = $csvPath
    json = $jsonPath
    markdown = $mdPath
} | ConvertTo-Json -Depth 4
