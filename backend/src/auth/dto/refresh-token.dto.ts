import { PartialType } from '@nestjs/mapped-types';
import { ValidateAuthDto } from './validate-auth.dto.js';

export class UpdateAuthDto extends PartialType(ValidateAuthDto) {}