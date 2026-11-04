# Autorização do Identitas

Perfis disponíveis: `Role.STUDENT` e `Role.PROFESSOR`. Não existe perfil `ADMIN`.

Importe `AuthorizationModule` no módulo que declara o controller protegido.
O módulo exporta `RolesGuard`, mas não o registra globalmente. Importar o módulo
sozinho não protege endpoints.

## Integração com autenticação

A camada de autenticação deve validar o access token e preencher `request.user`
com `{ id: string, role: Role }`, onde `id` é o ObjectId do usuário serializado.
Se o JWT utiliza `sub`, a autenticação deve mapeá-lo para `id`. O perfil deve vir
de uma fonte validada pelo servidor. Não incluir senha ou hash nesse objeto.
Não copiar identidade/perfil do body, query ou headers personalizados.

O guard de autenticação deve executar antes de `RolesGuard`. A implementação de
login, validação JWT e refresh tokens pertence ao módulo Auth e não está incluída.
Exemplo para um controller futuro (o `AuthGuard` abaixo será fornecido pelo Auth):

```ts
@Controller('users')
@UseGuards(AuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me/student')
  @Roles(Role.STUDENT)
  getStudentProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getStudentProfile(userId);
  }
}
```

Importe `Role`, `Roles`, `RolesGuard`, `CurrentUser` e `AuthorizationModule`
de `authorization/index.js` usando o caminho relativo ao arquivo consumidor.
`@CurrentUser()` retorna `AuthenticatedUser`; `@CurrentUser('id')` retorna o ID.

## Regras

- `@Roles` exige pelo menos um perfil válido. Vários perfis funcionam como OU.
- Os perfis do método substituem os do controller; não são somados.
- Com `RolesGuard`, ausência de usuário retorna 401; perfil ausente, inválido
  ou sem permissão retorna 403. Sem `@Roles`, aceita qualquer um dos dois perfis
  autenticados. O guard não valida tokens por conta própria.
- `@CurrentUser` retorna 401 se o usuário não estiver presente.
- Sem aplicar `RolesGuard`, `@Roles` apenas registra metadados e não protege a rota.

| Operação futura | Perfil |
| --- | --- |
| Consultar o próprio perfil de aluno | STUDENT |
| Consultar turmas do professor e sua sessão ativa | PROFESSOR |
| Abrir e encerrar sessões | PROFESSOR |
| Vincular tag NFC | Fora desta entrega; sem endpoint disponibilizado |

Os serviços devem verificar propriedade e matrícula. Um professor autorizado
pelo perfil ainda não pode abrir ou encerrar aulas de outro professor. Use o ID
autenticado nas consultas e operações do próprio usuário, não um ID escolhido
pelo cliente. As permissões de outras operações deverão ser definidas na sua
implementação; não são inferidas apenas pelo nome do serviço.

## Validação

Execute `npm test -- test/authorization.spec.ts`. Os testes criam uma aplicação
Nest isolada com usuário definido por fixture interna, sem MongoDB nem JWT real.
Essa fixture é exclusiva dos testes e não deve ser usada na aplicação.

O backend atual referencia módulos de negócio ausentes no `AppModule`; esses
componentes precisam ser restaurados pela equipe para executar a aplicação inteira.
