# ProtegeEla Frontend

[![CI](https://github.com/protegeEla/protegeela-frontend/actions/workflows/ci.yml/badge.svg)](https://github.com/protegeEla/protegeela-frontend/actions/workflows/ci.yml)

Aplicação web responsiva em Flutter, conectada ao backend Java/PostgreSQL.

> Versão demonstrativa. Não substitui serviços oficiais nem deve ser usada em
> uma emergência real. Criar um alerta não envia SMS, WhatsApp ou push.

## Funcionalidades

- Cadastro, login, edição de perfil e modo discreto.
- Rede de apoio com criação, edição e remoção de contatos.
- Convites temporários com aceite/recusa e canal preferido por contato.
- Alertas com localização opcional, acompanhamento e encerramento.
- Modo “Cheguei bem”, com prazo no backend e trajeto compartilhável por link privado.
- Mapa de alertas aproximados e pontos de apoio do OpenStreetMap.
- Atualização do mapa por WebSocket, com recuperação por HTTP.
- Orientações pesquisáveis, categorias, favoritos, leitura em voz alta e PWA instalável.

Confirmação de e-mail está temporariamente desativada; o cadastro e o login
funcionam sem SMTP. O código e a tela de confirmação ficam no projeto para uma
ativação futura. Recuperação de senha e envio automático de notificações ainda
não estão disponíveis. O link do trajeto pode ser enviado manualmente por
WhatsApp ou copiado para outro canal.

## Executar com Docker no Windows (CMD)

Instale e abra o Docker Desktop. Não é necessário instalar Flutter, Java ou
Redis no Windows: o Compose instala e executa o Flutter dentro do container e
sobe o frontend, backend e Redis. O PostgreSQL existente do pgAdmin é mantido.

Consulte o [guia completo para executar com Docker](README_DOCKER.md) para
iniciar, parar, acompanhar os logs e solucionar problemas.

No Prompt de Comando, execute:

```bat
cd /d "%USERPROFILE%\Documents\protegeela\protegeela-frontend"
docker compose up --build
```

Abra `http://localhost:3000`. A API roda em `http://localhost:8081/api` e se
conecta ao PostgreSQL `protegeela` no Windows. Deixe o Docker Desktop e a janela
do CMD abertos enquanto usa o app; pressione `Ctrl+C` para parar os serviços.
Para iniciar depois sem reconstruir, use `docker compose up`.

O backend usa por padrão usuário `postgres` e senha `luiz`. Se a senha do seu
PostgreSQL for diferente, defina-a no CMD antes de iniciar:

```bat
set DB_PASSWORD=sua-senha
docker compose up --build
```

Consulte [Erros encontrados e soluções](ERROS_E_SOLUCOES.md) para causas e
correções dos problemas de inicialização anteriores.

## Integração e privacidade

O token de sessão fica apenas em memória, exceto quando “Lembrar de mim” é marcado.
Contatos e alertas pertencem à conta autenticada. O mapa exibe somente alertas
compartilhados explicitamente, com localização aproximada. Alertas silenciosos
são privados; a posição exata é removida do banco ativo ao encerrar o alerta.

O WebSocket deriva sua URL de `API_BASE_URL` e autentica sem token na URL.
Redis compartilha cache e eventos entre backends. Catálogos podem ser preenchidos
pelas rotas administrativas; a busca de locais usa OpenStreetMap sem chave.

- [Endpoints da API](../protegeela-backend/API.md)
- [Busca de pontos de apoio](../protegeela-backend/OPENSTREETMAP.md)
- [Redis e WebSocket sem Docker](../protegeela-backend/REDIS_WEBSOCKET.md)
- [Revisão de segurança e pendências](../protegeela-backend/SECURITY_REVIEW.md)

A PWA não consegue atualizar o GPS continuamente com o navegador fechado. Nesse
caso, o mapa mantém a última posição, mas o prazo do “Cheguei bem” continua no
backend. A saída rápida
não apaga o histórico nem encerra a sessão. Dados pendentes locais não são
armazenamento secreto: são descartados após 24 horas na leitura ou no logout.
Os resultados do OpenStreetMap não são verificados pelo ProtegeEla.

## Estrutura

```text
lib/app/       # aplicação, rotas e tema
lib/core/      # configuração, serviços e widgets compartilhados
lib/features/  # apresentação e acesso a dados por funcionalidade
lib/shared/    # modelos compartilhados
assets/        # ilustrações
web/           # página inicial, manifesto e ícones da PWA
scripts/       # auditoria de referências e tamanho dos arquivos
```

Riverpod gerencia estado e dependências; GoRouter controla a navegação.
A autorização e as regras de acesso a dados são aplicadas pelo backend.

## Verificar e compilar

```powershell
dart format --output=none --set-exit-if-changed lib scripts
dart run scripts/audit_frontend.dart
flutter analyze --no-pub
flutter build web --release --no-pub
```

A CI executa essas verificações em pull requests e pushes para `main`.
O Dependabot acompanha dependências Dart e GitHub Actions.

## Publicar

Na Netlify, `build.sh` instala a versão configurada do Flutter e gera `build/web`.
Defina `API_BASE_URL` com a URL HTTPS pública da API no ambiente de build.
Configure `FRONTEND_ORIGINS` no backend e inclua as origens HTTPS/WSS da API em
`connect-src` no arquivo `netlify.toml`. O proxy deve aceitar upgrade WebSocket.
Não publique um build apontando para `localhost`.

## Contribuir

Preserve acessibilidade, privacidade e linguagem acolhedora. Execute as
verificações e descreva o impacto das alterações. Não inclua dados pessoais,
coordenadas reais, senhas ou tokens no código, logs ou relatos.

Relate vulnerabilidades pelo
[canal privado do GitHub](https://github.com/protegeEla/protegeela-frontend/security/advisories/new).

## Licença e créditos

Licença MIT: [LICENSE](LICENSE).
Projeto idealizado e desenvolvido por **ConderTech — A desenvolvedora**.
