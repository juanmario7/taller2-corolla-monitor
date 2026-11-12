#!/usr/bin/env bash
# Separa los datos de prueba de la evidencia del periodo evaluado (16–21 nov 2026).
# Programado para el 15 nov a las 23:00. Mueve a pruebas/<fecha_hora>/ los CSV,
# reportes, logs y copias de correos generados hasta ahora, guarda un respaldo
# completo de la base (pg_dump) y la deja vacía para que el 16 arranque limpio:
# así "anuncio nuevo" significa visto por primera vez dentro del periodo evaluado.
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob

DEST="pruebas/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DEST"/{datos,reportes,logs,correos}

DB_URL=$(grep -E '^DATABASE_URL=' .env | cut -d= -f2-)
pg_dump "$DB_URL" > "$DEST/carroya_pruebas.sql"

mv datos/*.csv "$DEST/datos/" 2>/dev/null || true
mv reportes/* "$DEST/reportes/" 2>/dev/null || true
mv logs/* "$DEST/logs/" 2>/dev/null || true
for f in correos/enviados/*; do
  [ "$(basename "$f")" = ".gitkeep" ] || mv "$f" "$DEST/correos/"
done

psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -c "TRUNCATE cambio, observacion, anuncio, vendedor, log_ejecucion RESTART IDENTITY CASCADE;"

cat > "$DEST/LEEME.txt" <<EOF
Datos de PRUEBA, generados antes del periodo evaluado (16-21 nov 2026).
Archivados el $(date '+%Y-%m-%d %H:%M:%S %z') (America/Bogota).
carroya_pruebas.sql es el respaldo de la base en ese momento; la base quedó vacía.
EOF
echo "Pruebas archivadas en $DEST y base vaciada."
