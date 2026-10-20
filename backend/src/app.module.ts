import { Module } from '@nestjs/common';
//import { createObserveModule } from '@nestjs/observe';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { ProfessorModule } from './professor/professor.module.js';
import { AlunoModule } from './aluno/aluno.module.js';
import { TurmaModule } from './turma/turma.module.js';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';


//export const { ObserveModule, ObserveInstrument } = createObserveModule();

console.log(process.env.MONGODB);

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MongooseModule.forRoot(process.env.MONGODB ?? ''),
    /*
    // Distributed tracing, auto-correlated logs, request/job metrics, error
    // telemetry, alarms, and more — out of the box. Sign up at https://observe.nestjs.com
    ObserveModule.forRoot({
      appKey: process.env.APP_KEY!,
      appSecret: process.env.APP_SECRET!,
      serviceId: 'backend',
    }),
    */
    ProfessorModule,
    AlunoModule,
    TurmaModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
