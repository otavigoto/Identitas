# Rotas da API

Este documento lista as rotas declaradas nos controllers do backend. Os caminhos
são relativos ao host da API; o projeto não configura um prefixo global.

## Autenticação

As rotas protegidas usam o header:

```http
Authorization: Bearer <accessToken>
```

O token contém `sub` (ID MongoDB do usuário), `ra` e `role`. O RA é usado para
login; NFC UID identifica um cartão e não substitui o ID do usuário.

| Método | Rota | Acesso | O que faz |
| --- | --- | --- | --- |
| `POST` | `/auth` | Público | Autentica com RA e senha. Retorna usuário sem senha, `accessToken` e `refreshToken`. |
| `POST` | `/auth/refresh` | Público, exige refresh token no body | Valida o refresh token e emite um novo access token e refresh token. |
| `GET` | `/auth/profile` | `STUDENT`, `PROFESSOR` | Retorna o perfil associado ao access token, sem precisar enviar o ID na URL. |
| `PATCH` | `/auth/update` | `STUDENT`, `PROFESSOR` | Altera RA e/ou senha do usuário autenticado. Ao alterar a senha, exige `currentPassword`. Retorna o usuário e novos tokens. |

### Bodies de autenticação

`POST /auth`:

```json
{ "ra": "RA123", "password": "senha" }
```

`POST /auth/refresh`:

```json
{ "refreshToken": "<refreshToken>" }
```

`PATCH /auth/update` aceita propriedades opcionais:

```json
{
  "ra": "RA456",
  "password": "nova-senha",
  "currentPassword": "senha-atual"
}
```

## Usuários

Todas as rotas de `/users` exigem access token.

| Método | Rota | Acesso | O que faz |
| --- | --- | --- | --- |
| `POST` | `/users` | `PROFESSOR` | Cria usuário. A senha é armazenada como hash. |
| `GET` | `/users` | `PROFESSOR` | Lista usuários. |
| `GET` | `/users/:id` | `STUDENT`, `PROFESSOR` | Busca usuário pelo ID MongoDB. |
| `GET` | `/users/profile/:id` | `STUDENT`, `PROFESSOR` | Busca perfil pelo ID MongoDB. |
| `PATCH` | `/users/:id` | `STUDENT`, `PROFESSOR` | Atualiza os campos enviados para o usuário indicado. |
| `DELETE` | `/users/:id` | `STUDENT`, `PROFESSOR` | Remove o usuário indicado. |
| `PATCH` | `/users/:id/nfc` | `STUDENT`, `PROFESSOR` | Vincula um NFC UID ao usuário indicado. O UID é normalizado para maiúsculas e não pode estar vinculado a outro usuário. |

O body de criação aceita `name`, `ra`, `course`, `periodSemester`, `password`,
`role` (`STUDENT` ou `PROFESSOR`) e, opcionalmente, `nfcUid`. O body de
atualização aceita um subconjunto desses campos. Para atribuir NFC:

```json
{ "nfcUid": "A1B2C3D4" }
```

## Turmas e disciplinas

### CRUD e matrícula

As rotas desta tabela não declaram guard de autenticação no controller.

| Método | Rota | Acesso declarado | O que faz |
| --- | --- | --- | --- |
| `POST` | `/classes` | Público | Cria uma turma/disciplina. |
| `GET` | `/classes` | Público | Lista turmas. Aceita query params `disciplina` e `semestre`; atualmente `disciplina` filtra o campo `week` e `semestre` filtra `attendanceStatus`. |
| `GET` | `/classes/:id` | Público | Busca uma turma pelo ID MongoDB. |
| `PATCH` | `/classes/:id` | Público | Atualiza os campos enviados da turma. |
| `DELETE` | `/classes/:id` | Público | Remove a turma. |
| `POST` | `/classes/:id/students` | Público | Adiciona alunos à turma sem duplicar IDs já matriculados. Recebe `{ "enrolledStudents": ["<studentId>"] }`. |
| `DELETE` | `/classes/:id/students/:studentId` | Público | Remove um aluno da turma. |

O body de criação da turma inclui `name`, `id_professor`, `week`, `startTime`,
`endTime` e `attendanceStatus` (`open` ou `closed`). Também pode incluir
`enrolledStudents`, `qtdAulas`, `attendanceTime` e `attendanceList`. Os horários
devem usar `HH:mm`.

> **Atenção:** “Público” significa que essas rotas não têm `JwtAuthGuard` no
> controller atualmente. Não envie dados sensíveis assumindo que elas exigem
> autenticação.

### Aulas do usuário autenticado

