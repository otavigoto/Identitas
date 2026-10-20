import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import type { HydratedDocument } from 'mongoose';

export type ProfessorDocument = HydratedDocument<Professor>;

@Schema({ collection: 'professores', timestamps: true })
export class Professor {
  @Prop({
    type: String,
    required: true,
    trim: true,
    minlength: 2,
    maxlength: 150,
  })
  nome!: string;

  @Prop({
    type: String,
    required: true,
    trim: true,
    lowercase: true,
    maxlength: 254,
  })
  email!: string;

  @Prop({
    type: String,
    required: true,
    trim: true,
    minlength: 1,
    maxlength: 50,
  })
  matriculaFuncional!: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ProfessorSchema = SchemaFactory.createForClass(Professor);
ProfessorSchema.index({ email: 1 }, { unique: true });
ProfessorSchema.index({ matriculaFuncional: 1 }, { unique: true });
