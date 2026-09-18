# Upload + analyze BYMA sample PDFs against Docling Studio MAX stack.
# Requires: stack up on http://localhost:3000
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/byma_max_upload.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/byma_max_upload.ps1 -OnlyPreset comunicado
#   powershell -ExecutionPolicy Bypass -File scripts/byma_max_upload.ps1 -SkipAnalyze

param(
    [string]$BaseUrl = "http://localhost:3000",
    [ValidateSet("all", "comunicado", "presentacion", "eeff", "memoria")]
    [string]$OnlyPreset = "all",
    [switch]$SkipAnalyze,
    [switch]$Wait
)

$ErrorActionPreference = "Stop"
$SampleDir = Join-Path $PSScriptRoot "..\docs\archivos_muestra" | Resolve-Path

$Presets = @{
    comunicado = @{
        pipelineOptions = @{
            doOcr                    = $true
            doTableStructure         = $true
            tableMode                = "accurate"
            doCodeEnrichment         = $false
            doFormulaEnrichment      = $false
            doPictureClassification  = $true
            doPictureDescription     = $false
            generatePictureImages    = $true
            generatePageImages       = $false
            imagesScale              = 1.0
        }
        chunkingOptions = @{
            chunkerType       = "hybrid"
            maxTokens         = 512
            mergePeers        = $true
            repeatTableHeader = $true
        }
    }
    presentacion = @{
        pipelineOptions = @{
            doOcr                    = $true
            doTableStructure         = $true
            tableMode                = "accurate"
            doCodeEnrichment         = $false
            doFormulaEnrichment      = $false
            doPictureClassification  = $true
            doPictureDescription     = $false
            generatePictureImages    = $true
            generatePageImages       = $true
            imagesScale              = 1.5
        }
        chunkingOptions = @{
            chunkerType       = "hybrid"
            maxTokens         = 512
            mergePeers        = $true
            repeatTableHeader = $true
        }
    }
    eeff = @{
        pipelineOptions = @{
            doOcr                    = $true
            doTableStructure         = $true
            tableMode                = "accurate"
            doCodeEnrichment         = $false
            doFormulaEnrichment      = $true
            doPictureClassification  = $false
            doPictureDescription     = $false
            generatePictureImages    = $false
            generatePageImages       = $false
            imagesScale              = 1.0
        }
        chunkingOptions = @{
            chunkerType       = "hybrid"
            maxTokens         = 768
            mergePeers        = $true
            repeatTableHeader = $true
        }
    }
    memoria = @{
        pipelineOptions = @{
            doOcr                    = $true
            doTableStructure         = $true
            tableMode                = "accurate"
            doCodeEnrichment         = $false
            doFormulaEnrichment      = $true
            doPictureClassification  = $true
            doPictureDescription     = $false
            generatePictureImages    = $true
            generatePageImages       = $false
            imagesScale              = 1.0
        }
        chunkingOptions = @{
            chunkerType       = "hybrid"
            maxTokens         = 512
            mergePeers        = $true
            repeatTableHeader = $true
        }
    }
}

# Ordered jobs: light → heavy
$Jobs = @(
    @{ File = "BYMA_Comunicado_de_Prensa-Resultados-1T26.pdf"; Preset = "comunicado" }
    @{ File = "BYMA-Comunicado_de_Prensa-2T26.pdf"; Preset = "comunicado" }
    @{ File = "BYMA_2T26_Transcripcion_Resultados_ES.pdf"; Preset = "comunicado" }
    @{ File = "Presentacion_de_resultados_BYMA-2T26.pdf"; Preset = "presentacion" }
    @{ File = "Presentación_de_resultados_BYMA-1T26.pdf"; Preset = "presentacion" }
    @{ File = "BYMA_-_EEFF_31-03-2026_VF.pdf"; Preset = "eeff" }
    @{ File = "BYMA - EEFF 30-06-2026.pdf"; Preset = "eeff" }
    @{ File = "Memoria-BYMA-y-EEFF-al-31-12-2023.pdf"; Preset = "memoria" }
    @{ File = "BYMA-MEMORIA_2024_y_EEFF_31-12-2024.pdf"; Preset = "memoria" }
    @{ File = "BYMA-MEMORIA_2025.pdf"; Preset = "memoria" }
)

function Get-Health {
    Invoke-RestMethod -Uri "$BaseUrl/api/health" -Method GET
}

function Wait-Analysis {
    param([string]$AnalysisId, [int]$TimeoutSec = 3600)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $job = Invoke-RestMethod -Uri "$BaseUrl/api/analyses/$AnalysisId" -Method GET
        Write-Host ("  status={0} progress={1}/{2}" -f $job.status, $job.progressCurrent, $job.progressTotal)
        if ($job.status -in @("completed", "failed", "cancelled")) { return $job }
        Start-Sleep -Seconds 15
    }
    throw "Timeout waiting for analysis $AnalysisId"
}

Write-Host "Checking health at $BaseUrl ..."
$health = Get-Health
Write-Host ("engine={0} version={1} ingestion={2} reasoning={3}" -f `
        $health.engine, $health.version, $health.ingestionAvailable, $health.reasoningAvailable)

if (-not $health.ingestionAvailable) {
    Write-Warning "ingestionAvailable=false — OpenSearch/embedding/Neo4j may still be warming up"
}

foreach ($item in $Jobs) {
    if ($OnlyPreset -ne "all" -and $item.Preset -ne $OnlyPreset) { continue }

    $path = Join-Path $SampleDir $item.File
    if (-not (Test-Path -LiteralPath $path)) {
        # Presentación 1T26 may have encoding-mangled filename
        $alt = Get-ChildItem -LiteralPath $SampleDir -Filter "Presentaci*_BYMA-1T26.pdf" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($item.File -like "Presentaci*" -and $alt) {
            $path = $alt.FullName
        }
        else {
            Write-Warning "Missing file: $($item.File)"
            continue
        }
    }

    Write-Host ""
    Write-Host "=== Upload $($item.File) [$($item.Preset)] ==="
    $form = @{ file = Get-Item -LiteralPath $path }
    $doc = Invoke-RestMethod -Uri "$BaseUrl/api/documents/upload" -Method POST -Form $form
    Write-Host ("  documentId={0}" -f $doc.id)

    if ($SkipAnalyze) { continue }

    $body = @{
        documentId      = $doc.id
        pipelineOptions = $Presets[$item.Preset].pipelineOptions
        chunkingOptions = $Presets[$item.Preset].chunkingOptions
    } | ConvertTo-Json -Depth 6

    $analysis = Invoke-RestMethod -Uri "$BaseUrl/api/analyses" -Method POST -ContentType "application/json" -Body $body
    Write-Host ("  analysisId={0}" -f $analysis.id)

    if ($Wait) {
        $done = Wait-Analysis -AnalysisId $analysis.id
        if ($done.status -ne "completed") {
            Write-Warning ("Analysis failed: {0}" -f $done.error)
        }
    }
}

Write-Host ""
Write-Host "Done. Open $BaseUrl — Docs / Parse / Chunk / Ingest / Graph / Ask"
Write-Host "Tip: run with -Wait to block until each analysis finishes (memorias take long)."
