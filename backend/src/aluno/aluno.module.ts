import { Module } from '@nestjs/common';
import { AlunoService } from './aluno.service.js';
import { AlunoController } from './aluno.controller.js';

@Module({
  controllers: [AlunoController],
  providers: [AlunoService],
})
export class AlunoModule {}
