import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TurmaService } from './turma.service.js';
import { TurmaController } from './turma.controller.js';
import { Turma, TurmaSchema } from './schema/turma.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Turma.name, schema: TurmaSchema }])
  ],
  controllers: [TurmaController],
  providers: [TurmaService],
})
export class TurmaModule {}