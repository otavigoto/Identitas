import { Type } from 'class-transformer';
import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsDate,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

export class StudentAttendanceDto {
  @IsString()
  @IsNotEmpty()
  studentId: string;

  @IsBoolean()
  present: boolean;
}

export class AttendanceStudentDto {
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  presentStudentIds?: string[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => StudentAttendanceDto)
  students?: StudentAttendanceDto[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  date?: Date;
}
