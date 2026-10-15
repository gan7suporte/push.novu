#!/usr/bin/env bash
# Gera um stack.env com URLs e segredos aleatórios a partir do stack.env.example
# Uso: bash gerar-env.sh DOMINIO [arquivo_saida]
#   ex.: bash gerar-env.sh pulse.apps.gan7.com.br
#   → Dashboard https://DOMINIO, API https://api.DOMINIO, WebSocket https://ws.DOMINIO
set -euo pipefail

cd "$(dirname "$0")"

DOMINIO="${1:?Informe o domínio, ex.: bash gerar-env.sh pulse.apps.gan7.com.br}"
DOMINIO="${DOMINIO#http://}"
DOMINIO="${DOMINIO#https://}"
DOMINIO="${DOMINIO%/}"
OUT="${2:-stack.env}"

if [ -f "$OUT" ]; then
  echo "✗ $OUT já existe — não vou sobrescrever (os segredos atuais seriam perdidos)." >&2
  exit 1
fi

# tr -d '\r' protege contra checkout com CRLF
tr -d '\r' < stack.env.example | sed \
  -e "s|^DASHBOARD_URL=.*|DASHBOARD_URL=https://${DOMINIO}|" \
  -e "s|^API_URL=.*|API_URL=https://api.${DOMINIO}|" \
  -e "s|^WS_URL=.*|WS_URL=https://ws.${DOMINIO}|" \
  -e "s|^JWT_SECRET=$|JWT_SECRET=$(openssl rand -hex 32)|" \
  -e "s|^STORE_ENCRYPTION_KEY=$|STORE_ENCRYPTION_KEY=$(openssl rand -hex 16)|" \
  -e "s|^NOVU_SECRET_KEY=$|NOVU_SECRET_KEY=$(openssl rand -hex 32)|" \
  -e "s|^MONGO_PASSWORD=$|MONGO_PASSWORD=$(openssl rand -hex 24)|" \
  > "$OUT"

chmod 600 "$OUT"
echo "▸ $OUT criado:"
grep -E '^(DASHBOARD|API|WS)_URL=' "$OUT"
