import { Body, Controller, Get, Patch, Post, Req, UseGuards, } from '@nestjs/common';
import type { Request } from 'express';
import { Roles } from '../common/decorators/roles.decorator.js';
import { Role } from '../common/enums/role.enum.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import { AuthService, type JwtPayload } from './auth.service.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { UpdateAuthDto } from './dto/update-auth.dto.js';
import { ValidateAuthDto } from './dto/validate-auth.dto.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post()
  validateUser(@Body() validateAuthDto: ValidateAuthDto) {
    return this.authService.validateUser(validateAuthDto);
  }

  @Post('refresh')
  refreshToken(@Body() refreshTokenDto: RefreshTokenDto) {
    return this.authService.refreshToken(refreshTokenDto.refreshToken);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR, Role.STUDENT)
  getProfile(@Req() req: Request & { user: JwtPayload }) {
    return this.authService.getProfile(req.user.sub);
  }

  @Patch('update')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR, Role.STUDENT)
  updateAuth(
    @Req() req: Request & { user: JwtPayload },
    @Body() updateAuthDto: UpdateAuthDto,
  ) {
    return this.authService.updateAuth(req.user.sub, updateAuthDto);
  }
}