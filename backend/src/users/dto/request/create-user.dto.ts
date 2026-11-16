import { IsOptional, IsString } from "class-validator";
import { Role} from "../../../common/enums/role.enum.js";

export class CreateUserDto {
  @IsString()
  name: string;

  @IsString()
  ra: string;

  @IsString()
  course: string;

  @IsString()
  periodSemester: string;

  @IsString()
  password: string;

  @IsString()
  role: Role;

  @IsOptional()
  @IsString()
  nfcUid: string;
}