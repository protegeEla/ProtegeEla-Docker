<<<<<<< HEAD
﻿# ProtegeEla

Projeto dividido em dois módulos:

- `protegeela-frontend`: aplicativo Flutter Web e interface.
- `protegeela-backend`: API Spring Boot, PostgreSQL, Redis e WebSocket.
- `compose.yaml`: Docker Compose na raiz que coordena os dois módulos.

## Executar os dois módulos com Docker

Abra um terminal na pasta raiz `protegeela` e execute:

```sh
docker compose up --build
```

O frontend fica em `http://localhost:3000` e a API em
`http://localhost:8081/api`. O Compose usa o PostgreSQL existente no Windows;
consulte `protegeela-frontend/README_DOCKER.md` para configurar a conexão e
acessar o app pelo celular.

## Estado da confirmação de e-mail

O cadastro funciona sem SMTP. A confirmação por código foi preservada, mas fica
desativada por padrão com `EMAIL_VERIFICATION_ENABLED=false`. Para ativá-la no
futuro, configure SMTP e habilite a variável no `.env` ao lado do `compose.yaml`.

## Documentação

- `protegeela-frontend/README.md`: frontend e comandos de execução.
- `protegeela-backend/README.md`: API, configuração e organização do código.
- `protegeela-backend/API.md`: endpoints e formatos de requisição.
=======
# ProtegeEla-Docker
>>>>>>> b17f8457ce6130293b6238c93526764743c2a373
