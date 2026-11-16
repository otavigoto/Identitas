import { IsNotEmpty, IsString } from 'class-validator';

export class ManageClassStudentDto {
  @IsString()
  @IsNotEmpty()
  alunoId: string;
}
