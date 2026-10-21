import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { CreateAlunoDto } from '../../aluno/dto/create-aluno.dto.js';

export type TurmaDocument = HydratedDocument<Turma>;

@Schema({ timestamps: true }) 
export class Turma {
  
  @Prop({ required: true }) 
  nome: string;

  @Prop({ required: true })
  disciplina: string;

  @Prop({ required: true })
  semestre: string;

  @Prop({ required: true})
  id_professor: string;

  @Prop({ required: true})
  listaAlunos: string;
}

export const TurmaSchema = SchemaFactory.createForClass(Turma);