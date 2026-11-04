import { SetMetadata } from '@nestjs/common';
import { Role } from '../enums/role.enum.js';

export const ROLES_KEY = 'identitas:roles';

export function Roles(...roles: [Role, ...Role[]]) {
  if (
    roles.length === 0 ||
    roles.some((role) => !Object.values(Role).includes(role))
  ) {
    throw new Error('@Roles exige pelo menos um perfil válido.');
  }
  return SetMetadata(ROLES_KEY, roles);
}
