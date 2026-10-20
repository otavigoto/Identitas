import {
  Inject,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { verifyPassword } from './password.js';

@Injectable()
export class AuthService {
  constructor(
    @Inject(ConfigService) private readonly config: ConfigService,
    @Inject(JwtService) private readonly jwt: JwtService,
  ) {}

  private settings() {
    const login = this.config.get<string>('ADMIN_LOGIN');
    const hash = this.config.get<string>('ADMIN_PASSWORD_HASH');
    const secret = this.config.get<string>('JWT_SECRET');
    if (!login || !hash || !secret || secret.length < 32) {
      throw new ServiceUnavailableException(
        'Configure o administrador com npm run admin:setup.',
      );
    }
    return { login, hash, secret };
  }

  async login(login: string, senha: string) {
    const config = this.settings();
    const passwordMatches = verifyPassword(senha, config.hash);
    if (login !== config.login || !passwordMatches) {
      throw new UnauthorizedException('Login ou senha inválidos.');
    }
    return {
      accessToken: await this.jwt.signAsync(
        { sub: config.login, role: 'ADMIN' },
        {
          secret: config.secret,
          algorithm: 'HS256',
          expiresIn: '15m',
          issuer: 'identitas',
          audience: 'identitas-api',
        },
      ),
      tokenType: 'Bearer',
      expiresIn: 900,
    };
  }

  async verify(token: string): Promise<{ sub: string; role: string }> {
    const config = this.settings();
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string; role: string }>(
        token,
        {
          secret: config.secret,
          algorithms: ['HS256'],
          issuer: 'identitas',
          audience: 'identitas-api',
        },
      );
      if (typeof payload.sub !== 'string' || typeof payload.role !== 'string')
        throw new Error();
      if (payload.role === 'ADMIN' && payload.sub !== config.login)
        throw new Error();
      return payload;
    } catch {
      throw new UnauthorizedException('Token inválido ou expirado.');
    }
  }
}
