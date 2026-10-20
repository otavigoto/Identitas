import {
  Body,
  Controller,
  HttpCode,
  Inject,
  Post,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsString, Length } from 'class-validator';
import { AuthService } from './auth.service.js';

export class LoginDto {
  @IsString()
  @Length(1, 150)
  login!: string;

  @IsString()
  @Length(1, 256)
  senha!: string;
}

@Controller('auth')
export class AuthController {
  constructor(@Inject(AuthService) private readonly auth: AuthService) {}

  @Post('login')
  @HttpCode(200)
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
      expectedType: LoginDto,
    }),
  )
  login(@Body() body: LoginDto) {
    return this.auth.login(body.login, body.senha);
  }
}
