import { Type } from 'class-transformer';
import {
  ArrayUnique,
  IsArray,
  IsDate,
  IsOptional,
  IsString,
} from 'class-validator';

export class AttendanceStudentDto {
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  presentStudentIds: string[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  date?: Date;
}