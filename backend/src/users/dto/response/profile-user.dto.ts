import { IsString } from "class-validator";
import { Role } from "../../../common/enums/role.enum.js";

export class ProfileUserDto {
  @IsString()
  name: string;

  @IsString()
  role: Role;

  @IsString()
  ra: string;

  @IsString()
  course: string;

  @IsString()
  periodSemester: string;

  @IsString()
  nfcUid: string;
}