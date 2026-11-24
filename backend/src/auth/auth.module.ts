import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import { UsersModule } from '../users/users.module.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';

const MIN_JWT_SECRET_LENGTH = 16;

/**
 * O segredo assina os tokens: se tiver um valor padrão no código, qualquer
 * pessoa com acesso ao repositório consegue forjar um token de professor. Por
 * isso ele é obrigatório e o servidor não sobe sem ele.
 */
export function requireJwtSecret(secret: string | undefined): string {
  if (!secret || secret.trim().length < MIN_JWT_SECRET_LENGTH) {
    throw new Error(
      `JWT_SECRET não definido ou curto demais (mínimo ${MIN_JWT_SECRET_LENGTH} ` +
        'caracteres). Defina no backend/.env, por exemplo com: ' +
        'node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'hex\'))"',
    );
  }
  return secret;
}

@Module({
  imports: [
    UsersModule,
    JwtModule.registerAsync({
      global: true,
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: requireJwtSecret(configService.get<string>('JWT_SECRET')),
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard, RolesGuard],
  exports: [AuthService, JwtAuthGuard, RolesGuard, JwtModule],
})
export class AuthModule {}
