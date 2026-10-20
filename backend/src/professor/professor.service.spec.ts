import { Test, TestingModule } from '@nestjs/testing';
import { ProfessorService } from './professor.service.js';
import { getModelToken } from '@nestjs/mongoose';
import { Professor } from './entities/professor.entity.js';
import {
  ConflictException,
  InternalServerErrorException,
} from '@nestjs/common';

describe('ProfessorService', () => {
  let service: ProfessorService;
  const model = { init: vi.fn(), create: vi.fn() };

  beforeEach(async () => {
    vi.resetAllMocks();
    model.init.mockResolvedValue(undefined);
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfessorService,
        { provide: getModelToken(Professor.name), useValue: model },
      ],
    }).compile();

    service = module.get<ProfessorService>(ProfessorService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('translates unique-index conflicts into HTTP 409', async () => {
    model.create.mockRejectedValue({ code: 11000 });
    await expect(
      service.create({
        nome: 'Maria Silva',
        email: 'maria@example.com',
        matriculaFuncional: '001',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('does not expose internal database errors', async () => {
    model.create.mockRejectedValue(new Error('private database details'));
    const result = service.create({
      nome: 'Maria Silva',
      email: 'maria@example.com',
      matriculaFuncional: '001',
    });
    await expect(result).rejects.toBeInstanceOf(InternalServerErrorException);
    await expect(result).rejects.toThrow(
      'Não foi possível cadastrar o professor.',
    );
  });
});
