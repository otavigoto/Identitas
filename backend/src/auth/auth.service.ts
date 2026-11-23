import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { Role } from '../common/enums/role.enum.js';
import { UsersService } from '../users/users.service.js';
import { UpdateAuthDto } from './dto/update-auth.dto.js';
import { ValidateAuthDto } from './dto/validate-auth.dto.js';

export interface JwtPayload {
  sub: string;
  ra: string;
  role: Role;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(validateAuthDto: ValidateAuthDto) {
    const { ra, password } = validateAuthDto;
    const user = await this.usersService.findByRa(ra);

    if (!user) {
      throw new UnauthorizedException('RA ou senha inválidos.');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('RA ou senha inválidos.');
    }

    const payload: JwtPayload = {
      sub: user._id.toString(),
      ra: user.ra,
      role: user.role,
    };

    const tokens = await this.generateTokens(payload);

    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  async refreshToken(token: string) {
    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(token);

      const user = await this.usersService.findOne(payload.sub);
      if (!user) {
        throw new UnauthorizedException('Usuário não encontrado.');
      }

      const newPayload: JwtPayload = {
        sub: user._id.toString(),
        ra: user.ra,
        role: user.role,
      };

      return await this.generateTokens(newPayload);
    } catch {
      throw new UnauthorizedException('Refresh token inválido ou expirado.');
    }
  }

  async updateAuth(userId: string, updateAuthDto: UpdateAuthDto) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new NotFoundException(`Usuário com ID ${userId} não encontrado.`);
    }

    const dataToUpdate: Partial<{ ra: string; password: string }> = {};

    if (updateAuthDto.ra && updateAuthDto.ra !== user.ra) {
      const existingRa = await this.usersService.findByRa(updateAuthDto.ra);
      if (existingRa && existingRa._id.toString() !== userId) {
        throw new BadRequestException(
          'Este RA já está cadastrado para outro usuário.',
        );
      }
      dataToUpdate.ra = updateAuthDto.ra;
    }

    if (updateAuthDto.password) {
      if (!updateAuthDto.currentPassword) {
        throw new BadRequestException(
          'Informe a senha atual para definir uma nova senha.',
        );
      }

      const isCurrentValid = await bcrypt.compare(
        updateAuthDto.currentPassword,
        user.password,
      );
      if (!isCurrentValid) {
        throw new BadRequestException('A senha atual está incorreta.');
      }

      dataToUpdate.password = updateAuthDto.password;
    }

    const updatedUser = await this.usersService.update(userId, dataToUpdate);

    const tokens = await this.generateTokens({
      sub: updatedUser._id.toString(),
      ra: updatedUser.ra,
      role: updatedUser.role,
    });

    return {
      user: this.sanitizeUser(updatedUser),
      ...tokens,
    };
  }

  async getProfile(userId: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new NotFoundException(`Usuário com ID ${userId} não encontrado.`);
    }

    return this.sanitizeUser(user);
  }

  private sanitizeUser(user: any) {
    const userObj =
      typeof user.toObject === 'function' ? user.toObject() : user;
    const { password: _, ...userWithoutPassword } = userObj;
    return userWithoutPassword;
  }

  private async generateTokens(payload: JwtPayload) {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        expiresIn: '7d',
      }),
    ]);

    return {
      accessToken,
      refreshToken,
    };
  }
}
