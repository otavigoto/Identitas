import {
  ArrayUnique,
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateClassDto {
  @IsString()
  @IsNotEmpty()
  nome: string;

  @IsString()
  @IsNotEmpty()
  disciplina: string;

  @IsString()
  @IsNotEmpty()
  semestre: string;

  @IsString()
  @IsNotEmpty()
  id_professor: string;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  listaAlunos?: string[];
}
