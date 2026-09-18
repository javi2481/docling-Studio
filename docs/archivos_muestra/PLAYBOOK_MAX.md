# Docling Studio — playbook BYMA (máximo aprovechamiento)
#
# Stack: docker compose -f docker-compose.max.yml --env-file .env.max up -d --build
# UI:    http://localhost:3000
#
# Orden recomendado (mismo criterio que docs/archivos_muestra/README.es.md):
#   1) Comunicados + transcripción (pocas páginas, validar pipeline)
#   2) Presentaciones (layout + figuras)
#   3) EEFF (tablas → table_mode=accurate)
#   4) Memorias (~190 págs) al final
#
# Presets de análisis en la UI (o vía scripts/byma_max_upload.ps1):
#
# [comunicado / transcripcion]
#   do_ocr=true, do_table_structure=true, table_mode=accurate
#   do_formula_enrichment=false, do_code_enrichment=false
#   do_picture_classification=true, generate_picture_images=true
#   do_picture_description=false   # VLM lento; activar solo si necesitás captions
#   generate_page_images=false
#   chunker=hybrid, max_tokens=512, merge_peers=true, repeat_table_header=true
#
# [presentacion]
#   igual + generate_page_images=true, images_scale=1.5
#   do_picture_classification=true, generate_picture_images=true
#
# [eeff]
#   table_mode=accurate (obligatorio), do_ocr=true
#   generate_page_images=false (ahorra RAM)
#   chunker=hybrid, max_tokens=768, repeat_table_header=true
#
# [memoria]
#   BATCH_PAGE_SIZE=5 ya está en el stack
#   timeout 1800s, max 100 MB
#   table_mode=accurate, do_ocr=true
#   picture classification + images ON
#   picture_description OFF en el primer pase (re-analizar después si hace falta)
#   chunker=hybrid, max_tokens=512
#
# Tras cada análisis completado:
#   1. Revisar Parse (bbox / árbol) e Inspect (Markdown)
#   2. Chunk view → Generate chunks si no vinieron con el análisis
#   3. Ingest → push a OpenSearch + Neo4j (Stores)
#   4. Graph tab + Neo4j Browser :7474
#   5. Ask (reasoning) con Ollama qwen3-coder:30b — requiere analysis listo
#
# awesome-docling (scub-france) — qué sirve AHORA vs después:
#   YA cubierto por este stack: Docling Studio, OpenSearch RAG, Neo4j graph, Ollama reasoning
#   Útil después (no hace falta instalar para exprimir Studio):
#     - chunky → validar calidad de chunks Markdown antes de indexar en prod
#     - docling-eval / docling-sdg → métricas y datasets sintéticos
#     - docling-graph → KG más rico fuera del mirror Neo4j de Studio
#     - Granite-Docling / SmolDocling → pipeline VLM si picture_description no alcanza
#     - docling-mcp → agentes externos sobre los mismos docs
#
# Claimprint: proyecto aparte; contenedores eliminados de Docker Desktop.
