import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AlunoService } from './aluno.service.js';
import { AlunoController } from './aluno.controller.js';
import { Aluno, AlunoSchema } from './schema/aluno.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Aluno.name, schema: AlunoSchema }]),
  ],
  controllers: [AlunoController],
  providers: [AlunoService],
})
export class AlunoModule {}
