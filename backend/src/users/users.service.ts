import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto.js';
import { UpdateUserDto } from './dto/update-user.dto.js';
import { InjectModel } from '@nestjs/mongoose';
import { User } from './entities/user.entity.js';


@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: any) {}
  create(createUserDto: CreateUserDto) {
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

  async assignNfcKey(id: string, nfcKey: string) {
    const existingUser = await this.userModel.findOne({ nfcKey }).exec();
    if (existingUser && existingUser._id.toString() !== id) {
      throw new BadRequestException('Esta chave NFC já está cadastrada para outro usuário.');
    }

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, { nfcKey }, { new: true })
      .exec();

    if (!updatedUser) {
      throw new NotFoundException(`Usuário com ID ${id} não encontrado.`);
    }

    return updatedUser;
  }
}