| Método | Rota | Acesso | O que faz |
| --- | --- | --- | --- |
| `GET` | `/classes/me/today` | `STUDENT`, `PROFESSOR` | Retorna `{ user, classes }` para o dia. O aluno recebe `attendanceRecorded` e `present` em cada aula; o professor recebe somente as informações de horário. Aceita `?date=AAAA-MM-DD` para consultar outra data. |
| `GET` | `/classes/me/weekly` | `STUDENT`, `PROFESSOR` | Retorna `{ user, classes }` da semana. O aluno recebe frequência e histórico por turma e `overallAttendance`; o professor recebe disciplinas e horários, sem frequência. |
| `GET` | `/classes/student/:studentId/today` | `STUDENT`, somente o próprio ID | Lista aulas do dia para o estudante autenticado. Aceita `?date=AAAA-MM-DD`. |
| `GET` | `/classes/student/:studentId` | `STUDENT`, somente o próprio ID | Lista turmas em que o estudante autenticado está matriculado. |
| `GET` | `/classes/teacher/:teacherId` | `PROFESSOR`, somente o próprio ID | Lista turmas ministradas pelo professor autenticado. |

Nos endpoints `/classes/me/...`, o usuário é identificado pelo `sub` do access
token; não envie RA ou NFC UID como parâmetro de usuário.

### Chamada e frequência

| Método | Rota | Acesso | O que faz |
| --- | --- | --- | --- |
| `GET` | `/classes/:id/students` | `PROFESSOR` responsável pela turma | Retorna a lista de alunos para a chamada do dia, com `id`, `name`, `ra`, `nfcUid` e `present`, além dos totais presentes e ausentes. Aceita `?date=AAAA-MM-DD`. |
| `GET` | `/classes/:id/students/all` | `PROFESSOR` responsável pela turma | Retorna o resumo geral e o histórico de frequência dos alunos da turma. |
| `GET` | `/classes/:id/attendance/summary` | `PROFESSOR` responsável pela turma | Retorna frequência geral da turma e frequência/histórico de cada aluno. |
| `PATCH` | `/classes/:id/attendance/open` | `PROFESSOR` responsável pela turma | Abre a chamada e inicia a janela de cinco minutos para registrar presença. |
| `POST` | `/classes/:id/students/attendance` | `PROFESSOR` responsável pela turma | Registra ou atualiza a presença da turma. Retorna HTTP `200`. |
| `POST` | `/classes/:id/students/attendance/nfc` | `PROFESSOR` responsável pela turma | Marca como presentes os alunos identificados pelos NFC UIDs enviados. Retorna HTTP `200`. |
| `POST` | `/classes/:id/attendance/scan-professor` | `STUDENT` matriculado na turma | Valida o NFC do professor da turma e registra a presença do aluno autenticado. Retorna HTTP `200`. |

Para enviar a chamada completa após o professor comparar os cartões com a lista,
`POST /classes/:id/students/attendance` aceita cada aluno matriculado uma única
vez:

```json
{
  "students": [
    { "studentId": "<id-mongodb-do-aluno>", "present": true },
    { "studentId": "<id-mongodb-de-outro-aluno>", "present": false }
  ]
}
```

Também é aceito o formato legado `{ "presentStudentIds": ["<studentId>"] }`.
Opcionalmente, ambos os formatos podem receber `"date": "2026-11-23T12:00:00.000Z"`.

Leitura dos cartões dos alunos pelo professor, em
`POST /classes/:id/students/attendance/nfc`:

```json
{ "nfcUids": ["A1B2C3D4", "E5F6A7B8"] }
```

Leitura do cartão do professor pelo aluno, em
`POST /classes/:id/attendance/scan-professor`:

```json
{ "nfcUid": "A1B2C3D4" }
```

IDs enviados como `studentId` são IDs MongoDB, não RA nem NFC UID. O endpoint de
chamada completa valida que todos os alunos matriculados estejam presentes no
body e que nenhum aluno de outra turma seja enviado.

Se algum ID de `enrolledStudents` não existir mais como usuário, as rotas
`GET /classes/:id/students`, `GET /classes/:id/students/all` e
`GET /classes/:id/attendance/summary` **não falham**: elas devolvem os alunos
encontrados em `students` e os ausentes em `missingStudents`:

```json
{
  "students": [{ "id": "...", "name": "Ana", "ra": "RA001", "present": false }],
  "missingStudents": [{ "id": "<id-mongodb>", "message": "Aluno não encontrado." }]
}
```

Os alunos em `missingStudents` não entram em `totalStudents`, e o envio da
chamada completa exige todos os matriculados: remova-os da turma antes
(`DELETE /classes/:id/students/:studentId`).

## Respostas de erro comuns

- `400 Bad Request`: body inválido, ID inválido, aluno não matriculado, chamada
  fechada/expirada ou lista de presença incompleta.
- `401 Unauthorized`: access token ausente, inválido ou expirado.
- `403 Forbidden`: role sem permissão ou tentativa de consultar o ID de outro
  estudante/professor nas rotas que comparam o ID com o token.
- `404 Not Found`: usuário, turma ou NFC não encontrado; também é retornado
  quando um professor tenta acessar turma que não lhe pertence.
