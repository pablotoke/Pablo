param(
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptRoot
    $OutputDir = Join-Path $workspaceRoot "Inventario_APPMAQ\Pesquisa_Cache"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$files = @(
    [pscustomobject]@{
        Name = "candidatos_documentos.csv"
        Header = "data_lote,batch_id,marca,modelo,tipo_documento,fonte,consulta,titulo,url,idioma,acesso,status,score,observacao"
    },
    [pscustomobject]@{
        Name = "validacoes_documentos.csv"
        Header = "data_validacao,batch_id,marca,modelo,tipo_documento,fonte,url,resultado,idioma,modelos_confirmados,paginas,titulo_interno,observacao"
    },
    [pscustomobject]@{
        Name = "downloads_documentos.csv"
        Header = "data_download,batch_id,marca,modelo,tipo_documento,fonte,url,arquivo_local,tamanho_bytes,paginas,sha256,status,observacao"
    },
    [pscustomobject]@{
        Name = "rejeitados_documentos.csv"
        Header = "data_rejeicao,batch_id,marca,modelo,tipo_documento,fonte,url,motivo,idioma,observacao"
    },
    [pscustomobject]@{
        Name = "lotes_pesquisa.csv"
        Header = "data_lote,batch_id,tamanho_lote,status,observacao"
    }
)

foreach ($file in $files) {
    $path = Join-Path $OutputDir $file.Name
    if (-not (Test-Path -LiteralPath $path)) {
        $file.Header | Set-Content -LiteralPath $path -Encoding UTF8
    }
}

$manifestPath = Join-Path $OutputDir "manifesto_cache.json"
$manifest = [pscustomobject]@{
    criado_em = (Get-Date).ToString("s")
    protocolo = "pesquisa_economica_manuais"
    idiomas_aceitos = @("PT", "ES", "EN")
    idiomas_rejeitados = @("RU", "AR", "ZH", "PL")
    fontes_prioritarias = @("Scribd", "ManualsLib", "Site oficial", "JSAgro", "Fonte gratuita")
    regra_pasta_modelo = "Criar subpasta somente quando houver documento real, link forte validado ou arquivo baixado."
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

[pscustomobject]@{
    cache_dir = $OutputDir
    files = @($files | ForEach-Object { Join-Path $OutputDir $_.Name })
    manifest = $manifestPath
} | ConvertTo-Json -Depth 4
