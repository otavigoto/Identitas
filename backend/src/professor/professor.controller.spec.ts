import { Test, TestingModule } from '@nestjs/testing';
import { ProfessorController } from './professor.controller.js';
import { ProfessorService } from './professor.service.js';
import { AdminGuard } from '../auth/admin.guard.js';

describe('ProfessorController', () => {
  let controller: ProfessorController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ProfessorController],
      providers: [{ provide: ProfessorService, useValue: { create: vi.fn() } }],
    })
      .overrideGuard(AdminGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<ProfessorController>(ProfessorController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
