import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import { UpdateUserDto } from './dto/update-user.dto.js';
import { AssignNfcDto } from './dto/assing-nfc.dto.js';
import { Role, Roles, RolesGuard } from '../authorization/index.js';

@Controller('users')
@UseGuards(RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @Roles(Role.PROFESSOR, Role.STUDENT)
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @Roles(Role.PROFESSOR, Role.STUDENT)
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
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

  @Patch(':id/nfc')
  @Roles(Role.PROFESSOR, Role.STUDENT)
  assignNfc(
    @Param('id') id: string,
    @Body() assignNfcDto: AssignNfcDto,
  ) {
    return this.usersService.assignNfcKey(id, assignNfcDto.nfcUid);
  }
}
