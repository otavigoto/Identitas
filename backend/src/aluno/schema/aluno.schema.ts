import {Prop, Schema, SchemaFactory} from '@nestjs/mongoose';
import {Document} from 'mongoose';

export enum Role {
    ALUNO = 'ALUNO',
    PROFESSOR = 'PROFESSOR',
}

@Schema( {collection: 'alunos', timestamps: true})
export class Aluno extends Document{

    @Prop({required:true, trim:true})
    nome:string;

    @Prop({required:true, unique:true, trim:true})
    ra: string;

    @Prop({required: true})
    passwordHash: string;

    @Prop({enum: Role, default: Role.ALUNO, required: true})
    role: Role;

    @Prop({unique:true, sparse:true})
    nfcUid: string;
}

export const AlunoSchema = SchemaFactory.createForClass(Aluno);