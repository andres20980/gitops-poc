#!/bin/bash

# Borrar ficheros previos
rm -f skeleton-poc-*.txt

# Recorre el directorio actual y sus subdirectorios inmediatos
find . -maxdepth 1 -mindepth 1 -type d | while read -r DIR; do
  BASENAME=$(basename "$DIR")

  # Saltar si es .git o services
  [[ "$BASENAME" == ".git" || "$BASENAME" == "services" ]] && continue

  OUTFILE="skeleton-poc-${BASENAME}.txt"
  echo "📁 Directory structure for '$DIR'" > "$OUTFILE"
  tree -a -I '.git|services' "$DIR" >> "$OUTFILE"

  echo -e "\n📄 File contents within '$DIR' (recursive)" >> "$OUTFILE"

  # Buscar todos los archivos excepto los skeleton-poc
  find "$DIR" -type f \
    ! -path "*/.git/*" \
    ! -path "*/services/*" \
    ! -name "skeleton-poc-*" | while read -r FILE; do
      echo -e "\n==== $FILE ====" >> "$OUTFILE"
      cat "$FILE" >> "$OUTFILE"
  done

  echo "✅ Generated $OUTFILE"
done

# Incluir el propio directorio raíz también
OUTFILE="skeleton-poc-root.txt"
echo "📁 Directory structure for '.'" > "$OUTFILE"
tree -a -I '.git|services' . >> "$OUTFILE"

echo -e "\n📄 File contents within '.' (recursive)" >> "$OUTFILE"

find . -maxdepth 1 -type f \
  ! -name "skeleton-poc-*" | while read -r FILE; do
    echo -e "\n==== $FILE ====" >> "$OUTFILE"
    cat "$FILE" >> "$OUTFILE"
done

echo "✅ Generated $OUTFILE"
