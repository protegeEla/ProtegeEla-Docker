# Lista de erros do backend e do frontend

Registro dos erros e avisos que apareceram durante a execução do ProtegeEla,
com as causas e soluções aplicadas. O PostgreSQL `protegeela` do pgAdmin foi
mantido no Windows; frontend, backend e Redis são executados em containers.

## Backend

### 1. URL do banco fora do formato JDBC

- **Mensagem:** `'url' must start with "jdbc"`.
- **Causa:** a variável de ambiente usada para a URL do banco continha um valor
  que não começava com `jdbc:`.
- **Solução:** o backend monta a URL JDBC com `DB_HOST`, `DB_PORT` e `DB_NAME`.
  No Docker, `DB_HOST=host.docker.internal` aponta para o PostgreSQL instalado
  no Windows.

### 2. Migration tentou criar tabela existente

- **Mensagem:** `relation "app_contacts" already exists` ao executar
  `V1__application_schema.sql`.
- **Causa:** uma cópia compilada antiga de `V1` permaneceu em
  `target/classes` depois que as migrations foram consolidadas em `V5`.
- **Solução:** limpar os artefatos antigos com `mvnw clean`. O Dockerfile do
  backend também compila a aplicação após limpar o diretório gerado. As tabelas
  e os dados do PostgreSQL foram preservados; o Flyway confirmou que o schema
  estava atualizado.

### 3. Porta 8080 já estava ocupada

- **Mensagem:** `Web server failed to start. Port 8080 was already in use`.
- **Causa:** outro processo do Windows já usava a porta 8080.
- **Solução:** o Compose publica o backend na porta 8081 do Windows e mantém a
  porta 8080 dentro do container. A API fica em `http://localhost:8081/api`.

### 4. Maven mostrou sucesso mesmo com falha ao iniciar o Spring

- **Mensagem:** `BUILD SUCCESS` apareceu depois de um erro de inicialização do
  Spring.
- **Causa:** o build Maven pode terminar mesmo que a aplicação falhe ao iniciar
  em tempo de execução.
- **Solução:** confirmar o estado do container e consultar
  `http://localhost:8081/api/health`; a resposta esperada é
  `{"status":"ok"}`.

### 5. Conexão ao PostgreSQL do Windows a partir do Docker

- **Problema:** `localhost` dentro do backend Docker apontaria para o próprio
  container, não para o PostgreSQL do Windows.
- **Solução:** Compose configura `host.docker.internal:5432`, banco
  `protegeela`. A conexão ao PostgreSQL 18.6 foi confirmada; Flyway informou
  que o schema estava atualizado.

## Frontend

### 1. Flutter não estava instalado ou no PATH

- **Mensagem:** `flutter` não era reconhecido no CMD.
- **Causa:** o Flutter SDK não estava disponível no Windows.
- **Solução:** o Dockerfile instala Flutter 3.47.5 no container do frontend;
  não é preciso instalar Flutter no Windows.

### 2. Comandos de PowerShell usados no CMD

- **Problema:** instruções como `Copy-Item` e `$env:VARIAVEL` não funcionam no
  Prompt de Comando.
- **Causa:** eram comandos específicos do PowerShell.
- **Solução:** o guia Docker usa `docker compose` e comandos compatíveis com
  CMD.

### 3. Página ainda não respondia durante a primeira inicialização

- **Sintoma:** a conexão com `localhost:3000` foi fechada enquanto o container
  ainda iniciava o servidor web.
- **Causa:** na primeira execução, o Flutter baixou os componentes web e as
  dependências e compilou o app.
- **Solução:** aguardar no log do frontend a mensagem indicando que o app está
  sendo servido em `0.0.0.0:3000`. Depois, `http://localhost:3000` respondeu
  com HTTP 200.

## Avisos que não bloquearam a execução

- O Flutter avisa que o dispositivo `web-server` não oferece a mesma depuração
  do Chrome/Edge sem uma extensão Dart. Isso não impede abrir o frontend no
  navegador.
- O Flutter informa que existem versões mais novas de alguns pacotes. Isso não
  impediu o `flutter pub get` nem a execução do app.
- O backend exibiu uma senha de segurança gerada pelo Spring para uso de
  desenvolvimento. É um aviso de configuração, não a senha do PostgreSQL.

## Estado verificado

- Frontend: `http://localhost:3000` respondeu HTTP 200.
- API: `http://localhost:8081/api/health` respondeu HTTP 200 com
  `{"status":"ok"}`.
- Backend conectado a `host.docker.internal:5432/protegeela` no PostgreSQL 18.6.
- Containers `frontend`, `backend` e `redis` iniciaram; backend e Redis ficaram
  saudáveis.

Veja [README_DOCKER.md](README_DOCKER.md) para executar o projeto.
