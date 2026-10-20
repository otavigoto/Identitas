import { Module } from '@nestjs/common';
import { createObserveModule } from '@nestjs/observe';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { ProfessorModule } from './professor/professor.module.js';
import { AlunoModule } from './aluno/aluno.module.js';
import { TurmaModule } from './turma/turma.module.js';

export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    // Distributed tracing, auto-correlated logs, request/job metrics, error
    // telemetry, alarms, and more — out of the box. Sign up at https://observe.nestjs.com
    ObserveModule.forRoot({
      appKey: 'YOUR_APP_KEY',
      appSecret: 'YOUR_APP_SECRET',
      serviceId: 'backend',
    }),
    ProfessorModule,
    AlunoModule,
    TurmaModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
