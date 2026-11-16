import { PartialType } from '@nestjs/mapped-types';
import { IsOptional, IsString } from 'class-validator';
import { ValidateAuthDto } from './validate-auth.dto.js';

export class UpdateAuthDto extends PartialType(ValidateAuthDto) {
  @IsOptional()
  @IsString()
  currentPassword?: string;
}
