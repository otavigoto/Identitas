import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { ProfessorModule } from './professor/professor.module.js';
import { AlunoModule } from './aluno/aluno.module.js';
import { TurmaModule } from './turma/turma.module.js';
import { DatabaseModule } from './database/database.module.js';

@Module({
  imports: [DatabaseModule, ProfessorModule, AlunoModule, TurmaModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
