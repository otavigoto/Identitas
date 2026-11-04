import 'reflect-metadata';
import { Controller, Get, type INestApplication, UseGuards } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import type { NextFunction, Response } from 'express';
import request from 'supertest';
import {
  AuthorizationModule,
  type AuthenticatedRequest,
  type AuthenticatedUser,
  CurrentUser,
  Role,
  Roles,
  RolesGuard,
} from '../src/authorization/index.js';

@Controller('restricted')
@UseGuards(RolesGuard)
@Roles(Role.PROFESSOR)
class RestrictedController {
  @Get('teacher')
  teacher() {
    return { allowed: true };
  }

  @Get('student')
  @Roles(Role.STUDENT)
  student(@CurrentUser() user: AuthenticatedUser) {
    return user;
  }

  @Get('shared')
  @Roles(Role.STUDENT, Role.PROFESSOR)
  shared(@CurrentUser('id') id: string) {
    return { id };
  }
}

@Controller('authenticated')
@UseGuards(RolesGuard)
class AuthenticatedController {
  @Get()
  get() {
    return { allowed: true };
  }
}

// Isola o comportamento do decorator quando não há guard.
@Controller('decorator')
class DecoratorController {
  @Get()
  get(@CurrentUser() user: AuthenticatedUser) {
    return user;
  }
}

describe('Authorization HTTP', () => {
  let app: INestApplication;
  let authenticatedUser: unknown;
  const id = '507f1f77bcf86cd799439011';

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AuthorizationModule],
      controllers: [
        RestrictedController,
        AuthenticatedController,
        DecoratorController,
      ],
    }).compile();
    app = module.createNestApplication();
    // Fixture local: não lê identidade fornecida por clientes HTTP.
    app.use((req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
      req.user = authenticatedUser as AuthenticatedUser | undefined;
      next();
    });
    await app.init();
  });

  beforeEach(() => {
    authenticatedUser = undefined;
  });

  afterAll(async () => {
    await app?.close();
  });

  it.each([
    [Role.STUDENT, '/restricted/student', 200],
    [Role.PROFESSOR, '/restricted/student', 403],
    [Role.PROFESSOR, '/restricted/teacher', 200],
    [Role.STUDENT, '/restricted/teacher', 403],
    [Role.STUDENT, '/restricted/shared', 200],
    [Role.PROFESSOR, '/restricted/shared', 200],
    [Role.STUDENT, '/authenticated', 200],
    [Role.PROFESSOR, '/authenticated', 200],
  ])('%s acessa %s com status %i', async (role, path, status) => {
    authenticatedUser = { id, role };
    await request(app.getHttpServer()).get(path).expect(status);
  });

  it.each(['/restricted/teacher', '/authenticated', '/decorator'])(
    'retorna 401 sem usuário em %s',
    async (path) => {
      await request(app.getHttpServer()).get(path).expect(401);
    },
  );

  it.each([undefined, null, 'ADMIN', 'UNKNOWN', 'student', 1])(
    'retorna 403 para perfil inválido %s, mesmo sem @Roles',
    async (role) => {
      authenticatedUser = { id, role };
      await request(app.getHttpServer()).get('/authenticated').expect(403);
      await request(app.getHttpServer()).get('/restricted/shared').expect(403);
    },
  );

  it('retorna o usuário autenticado completo', async () => {
    authenticatedUser = { id, role: Role.STUDENT };
    await request(app.getHttpServer())
      .get('/restricted/student')
      .expect(200, authenticatedUser);
  });

  it('extrai somente o identificador solicitado', async () => {
    authenticatedUser = { id, role: Role.PROFESSOR };
    await request(app.getHttpServer())
      .get('/restricted/shared')
      .expect(200, { id });
  });

  it('não aceita identidade do body, query ou headers', async () => {
    await request(app.getHttpServer())
      .get('/restricted/teacher')
      .query({ id, role: Role.PROFESSOR })
      .set('x-user-id', id)
      .set('x-role', Role.PROFESSOR)
      .send({ user: { id, role: Role.PROFESSOR } })
      .expect(401);
  });

  it('não permite sobrescrever o perfil autenticado pela requisição', async () => {
    authenticatedUser = { id, role: Role.STUDENT };
    await request(app.getHttpServer())
      .get('/restricted/teacher')
      .set('x-role', Role.PROFESSOR)
      .query({ role: Role.PROFESSOR })
      .expect(403);
  });
});

describe('@Roles', () => {
  it('rejeita declaração sem perfis também em runtime', () => {
    // @ts-expect-error Verifica também chamadas JavaScript sem argumentos.
    expect(() => Roles()).toThrow('pelo menos um perfil válido');
  });

  it('rejeita perfis fora do enum', () => {
    // @ts-expect-error ADMIN não faz parte dos perfis do Identitas.
    expect(() => Roles('ADMIN')).toThrow('pelo menos um perfil válido');
  });
});
