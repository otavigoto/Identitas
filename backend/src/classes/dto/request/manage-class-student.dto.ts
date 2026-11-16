import { IsArray, IsNotEmpty, IsString } from 'class-validator';

export class ManageClassStudentDto {
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty()
  enrolledStudents: string[]; // Array de IDs dos estudantes
}