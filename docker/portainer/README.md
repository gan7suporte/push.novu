# Novu no Portainer (SRVGAN7-APP01)

Stack com API, Worker, WebSocket, Dashboard, MongoDB e Redis usando as imagens oficiais do Novu.
Não depende do Supabase nem da stack `mag-sac`.

| Serviço   | Porta publicada | Observação                         |
|-----------|-----------------|------------------------------------|
| Dashboard | 4000            | painel web                         |
| API       | 3000            | usada pelo Dashboard e pelos sistemas |
| WebSocket | 3002            | notificações em tempo real (Inbox) |
| MongoDB / Redis / Worker | — | só na rede interna da stack       |

## Arquivos

- `docker-compose.yml` — a stack (colar no Portainer)
- `stack.env.example` — modelo de variáveis
- `gerar-env.sh` — gera o `stack.env` com segredos aleatórios

## 1. Conferir portas livres no servidor

```bash
sudo ss -tlnp | grep -E ':(3000|3002|4000)\b' || echo "portas livres"
```

Se alguma estiver ocupada, troque `API_PORT`, `WS_PORT` ou `DASHBOARD_PORT` no `stack.env`.

## 2. Gerar o stack.env (no Git Bash ou no Linux)

```bash
cd docker/portainer
bash gerar-env.sh http://IP_OU_DOMINIO_DO_SERVIDOR
```

`NOVU_HOST` deve ser o endereço que o **navegador** dos usuários usa para chegar ao servidor
(sem porta e sem barra no final). Guarde o `stack.env` em local seguro (cofre de senhas):
- `STORE_ENCRYPTION_KEY` não pode mudar depois que provedores (SMS, push etc.) forem cadastrados;
- `MONGO_USER`/`MONGO_PASSWORD` só valem na primeira criação do volume.

## 3. Criar a stack no Portainer

1. **Stacks → Add stack**, nome: `novu`
2. **Build method: Web editor** → colar o conteúdo de `docker-compose.yml`
3. **Environment variables → Load variables from .env file** → selecionar o `stack.env`
4. **Deploy the stack**

O servidor precisa de acesso a `ghcr.io` para baixar as imagens. A primeira subida leva alguns minutos.

## 4. Validar

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/v1/health-check   # 200
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3002/v1/health-check   # 200
```

Abrir `http://IP_OU_DOMINIO:4000`, criar a conta de administrador e pegar a API key em **Settings → API Keys**.

## Atualizar a versão

Alterar `NOVU_VERSION` nas variáveis da stack → **Update the stack** com *Re-pull image* marcado.
Faça backup do volume `novu_mongodb` antes.

## HTTPS (recomendado)

Com proxy reverso (Nginx Proxy Manager, Traefik etc.) na frente, use `NOVU_HOST=https://dominio`
e ajuste as portas conforme o proxy expõe cada serviço.
