import {Prop, Schema, SchemaFactory} from '@nestjs/mongoose';
import { Role} from "../../common/enums/role.enum.js";

@Schema( {timestamps: true})
export class Auth {

  @Prop({required: true})
  ra: string;

  @Prop({required: true})
  password: string;
}

export const AuthSchema = SchemaFactory.createForClass(Auth);
