#!/usr/bin/env bash
# Gera um stack.env com segredos aleatórios a partir do stack.env.example
# Uso: bash gerar-env.sh http://IP_OU_DOMINIO [arquivo_saida]
set -euo pipefail

cd "$(dirname "$0")"

HOST="${1:?Informe o endereço, ex.: bash gerar-env.sh http://192.168.0.10}"
HOST="${HOST%/}"
OUT="${2:-stack.env}"

if [ -f "$OUT" ]; then
  echo "✗ $OUT já existe — não vou sobrescrever (os segredos atuais seriam perdidos)." >&2
  exit 1
fi

sed \
  -e "s|^NOVU_HOST=.*|NOVU_HOST=${HOST}|" \
  -e "s|^JWT_SECRET=$|JWT_SECRET=$(openssl rand -hex 32)|" \
  -e "s|^STORE_ENCRYPTION_KEY=$|STORE_ENCRYPTION_KEY=$(openssl rand -hex 16)|" \
  -e "s|^NOVU_SECRET_KEY=$|NOVU_SECRET_KEY=$(openssl rand -hex 32)|" \
  -e "s|^MONGO_PASSWORD=$|MONGO_PASSWORD=$(openssl rand -hex 24)|" \
  stack.env.example > "$OUT"

chmod 600 "$OUT"
echo "▸ $OUT criado para ${HOST}"
