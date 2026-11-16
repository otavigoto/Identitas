import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcrypt';
import { CreateUserDto } from './dto/request/create-user.dto.js';
import { UpdateUserDto } from './dto/request/update-user.dto.js';
import { User } from './entities/user.entity.js';


@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: any) {}

  // CRUD USERS -----------------------

  async create(createUserDto: CreateUserDto) {
    createUserDto.password = await bcrypt.hash(createUserDto.password, 10);
    return this.userModel.create(createUserDto);
  }

  findAll() {
    return this.userModel.find();
  }

  findOne(id: string) {
    return this.userModel.findById(id);
  }

  update(id: string, updateUserDto: UpdateUserDto) {
    return this.userModel.findByIdAndUpdate(id, updateUserDto, { new: true });
  }

  remove(id: string) {
    return this.userModel.findByIdAndRemove(id);
  }

  // FIM CRUD USERS -----------------------

  findByRa(ra: string) {
    const user = this.userModel.findOne({ ra });
    if (!user) {
      throw new NotFoundException(`Usuário com RA ${ra} não encontrado.`);
    }
    return user;
  }

  async findByNfcUid(nfcUid: string) {
    const user = await this.userModel.findOne({ nfcUid });
    if (!user) {
      throw new NotFoundException(`Usuário com NFC UID ${nfcUid} não encontrado.`);
    }
    return user;
  }

  async assignNfcKey(id: string, nfcUid: string) {
    const existingUser = await this.userModel.findOne({ nfcUid }).exec();
    if (existingUser && existingUser._id.toString() !== id) {
      throw new BadRequestException('Esta chave NFC já está cadastrada para outro usuário.');
    }

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, { nfcUid }, { new: true })
      .exec();

    if (!updatedUser) {
      throw new NotFoundException(`Usuário com ID ${id} não encontrado.`);
    }

    return updatedUser;
  }
}
