import { IsEmail, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateAlunoDto {
  @IsNotEmpty({ message: 'O nome é obrigatório' })
  @IsString()
  nome: string;

  @IsNotEmpty({ message: 'O RA é obrigatório' })
  @IsString()
  ra: string;

  @IsNotEmpty({ message: 'A senha é obrigatória' })
  @IsString()
  @MinLength(6, { message: 'A senha deve ter no mínimo 6 caracteres' })
  password: string;

  @IsOptional()
  @IsString()
  nfcUid?: string;
}