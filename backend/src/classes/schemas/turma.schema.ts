import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type TurmaDocument = HydratedDocument<Turma>;

@Schema({ collection: 'turmas', timestamps: true })
export class Turma {
  @Prop({ required: true, trim: true })
  nome: string;

  @Prop({ required: true, trim: true })
  disciplina: string;

  @Prop({ required: true, trim: true })
  semestre: string;

  @Prop({ required: true, trim: true })
  id_professor: string;

  @Prop({ type: [String], default: [] })
  listaAlunos: string[];
}

export const TurmaSchema = SchemaFactory.createForClass(Turma);
