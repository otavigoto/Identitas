import type { Request } from 'express';
import type { Role } from '../common/enums/role.enum.js';

export interface AuthenticatedUser {
  /** MongoDB ObjectId serializado como string. */
  id: string;
  role: Role;
}

/** Preenchido exclusivamente pela camada de autenticação após validar o token. */
export type AuthenticatedRequest = Request & { user?: AuthenticatedUser };
