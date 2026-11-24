import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
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
    if (createUserDto.nfcUid) {
      createUserDto.nfcUid = createUserDto.nfcUid.trim().toUpperCase();
    }
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
    return this.userModel.findOne({ ra }).exec();
  }

  async findByNfcUid(nfcUid: string) {
    const user = await this.userModel
      .findOne({ nfcUid: nfcUid.trim().toUpperCase() })
      .exec();
    if (!user) {
      throw new NotFoundException(
        `Usuário com NFC UID ${nfcUid} não encontrado.`,
      );
    }
    return user;
  }

  async assignNfcKey(id: string, nfcUid: string) {
    const normalizedNfcUid = nfcUid.trim().toUpperCase();
    const existingUser = await this.userModel
      .findOne({ nfcUid: normalizedNfcUid })
      .exec();
    if (existingUser && existingUser._id.toString() !== id) {
      throw new BadRequestException(
        'Esta chave NFC já está cadastrada para outro usuário.',
      );
    }

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, { nfcUid: normalizedNfcUid }, { new: true })
      .exec();

    if (!updatedUser) {
      throw new NotFoundException(`Usuário com ID ${id} não encontrado.`);
    }

    const user = updatedUser.toObject();
    delete user.password;
    return user;
  }
}
