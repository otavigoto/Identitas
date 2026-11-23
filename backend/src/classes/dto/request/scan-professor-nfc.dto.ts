import { IsNotEmpty, IsString } from 'class-validator';

export class ScanProfessorNfcDto {
  @IsString()
  @IsNotEmpty()
  nfcUid: string;
}
