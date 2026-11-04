import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClassesService } from './classes.service.js';
import { ClassesController } from './classes.controller.js';
import { Turma, TurmaSchema } from './schemas/turma.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Turma.name, schema: TurmaSchema }]),
  ],
  controllers: [ClassesController],
  providers: [ClassesService],
})
export class ClassesModule {}
