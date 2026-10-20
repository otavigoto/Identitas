import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { Test } from '@nestjs/testing';
import { MongooseModule, getConnectionToken } from '@nestjs/mongoose';
import type { INestApplication } from '@nestjs/common';
import type { Connection } from 'mongoose';
import request from 'supertest';
import { ProfessorModule } from '../src/professor/professor.module.js';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { hashPassword } from '../src/auth/password.js';

// Always isolated from the application's identitas database.
const database = `identitas_test_${randomUUID().replaceAll('-', '')}`;
const uri = `mongodb://127.0.0.1:27017/${database}`;
const valid = {
  nome: 'Maria Silva',
  email: 'maria@example.com',
  matriculaFuncional: '000123',
};

describe('POST /professor (MongoDB local)', () => {
  let app: INestApplication;
  let connection: Connection;
  let token: string;
  const secret = randomUUID() + randomUUID();
  const settings: Record<string, string> = {
    ADMIN_LOGIN: 'admin-test',
    ADMIN_PASSWORD_HASH: hashPassword('test-password-only'),
    JWT_SECRET: secret,
  };

  function createProfessor(body: unknown) {
    return request(app.getHttpServer())
      .post('/professor')
      .set('Authorization', `Bearer ${token}`)
      .send(body as object);
  }

  async function start() {
    const module = await Test.createTestingModule({
      imports: [
        MongooseModule.forRoot(uri, {
          retryAttempts: 0,
          serverSelectionTimeoutMS: 3000,
        }),
        ProfessorModule,
      ],
    })
      .overrideProvider(ConfigService)
      .useValue({
        get: (key: string) => settings[key],
      })
      .compile();
    app = module.createNestApplication();
    connection = app.get<Connection>(getConnectionToken());
    await app.init();
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ login: 'admin-test', senha: 'test-password-only' })
      .expect(200);
    token = login.body.accessToken;
  }

  beforeAll(start, 15000);
  beforeEach(async () => {
    await connection.collection('professores').deleteMany({});
  });
  afterAll(async () => {
    if (connection?.readyState === 1) await connection.dropDatabase();
    await app?.close();
  });

  it('normalizes input, returns the public representation and persists across app restarts', async () => {
    const response = await createProfessor({
      nome: '  Maria Silva  ',
      email: ' MARIA@EXAMPLE.COM ',
      matriculaFuncional: ' 000123 ',
    }).expect(201);
    expect(response.body).toEqual({
      ...valid,
      id: expect.stringMatching(/^[a-f0-9]{24}$/),
      createdAt: expect.any(String),
      updatedAt: expect.any(String),
    });
    await app.close();
    await start();
    const saved = await connection
      .collection('professores')
      .findOne({ email: valid.email });
    expect(saved?.matriculaFuncional).toBe('000123');
    expect(saved?._id.toString()).toBe(response.body.id);
  });

  it.each([
    {},
    { ...valid, nome: undefined },
    { ...valid, email: undefined },
    { ...valid, matriculaFuncional: undefined },
    { ...valid, nome: '   ' },
    { ...valid, nome: 'x'.repeat(151) },
    { ...valid, email: 'invalid-email' },
    { ...valid, email: `${'a'.repeat(250)}@example.com` },
    { ...valid, matriculaFuncional: 123 },
    { ...valid, matriculaFuncional: 'x'.repeat(51) },
    { ...valid, matriculaFuncional: ' ' },
    { ...valid, nome: null },
    { ...valid, email: null },
    { ...valid, matriculaFuncional: null },
    { ...valid, nome: 123 },
    { ...valid, email: 123 },
    { ...valid, senha: 'not-accepted' },
    { ...valid, perfil: 'PROFESSOR' },
  ])('rejects invalid payload %# without saving', async (body) => {
    await createProfessor(body).expect(400);
    expect(await connection.collection('professores').countDocuments()).toBe(0);
  });

  it.each(['email', 'matriculaFuncional'] as const)(
    'rejects concurrent duplicate %s with HTTP 409',
    async (field) => {
      const second = {
        nome: 'Outra Pessoa',
        email: 'outra@example.com',
        matriculaFuncional: '456',
      };
      second[field] = valid[field];
      const results = await Promise.all(
        [valid, second].map((body) => createProfessor(body)),
      );
      expect(
        results.map((result) => result.status).sort((a, b) => a - b),
      ).toEqual([201, 409]);
      expect(await connection.collection('professores').countDocuments()).toBe(
        1,
      );
    },
  );

  it('rejects email duplicates after normalization', async () => {
    await createProfessor(valid).expect(201);
    await createProfessor({
      ...valid,
      email: ' MARIA@EXAMPLE.COM ',
      matriculaFuncional: '456',
    }).expect(409);
  });

  it('requires authentication', async () => {
    await request(app.getHttpServer())
      .post('/professor')
      .send(valid)
      .expect(401);
    await request(app.getHttpServer())
      .post('/professor')
      .set('Authorization', 'Bearer invalid')
      .send(valid)
      .expect(401);
    expect(await connection.collection('professores').countDocuments()).toBe(0);
  });

  it.each(['ALUNO', 'PROFESSOR'])('forbids authenticated %s', async (role) => {
    const otherToken = new JwtService().sign(
      { sub: 'other-user', role },
      {
        secret,
        issuer: 'identitas',
        audience: 'identitas-api',
        expiresIn: '15m',
      },
    );
    await request(app.getHttpServer())
      .post('/professor')
      .set('Authorization', `Bearer ${otherToken}`)
      .send(valid)
      .expect(403);
    expect(await connection.collection('professores').countDocuments()).toBe(0);
  });

  it('rejects expired admin tokens', async () => {
    const expired = new JwtService().sign(
      { sub: 'admin-test', role: 'ADMIN' },
      {
        secret,
        issuer: 'identitas',
        audience: 'identitas-api',
        expiresIn: -1,
      },
    );
    await request(app.getHttpServer())
      .post('/professor')
      .set('Authorization', `Bearer ${expired}`)
      .send(valid)
      .expect(401);
  });

  it('rejects incorrect credentials and client-selected roles', async () => {
    for (const body of [
      { login: 'admin-test', senha: 'wrong' },
      { login: 'other', senha: 'test-password-only' },
    ]) {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send(body)
        .expect(401);
    }
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ login: 'admin-test', senha: 'test-password-only', role: 'ADMIN' })
      .expect(400);
  });
});
