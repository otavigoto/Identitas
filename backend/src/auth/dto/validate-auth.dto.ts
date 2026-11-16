import { Prop } from "@nestjs/mongoose";
import { IsString } from 'class-validator';

export class ValidateAuthDto {
  @IsString()
  ra: string;

  @IsString()
  password: string;
}
