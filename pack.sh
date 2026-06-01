#!/bin/bash

# Esci immediatamente se un comando fallisce
set -e

NEXUS_URL="https://nexus.thundernetwork.org/repository/yum-main/"

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

#echo "📦 Pacchettizzazione di $NAME (v$VERSION)..."
echo "📦 1. Pacchettizzazione delle sorgenti..."
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
# echo "🚀 Ora puoi compilare l'RPM eseguendo:"
# echo "   rpmbuild -ba $SPEC_FILE"

echo "🛠️ 2. Compilazione dell'RPM con rpmbuild..."
# Eseguiamo rpmbuild e catturiamo sia stdout che stderr (2>&1)
RPM_BUILD_OUTPUT=$(rpmbuild -ba "$SPEC_FILE" 2>&1)

# Stampiamo l'output originale a schermo per controllo
echo "$RPM_BUILD_OUTPUT"

exit 0
# --- PARTE 1: ESTRAZIONE PERCORSI ---

# Estrae il pacchetto binario (esclude il file .src.rpm)
RPM_BINARY=$(echo "$RPM_BUILD_OUTPUT" | grep "^Scritto:" | grep -v "\.src\.rpm$" | awk '{print $2}')

# Estrae il pacchetto sorgente (prende solo il file .src.rpm)
RPM_SOURCE=$(echo "$RPM_BUILD_OUTPUT" | grep "^Scritto:" | grep "\.src\.rpm$" | awk '{print $2}')

echo ""
echo "🔍 File intercettati dall'output:"
echo "   📦 Binario:  $RPM_BINARY"
echo "   📦 Sorgente: $RPM_SOURCE"
echo ""

# --- PARTE 2: CARICAMENTO SU NEXUS ---

echo "🚀 3. Inizio caricamento su Nexus (${NEXUS_URL})..."

# Caricamento del pacchetto Binario (Non-Sorgente)
if [ -f "$RPM_BINARY" ]; then
    echo "📤 Caricamento pacchetto binario in corso..."
    curl -f -u "${NEXUS_USER}:${NEXUS_PASSWORD}" \
         -X POST "$NEXUS_URL" \
         -H "Content-Type: application/x-rpm" \
         --data-binary "@$RPM_BINARY"
    echo "✅ Binario caricato."
else
    echo "❌ Errore: File binario non trovato o non generato."
    exit 1
fi

# Caricamento del pacchetto Sorgente (SRPM)
if [ -f "$RPM_SOURCE" ]; then
    echo "📤 Caricamento pacchetto sorgente (SRPM) in corso..."
    curl -f -u "${NEXUS_USER}:${NEXUS_PASSWORD}" \
         -X POST "$NEXUS_URL" \
         -H "Content-Type: application/x-rpm" \
         --data-binary "@$RPM_SOURCE"
    echo "✅ Sorgente caricato."
else
    echo "⚠️ Avviso: File sorgente (.src.rpm) non trovato. Salto questo caricamento."
fi

echo ""
echo "🎉 Operazione completata! Entrambi i pacchetti sono ora ospitati sul tuo repository."
