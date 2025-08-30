#!/usr/bin/env bash
set -euo pipefail

echo "==> InfoCollect setup starting"

if ! command -v perl >/dev/null 2>&1; then
  echo "Perl non trovato nel PATH" >&2
  exit 1
fi

if ! command -v cpanm >/dev/null 2>&1; then
  echo "cpanm non trovato: provo a installarlo localmente (requires curl)" >&2
  if command -v curl >/dev/null 2>&1; then
    curl -L https://cpanmin.us | perl - App::cpanminus --local-lib=local
    export PERL5LIB="$PWD/local/lib/perl5:${PERL5LIB:-}"
    export PATH="$PWD/local/bin:${PATH}"
  else
    echo "curl non disponibile. Installa App::cpanminus manualmente e riprova." >&2
    exit 1
  fi
fi

echo "==> Installazione dipendenze Perl (cpanfile)"
cpanm --quiet --notest --installdeps . || { echo "Installazione CPAN fallita" >&2; exit 1; }

echo "==> Inizializzazione database SQLite"
perl -Mlib=lib -Minit_db -e 'init_db::createDB()' || { echo "Init DB fallita" >&2; exit 1; }

# Configura token HuggingFace opzionale da variabile d'ambiente
if [ -n "${HUGGINGFACE_API_TOKEN:-}" ]; then
  echo "==> Configuro HUGGINGFACE_API_TOKEN dalle variabili d'ambiente"
  perl -Mlib=lib -Mconfig_manager -e 'config_manager::add_setting("HUGGINGFACE_API_TOKEN", $ENV{HUGGINGFACE_API_TOKEN})'
fi

if [ -f package.json ]; then
  if command -v npm >/dev/null 2>&1; then
    echo "==> Installazione dipendenze Node (package.json)"
    npm install --no-fund --no-audit
  else
    echo "npm non trovato: salta installazione dipendenze Node" >&2
  fi
fi

cat <<'EON'

==> Setup completato.
- Avvia API web (Mojolicious):   perl web/api_server.pl daemon -l http://*:3000
- Avvia daemon P2P:              perl daemon.pl
- Avvia agent (crawler + P2P):   perl InfoCollect/agent.pl
- Dev server TS (Express demo):  npm run dev:web

Note:
- Imposta INFOCOLLECT_ENCRYPTION_KEY in settings per una chiave personalizzata.
- Moduli opzionali potrebbero richiedere tool di sistema (es. OpenSSL).
EON
