import { IsNotEmpty, IsString } from 'class-validator';

export class CreateTurmaDto {
  @IsString({ message: 'O nome deve ser um texto' })
  @IsNotEmpty({ message: 'O nome não pode ficar em branco' })
  nome: string;

  @IsString({ message: 'A disciplina deve ser um texto' })
  @IsNotEmpty({ message: 'A disciplina não pode ficar em branco' })
  disciplina: string;

  @IsString({ message: 'O semestre deve ser um texto' })
  @IsNotEmpty({ message: 'O semestre não pode ficar em branco' })
  semestre: string;

  @IsString({ message: 'O nome do professor deve ser um texto' })
  @IsNotEmpty({ message: 'O nome do professor não pode ficar em branco' })
  professor: string;

  @IsString({ message: 'A lista de alunos deve ser um texto' })
  @IsNotEmpty({ message: 'A lista de alunos não pode ficar em branco' })
  listaAlunos: string;


}