param(
  [string]$Workspace = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Workspace)) {
  $Workspace = (Resolve-Path -Path (Join-Path $PSScriptRoot "..")).Path
}

$outDir = Join-Path $Workspace "Inventario_APPMAQ\Lotes_Usuario"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$families = @(
  [pscustomobject]@{ Family = "VALTRA Q5"; Models = "Q265 Q285 Q305"; Queries = @(
    "Valtra Q265 Q285 Q305 manual operador PDF",
    "Valtra Q265 Q285 Q305 catalogo pecas PDF",
    "Valtra Q265 Q285 Q305 manual servico PDF",
    "Valtra Q5 esquema eletrico diagnostico codigos falhas PDF",
    "Valtra Q5 hydraulic schematic service manual PDF",
    "site:scribd.com Valtra Q265 Q285 Q305 manual",
    "site:manualslib.com Valtra Q265 manual"
  ) },
  [pscustomobject]@{ Family = "VALTRA S6"; Models = "S263 S274 S324 S346 S353 S374 S376 S394 S396 S416"; Queries = @(
    "Valtra S263 S274 S324 S346 S353 S374 S376 S394 S396 S416 manual operador PDF",
    "Valtra S346 S376 S416 catalogo pecas PDF",
    "Valtra S346 S376 S416 manual servico PDF",
    "Valtra S6 esquema eletrico diagnostico codigos falhas PDF",
    "Valtra S6 hydraulic schematic service manual PDF",
    "site:scribd.com Valtra S346 S376 S416 manual",
    "site:manualslib.com Valtra S346 manual"
  ) },
  [pscustomobject]@{ Family = "VALTRA T CVT"; Models = "T195 CVT T210 CVT T230 CVT T250 CVT"; Queries = @(
    "Valtra T195 CVT T210 CVT T230 CVT T250 CVT manual operador PDF",
    "Valtra T195 CVT T210 CVT T230 CVT T250 CVT catalogo pecas PDF",
    "Valtra T195 CVT T210 CVT T230 CVT T250 CVT manual servico PDF",
    "Valtra T CVT esquema eletrico diagnostico codigos falhas PDF",
    "Valtra T CVT hydraulic schematic service manual PDF",
    "site:scribd.com Valtra T195 CVT T210 CVT T230 CVT manual",
    "site:manualslib.com Valtra T195 CVT manual"
  ) }
)

function Convert-ResultUrl {
  param([string]$Url)
  if ($Url -match "uddg=([^&]+)") {
    return [System.Uri]::UnescapeDataString($Matches[1])
  }
  return $Url
}

function Strip-Html {
  param([string]$Text)
  $clean = [regex]::Replace($Text, "<.*?>", "")
  return [System.Net.WebUtility]::HtmlDecode($clean).Trim()
}

$rows = New-Object System.Collections.Generic.List[object]
$ua = "Mozilla/5.0 manual-research"

foreach ($family in $families) {
  foreach ($query in $family.Queries) {
    $searchUrl = "https://duckduckgo.com/html/?q=$([System.Uri]::EscapeDataString($query))"
    try {
      $html = (Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -Headers @{ "User-Agent" = $ua }).Content
      $matches = [regex]::Matches($html, '<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>(.*?)</a>', "IgnoreCase")
      $rank = 0
      foreach ($m in $matches) {
        $rank++
        $url = Convert-ResultUrl $m.Groups[1].Value
        $title = Strip-Html $m.Groups[2].Value
        $rows.Add([pscustomobject]@{
          data_pesquisa = (Get-Date).ToString("s")
          lote = "VALTRA 4"
          familia = $family.Family
          modelos = $family.Models
          consulta = $query
          rank = $rank
          titulo = $title
          url = $url
          status = "candidato_nao_validado"
        })
      }
      Start-Sleep -Milliseconds 800
    } catch {
      $rows.Add([pscustomobject]@{
        data_pesquisa = (Get-Date).ToString("s")
        lote = "VALTRA 4"
        familia = $family.Family
        modelos = $family.Models
        consulta = $query
        rank = 0
        titulo = "ERRO NA BUSCA"
        url = $_.Exception.Message
        status = "erro_busca"
      })
    }
  }
}

$csv = Join-Path $outDir "candidatos_valtra4_busca_ampliada_2026-07-02.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$rows | Where-Object { $_.status -eq "candidato_nao_validado" } |
  Sort-Object familia,consulta,rank |
  Select-Object familia,rank,titulo,url |
  Format-Table -AutoSize

Write-Host "CSV: $csv"
