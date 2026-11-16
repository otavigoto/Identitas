import { Type } from 'class-transformer';
import {
  ArrayUnique,
  IsArray,
  IsDate,
  IsOptional,
  IsString,
} from 'class-validator';

export class MarkAttendanceNfcDto {
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  nfcUids: string[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  date?: Date;
}