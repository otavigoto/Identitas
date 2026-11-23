import { Type } from 'class-transformer';
import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsDate,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Min,
  ValidateNested,
} from 'class-validator';

export enum AttendanceStatus {
  OPEN = 'open',
  CLOSED = 'closed',
}

// Criamos uma classe separada para o item da lista (boa prática para validação)
class StudentAttendanceRecordDto {
  @IsString()
  @IsNotEmpty()
  studentId: string;

  @IsBoolean()
  present: boolean;
}

class AttendanceItemDto {
  @IsDate()
  @Type(() => Date)
  date: Date;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => StudentAttendanceRecordDto)
  students: StudentAttendanceRecordDto[];
}

export class CreateClassDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  id_professor: string;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  enrolledStudents?: string[];

  @IsString()
  @IsNotEmpty({ message: 'O campo week não pode estar vazio' })
  week: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  qtdAulas?: number;

  @IsString()
  @IsNotEmpty()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'startTime deve estar no formato HH:mm (ex: 08:30)',
  })
  startTime: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'endTime deve estar no formato HH:mm (ex: 17:30)',
  })
  endTime: string;

  @IsNotEmpty()
  attendanceStatus: AttendanceStatus;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  attendanceTime?: Date;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AttendanceItemDto)
  attendanceList?: AttendanceItemDto[];
}
