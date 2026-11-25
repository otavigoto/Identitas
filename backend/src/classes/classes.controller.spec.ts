import 'reflect-metadata';
import { ForbiddenException } from '@nestjs/common';
import { Role } from '../common/enums/role.enum.js';
import { ROLES_KEY } from '../common/decorators/roles.decorator.js';
import { ClassesController } from './classes.controller.js';
import type { ClassesService } from './classes.service.js';

const GUARDS_METADATA = '__guards__';
const METHOD_METADATA = 'method';
const teacherId = '507f1f77bcf86cd799439012';
const otherTeacherId = '507f1f77bcf86cd799439099';

/** Todas as rotas do controller (métodos com decorator @Get/@Post/...). */
function routeHandlers() {
  return Object.getOwnPropertyNames(ClassesController.prototype)
    .filter((name) => name !== 'constructor')
    .map((name) => ({
      name,
      handler: (ClassesController.prototype as unknown as Record<string, object>)[
        name
      ] as object,
    }))
    .filter(({ handler }) => Reflect.hasMetadata(METHOD_METADATA, handler));
}

describe('ClassesController: autenticação e perfis', () => {
  it('nenhuma rota de turmas é pública: todas exigem token e perfil', () => {
    const routes = routeHandlers();
    expect(routes.length).toBeGreaterThan(10);

    for (const { name, handler } of routes) {
      const guards = Reflect.getMetadata(GUARDS_METADATA, handler) as
        | { name: string }[]
        | undefined;
      expect(
        guards?.map((guard) => guard.name),
        `${name} sem JwtAuthGuard/RolesGuard`,
      ).toEqual(['JwtAuthGuard', 'RolesGuard']);

      const roles = Reflect.getMetadata(ROLES_KEY, handler) as Role[] | undefined;
      expect(roles?.length, `${name} sem @Roles`).toBeGreaterThan(0);
    }
  });

  it.each([
    'create',
    'remove',
    'update',
    'findAll',
    'findOne',
    'addStudent',
    'removeStudent',
  ])('%s é só para professor', (name) => {
    const handler = (
      ClassesController.prototype as unknown as Record<string, object>
    )[name];
    expect(Reflect.getMetadata(ROLES_KEY, handler)).toEqual([Role.PROFESSOR]);
  });
});

describe('ClassesController: turma em nome de outro professor', () => {
  const service = {
    create: vi.fn(),
    update: vi.fn(),
  } as unknown as ClassesService;
  const controller = new ClassesController(service);
  const req = { user: { sub: teacherId, ra: '1', role: Role.PROFESSOR } } as never;
  const baseClass = {
    name: 'Banco de Dados',
    week: 'Segunda-feira',
    startTime: '08:00',
    endTime: '10:00',
    attendanceStatus: 'closed',
  };

  it('não deixa criar turma com id_professor de outro', () => {
    expect(() =>
      controller.create(
        { ...baseClass, id_professor: otherTeacherId } as never,
        req,
      ),
    ).toThrow(ForbiddenException);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('cria a turma quando o id_professor é o do próprio token', () => {
    controller.create({ ...baseClass, id_professor: teacherId } as never, req);
    expect(service.create).toHaveBeenCalledTimes(1);
  });

  it('não deixa passar a turma para outro professor pelo PATCH', () => {
    expect(() =>
      controller.update('id', { id_professor: otherTeacherId }, req),
    ).toThrow(ForbiddenException);
    expect(service.update).not.toHaveBeenCalled();
  });
});
