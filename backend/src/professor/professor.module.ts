import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { MongooseModule } from '@nestjs/mongoose';
import { Professor, ProfessorSchema } from './entities/professor.entity.js';
import { ProfessorService } from './professor.service.js';
import { ProfessorController } from './professor.controller.js';

@Module({
  imports: [
    AuthModule,
    MongooseModule.forFeature([
      { name: Professor.name, schema: ProfessorSchema },
    ]),
  ],
  controllers: [ProfessorController],
  providers: [ProfessorService],
})
export class ProfessorModule {}
