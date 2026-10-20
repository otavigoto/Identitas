import { Module } from '@nestjs/common';
import { ProfessorService } from './professor.service.js';
import { ProfessorController } from './professor.controller.js';

@Module({
  controllers: [ProfessorController],
  providers: [ProfessorService],
})
export class ProfessorModule {}
