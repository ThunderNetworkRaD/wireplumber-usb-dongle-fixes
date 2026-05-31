#!/bin/bash

# Esci immediatamente se un comando fallisce
set -e

# Trova il file .spec nella cartella corrente
SPEC_FILE=$(ls *.spec 2>/dev/null | head -n 1)

if [ -z "$SPEC_FILE" ]; then
    echo "❌ Errore: Nessun file .spec trovato in questa cartella!"
    exit 1
fi

# Estrae Name e Version dallo SPEC (rimuovendo spazi e tabulazioni)
NAME=$(grep -i "^Name:" "$SPEC_FILE" | awk '{print $2}')
VERSION=$(grep -i "^Version:" "$SPEC_FILE" | awk '{print $2}')

if [ -z "$NAME" ] || [ -z "$VERSION" ]; then
    echo "❌ Errore: Impossibile recuperare Name o Version da $SPEC_FILE"
    exit 1
fi

TARBALL_NAME="${NAME}-${VERSION}"
TARGET_TARBALL="${HOME}/rpmbuild/SOURCES/${TARBALL_NAME}.tar.gz"

echo "📦 Pacchettizzazione di $NAME (v$VERSION)..."

# Crea la cartella SOURCES se non esiste ancora
mkdir -p "${HOME}/rpmbuild/SOURCES"

# Crea il tar.gz escludendo la cronologia git, lo script stesso e i file spec/rpm
tar -czf "$TARGET_TARBALL" \
    --exclude=".git" \
    --exclude="*.sh" \
    --exclude="*.spec" \
    --transform "s^\.^${TARBALL_NAME}^" \
    .

echo "✅ Archivio creato con successo in:"
echo "   $TARGET_TARBALL"
echo ""
echo "🚀 Ora puoi compilare l'RPM eseguendo:"
echo "   rpmbuild -ba $SPEC_FILE"
