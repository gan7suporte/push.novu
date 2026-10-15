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

## 1. Conferir o servidor

```bash
# CPU com AVX: o mongo 8.x não sobe sem isso (comum em VM Proxmox com CPU "kvm64")
grep -q avx /proc/cpuinfo && echo "AVX ok" || echo "SEM AVX"

# portas livres
sudo ss -tlnp | grep -E ':(3000|3002|4000)\b' || echo "portas livres"
```

- **Sem AVX:** ajuste o tipo de CPU da VM para `host` (ou `x86-64-v3`) no hipervisor. Se não for possível,
  troque a imagem do Mongo para `mongo:4.4` **antes** da primeira subida (o volume não volta de versão).
- **Porta ocupada:** troque `API_PORT`, `WS_PORT` ou `DASHBOARD_PORT` no `stack.env`.

## 2. DNS e Nginx Proxy Manager

Crie no DNS três registros apontando para o servidor (A ou CNAME):

| Endereço público                     | Serviço   | Proxy Host no NPM → destino        | Websockets Support |
|--------------------------------------|-----------|------------------------------------|--------------------|
| `https://pulse.apps.gan7.com.br`     | Dashboard | `http://IP_DO_SERVIDOR:4000`       | não precisa        |
| `https://api.pulse.apps.gan7.com.br` | API       | `http://IP_DO_SERVIDOR:3000`       | não precisa        |
| `https://ws.pulse.apps.gan7.com.br`  | WebSocket | `http://IP_DO_SERVIDOR:3002`       | **ligar**          |

Em cada Proxy Host, na aba **SSL**: *Request a new SSL Certificate*, **Force SSL** e **HTTP/2**.
Se o NPM estiver no mesmo servidor, use o IP da máquina (não `localhost`, que dentro do container do NPM é ele mesmo).

## 3. Gerar o stack.env (no Git Bash ou no Linux)

```bash
cd docker/portainer
bash gerar-env.sh pulse.apps.gan7.com.br
```

Isso gera as três URLs acima e segredos aleatórios. Guarde o `stack.env` em local seguro (cofre de senhas):
- `STORE_ENCRYPTION_KEY` não pode mudar depois que provedores (SMS, push etc.) forem cadastrados;
- `MONGO_USER`/`MONGO_PASSWORD` só valem na primeira criação do volume;
- `DASHBOARD_URL` precisa ser exatamente o endereço aberto no navegador (o CORS da API depende dele).

## 4. Criar a stack no Portainer

1. **Stacks → Add stack**, nome: `novu`
2. **Build method: Web editor** → colar o conteúdo de `docker-compose.yml`
3. **Environment variables → Load variables from .env file** → selecionar o `stack.env`
4. **Deploy the stack**

O servidor precisa de acesso a `ghcr.io` para baixar as imagens. A primeira subida leva alguns minutos.

## 5. Validar

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/v1/health-check   # 200
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3002/v1/health-check   # 200
```

Pelo proxy: `curl -s https://api.pulse.apps.gan7.com.br/v1/health-check`.

Abrir `https://pulse.apps.gan7.com.br`, criar a conta de administrador e pegar a API key em **Settings → API Keys**.

## Atualizar a versão

Alterar `NOVU_VERSION` nas variáveis da stack → **Update the stack** com *Re-pull image* marcado.
Faça backup do volume `novu_mongodb` antes.
