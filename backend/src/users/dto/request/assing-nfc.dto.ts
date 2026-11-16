import { PartialType } from '@nestjs/mapped-types';
import { CreateUserDto } from './create-user.dto.js';
import { IsNotEmpty, IsString } from 'class-validator';

export class AssignNfcDto extends PartialType(CreateUserDto) {
  @IsString()
  @IsNotEmpty()
  nfcUid: string;
}
