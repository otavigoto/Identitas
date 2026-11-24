import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import type { JwtPayload } from '../auth/auth.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { Role } from '../common/enums/role.enum.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import { AssignNfcDto } from './dto/request/assing-nfc.dto.js';
import { CreateUserDto } from './dto/request/create-user.dto.js';
import { UpdateUserDto } from './dto/request/update-user.dto.js';
import { ProfileUserDto } from './dto/response/profile-user.dto.js';
import { UsersService } from './users.service.js';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // CRUD USERS -----------------------

  @Post()
  @Roles(Role.PROFESSOR)
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Patch(':id')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }

  @Get()
  @Roles(Role.PROFESSOR)
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  // FIM CRUD USERS -----------------------

  @Get('profile/:id')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  findProfile(@Param('id') id: string) {
    return this.usersService.findOne(id) as ProfileUserDto;
  }

  @Patch(':id/nfc')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  assignNfc(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
    @Body() assignNfcDto: AssignNfcDto,
  ) {
    if (id !== req.user.sub) {
      throw new ForbiddenException(
        'Só é possível vincular o NFC à sua própria conta.',
      );
    }
    return this.usersService.assignNfcKey(id, assignNfcDto.nfcUid);
  }
}
