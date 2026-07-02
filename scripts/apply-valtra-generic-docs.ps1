param(
    [Parameter(Mandatory = $true)]
    [string[]]$Modelos,

    [string]$DestinoBase = "E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 2",

    [string]$BibliotecaGenerica = "E:\MANUAIS_APPMAQ\_GENERICOS\VALTRA"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BibliotecaGenerica)) {
    throw "Biblioteca generica Valtra nao encontrada: $BibliotecaGenerica"
}

New-Item -ItemType Directory -Force -Path $DestinoBase | Out-Null

$pdfs = Get-ChildItem -LiteralPath $BibliotecaGenerica -File -Filter "*.pdf"
if (-not $pdfs) {
    throw "Nenhum PDF generico encontrado em: $BibliotecaGenerica"
}

$copiados = foreach ($modelo in $Modelos) {
    $modeloLimpo = $modelo.Trim()
    if ([string]::IsNullOrWhiteSpace($modeloLimpo)) {
        continue
    }

    $modeloDir = Join-Path $DestinoBase $modeloLimpo
    New-Item -ItemType Directory -Force -Path $modeloDir | Out-Null

    foreach ($pdf in $pdfs) {
        $destino = Join-Path $modeloDir $pdf.Name
        Copy-Item -LiteralPath $pdf.FullName -Destination $destino -Force

        [pscustomobject]@{
            modelo = $modeloLimpo
            arquivo = $destino
            origem = $pdf.FullName
        }
    }
}

$copiados | Sort-Object modelo, arquivo
