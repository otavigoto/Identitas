import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type TurmaDocument = HydratedDocument<Turma>;

@Schema({ timestamps: true }) 
export class Turma {
  
  @Prop({ required: true }) 
  nome: string;

  @Prop({ required: true })
  disciplina: string;

  @Prop({ required: true })
  semestre: string;
}

export const TurmaSchema = SchemaFactory.createForClass(Turma);