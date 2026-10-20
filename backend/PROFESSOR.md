# Cadastro de professor

Esta entrega implementa `POST /professor`, permitido somente ao perfil `ADMIN`,
e `POST /auth/login` para autenticar o administrador inicial configurado no backend.
As demais rotas geradas pelo NestJS continuam sendo exemplos; ainda não consultam nem alteram o banco.

## Preparação

1. Instale as dependências com `npm ci` dentro de `backend`.
2. Copie `.env.example` para `.env` caso ainda não exista.
3. Inicie o serviço local MongoDB na porta 27017. No Windows, se ele foi instalado como serviço,
   use `Start-Service MongoDB` em um PowerShell com permissão administrativa.
   Como alternativa, crie uma pasta de dados e execute
   `mongod --dbpath <pasta-de-dados> --bind_ip 127.0.0.1 --port 27017`.
4. Execute `npm run admin:setup` dentro de `backend` e informe login e senha.
   A senha é digitada sem exibição e somente seu hash scrypt é salvo no `.env`.
   O comando também gera `JWT_SECRET`. Executá-lo novamente substitui o administrador
   e invalida tokens anteriores, portanto use-o somente para configurar ou trocar essas credenciais.
5. Execute `npm run start:dev` dentro de `backend`.

Configuração local:

```dotenv
MONGODB_URI=mongodb://127.0.0.1:27017/identitas
```

O `.env` não deve ser versionado. A conexão fica no backend, nunca no Flutter.

## Exemplo no PowerShell

```powershell
$credencial = Get-Credential -Message "Administrador do Identitas"
$loginBody = @{
  login = $credencial.UserName
  senha = $credencial.GetNetworkCredential().Password
} | ConvertTo-Json
$sessao = Invoke-RestMethod -Method Post -Uri http://localhost:3000/auth/login `
  -ContentType "application/json" -Body $loginBody

$professorBody = @{
  nome = "Maria da Silva"
  email = "maria@example.com"
  matriculaFuncional = "000123"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri http://localhost:3000/professor `
  -Headers @{ Authorization = "Bearer $($sessao.accessToken)" } `
  -ContentType "application/json" -Body $professorBody
```

O cadastro retorna HTTP 201 com `id`, `nome`, `email`, `matriculaFuncional`,
`createdAt` e `updatedAt`. Repetir e-mail ou matrícula retorna 409; dados inválidos
ou campos extras retornam 400. Matrícula é texto e preserva zeros iniciais.
Nome aceita 2–150 caracteres; matrícula, 1–50; e-mail deve ser válido e ter até 254.
Espaços nas extremidades são removidos e o e-mail é convertido para minúsculas.

Os registros ficam na coleção `professores`. Índices únicos garantem a exclusividade
mesmo quando requisições chegam simultaneamente.

## Verificação

```powershell
npm run build
npm test
npm run test:e2e
```

Os testes de integração exigem o MongoDB local e usam um banco temporário exclusivo
`identitas_test_<uuid>`, removido ao terminar. Não utilizam o banco `identitas`.
Cobrem validação, normalização, concorrência e persistência após reiniciar a aplicação.

O token expira em 15 minutos. Login/senha incorretos, token inválido ou expirado e ausência
de token retornam 401. Um token válido sem perfil ADMIN retorna 403.
Sem configuração do administrador, o login retorna 503 e não libera acesso.
O perfil é atribuído no backend, nunca recebido do formulário de login.

O ID do professor poderá ser associado à futura conta de usuário. Cadastrar um professor
não cria credenciais nem concede perfil ADMIN. A autenticação de alunos e professores,
recuperação de senha e limitação de tentativas de login ficam para outra entrega.
Esta configuração inicial é destinada a desenvolvimento local; use HTTPS e proteção contra
tentativas repetidas antes de publicar o login na internet.
