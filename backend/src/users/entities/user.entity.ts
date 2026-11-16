import {Prop, Schema, SchemaFactory} from '@nestjs/mongoose';
import { Role} from "../../common/enums/role.enum.js";
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema( {timestamps: true})
export class User {

  @Prop({required: true})
  name: string;
  
  @Prop({required: true, unique: true})
  ra: string;

  @Prop({required:true})
  course: string;

  @Prop({required: true, default: 0})
  periodSemester: string;

  @Prop({required: true})
  password: string;

  @Prop({required: true})
  role: Role;

  @Prop({unique: true})
  nfcUid: string;
}

export const UserSchema = SchemaFactory.createForClass(User);