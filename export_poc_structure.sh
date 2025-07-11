#!/bin/bash
# export_poc_structure.sh v2.0.0
# Script to export the GitOps PoC directory structure and file contents.
# This version now includes the 'services' directory and its relevant files (pipelines, Dockerfiles).

# Borrar ficheros previos
rm -f skeleton-poc-*.txt

# Recorre el directorio actual y sus subdirectorios inmediatos (incluyendo 'services')
# La exclusión de '.git' se mantiene.
find . -maxdepth 1 -mindepth 1 -type d ! -name ".git" | while read -r DIR; do
  BASENAME=$(basename "$DIR")

  OUTFILE="skeleton-poc-${BASENAME}.txt"
  echo "📁 Directory structure for '$DIR'" > "$OUTFILE"
  # Tree -a para todos los archivos, -I para ignorar .git
  tree -a -I '.git' "$DIR" >> "$OUTFILE"

  echo -e "\n📄 File contents within '$DIR' (recursive)" >> "$OUTFILE"

  # Buscar todos los archivos excepto los skeleton-poc, y dentro de services, solo los relevantes
  # Para los directorios de servicio, buscamos azure-pipelines.yml y Dockerfile
  # Para otros directorios, excluimos 'services' de nuevo para el contenido, ya que lo manejamos aparte
  if [[ "$BASENAME" == "services" ]]; then
    find "$DIR" -type f \
      ! -path "*/.git/*" \
      -iregex ".*\(azure-pipelines\.yml\|Dockerfile\)" | \
      while read -r FILE; do
        echo -e "\n==== $FILE ====" >> "$OUTFILE"
        cat "$FILE" >> "$OUTFILE"
    done
  else
    find "$DIR" -type f \
      ! -path "*/.git/*" \
      ! -path "*/services/*" \
      ! -name "skeleton-poc-*" | \
      while read -r FILE; do
        echo -e "\n==== $FILE ====" >> "$OUTFILE"
        cat "$FILE" >> "$OUTFILE"
    done
  fi

  echo "✅ Generated $OUTFILE"
done

# Incluir el propio directorio raíz también (ahora sin excluir 'services')
OUTFILE="skeleton-poc-root.txt"
echo "📁 Directory structure for '.'" > "$OUTFILE"
tree -a -I '.git' . >> "$OUTFILE"

echo -e "\n📄 File contents within '.' (recursive)" >> "$OUTFILE"

# Para la raíz, buscamos los archivos de primer nivel y luego los directorios.
# Los archivos de primer nivel (como README.md, .gitignore, setup_gitops_poc.sh, export_poc_structure.sh)
find . -maxdepth 1 -type f \
  ! -name "skeleton-poc-*" | while read -r FILE; do
    echo -e "\n==== $FILE ====" >> "$OUTFILE"
    cat "$FILE" >> "$OUTFILE"
done

echo "✅ Generated $OUTFILE"