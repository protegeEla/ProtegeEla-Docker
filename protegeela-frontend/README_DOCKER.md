# Executar frontend e backend juntos com Docker

Este guia inicia o frontend Flutter, o backend Java e o Redis juntos usando
Docker Compose. O PostgreSQL do pgAdmin continua no Windows para manter o banco
existente `protegeela`.

## Requisitos

- Docker Desktop instalado e aberto.
- PostgreSQL do pgAdmin iniciado no Windows.
- Banco `protegeela`, usuÃ¡rio `postgres` e a senha configurada para esse banco.

NÃ£o Ã© necessÃ¡rio instalar Flutter, Java ou Redis no Windows. O Flutter SDK Ã©
instalado na imagem Docker do frontend.

## Iniciar os serviÃ§os

Abra o **Prompt de Comando (CMD)** e execute:

```bat
cd /d "%USERPROFILE%\Documents\protegeela"
docker compose up --build
```

Na primeira execuÃ§Ã£o, o Docker baixa as imagens, instala o Flutter dentro do
container, compila a versÃƒÂ£o web de produÃƒÂ§ÃƒÂ£o e compila o backend. Aguarde a
mensagem `Built build/web` nos logs do frontend antes de abrir a pÃƒÂ¡gina.

- Frontend: <http://localhost:3000>
- API: <http://localhost:8081/api>
- VerificaÃ§Ã£o da API: <http://localhost:8081/api/health>

O backend no container conecta ao PostgreSQL do Windows por
`host.docker.internal:5432`. O Compose publica a API na porta `8081` porque a
porta `8080` do Windows pode jÃ¡ estar ocupada.

## Abrir pelo celular na mesma rede Wi-Fi

No celular, abra o frontend pelo endereco IPv4 atual do computador, que pode
ser consultado com `ipconfig` no Windows. Crie ou edite
`.env` na pasta raiz `protegeela` e defina `HOST_LAN_IP` com esse endereco. O Compose
usara esse valor para configurar o endereco da API:

```dotenv
HOST_LAN_IP=IPV4_ATUAL_DO_COMPUTADOR
```

Depois execute `docker compose up --build -d` novamente e use o mesmo IP no
celular. Permita as portas 3000 e 8081 no Firewall do Windows, se solicitado.
HTTP na rede local Ã© para desenvolvimento; a geolocalizaÃ§Ã£o do navegador exige
HTTPS. No Flutter Web, a sessÃ£o fica no armazenamento do navegador; use essa
configuraÃ§Ã£o apenas para desenvolvimento local e nÃ£o para contas ou redes de
produÃ§Ã£o.

### Usar GPS no celular com HTTPS gratuito

Para permitir que o navegador do celular leia o GPS, abra um **Prompt de
Comando (CMD)** nesta pasta e execute (troque pelo seu e-mail):

```bat
set "TUNNEL_ALLOWED_EMAIL=seu-email@exemplo.com"
docker compose -f compose.yaml -f protegeela-frontend/compose.location-https.yaml up --build
```

Espere o container `location-https` mostrar o endereÃ§o
`https://...trycloudflare.com` nos logs e abra esse endereÃ§o no celular. A
Cloudflare enviarÃ¡ um cÃ³digo de acesso para o e-mail configurado; apÃ³s
entrar, permita a localizaÃ§Ã£o no navegador e tambÃ©m nas configuraÃ§Ãµes do
celular. O endereÃ§o temporÃ¡rio muda quando o tÃºnel reinicia. Esse tÃºnel Ã©
gratuito, mas publica o app na internet com acesso restrito ao e-mail informado;
pare os containers com `Ctrl+C` quando terminar.

## ConfirmaÃ§Ã£o por e-mail

A confirmaÃ§Ã£o por cÃ³digo estÃ¡ temporariamente desativada. O cadastro funciona
sem SMTP; a tela, as rotas e o envio estÃ£o preservados para correÃ§Ã£o e ativaÃ§Ã£o
futuras. Para reativar, configure `EMAIL_VERIFICATION_ENABLED=true` e as
variÃ¡veis SMTP no `.env` antes de iniciar os containers. NÃ£o salve senhas no
cÃ³digo-fonte; use uma credencial SMTP autorizada para envio.

## Comandos Ãºteis

Para iniciar em segundo plano:

```bat
docker compose up --build -d
```

Ver o estado dos serviÃ§os:

```bat
docker compose ps
```

Ver os logs:

```bat
docker compose logs -f
```

Parar os containers:

```bat
docker compose down
```

`docker compose down` mantÃ©m os volumes do Redis e do cache Flutter. O banco
PostgreSQL permanece no Windows. NÃ£o use `docker compose down -v` se quiser
manter os volumes do Docker.

## ConfiguraÃ§Ã£o do PostgreSQL

Por padrÃ£o, o Compose usa o banco `protegeela`, usuÃ¡rio `postgres` e senha
`luiz`. Se a senha for diferente, crie um arquivo `.env` na mesma pasta deste
guia, com:

```dotenv
DB_PASSWORD=sua-senha-do-postgres
```

O arquivo `.env` Ã© local e nÃ£o deve ser enviado ao Git. Se o PostgreSQL nÃ£o
aceitar conexÃµes do Docker, confira se o servidor estÃ¡ ativo e aceita conexÃµes
pela rede local do Docker Desktop.

## SoluÃ§Ã£o rÃ¡pida de problemas

- **Docker nÃ£o inicia:** abra o Docker Desktop e aguarde ficar pronto.
- **`port is already allocated`:** feche o serviÃ§o que usa a porta 3000 ou
  8081 antes de subir os containers.
- **Erro de conexÃ£o com PostgreSQL:** verifique se o PostgreSQL do Windows estÃ¡
  ativo, se o banco `protegeela` existe e se a senha em `.env` estÃ¡ correta.
- **Frontend nÃ£o conecta Ã  API:** confira se os containers `backend` e `redis`
  estÃ£o ativos com `docker compose ps` e se o endpoint de saÃºde retorna
  `{"status":"ok"}`.

Para instruÃ§Ãµes sobre os problemas anteriores de inicializaÃ§Ã£o, consulte
[Erros encontrados e soluÃ§Ãµes](ERROS_E_SOLUCOES.md).

