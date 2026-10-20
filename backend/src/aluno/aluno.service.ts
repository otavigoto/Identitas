import { 
  Injectable, 
  NotFoundException, 
  ConflictException, 
  InternalServerErrorException 
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';

import {Aluno, Role} from './schema/aluno.schema.js';
import { CreateAlunoDto } from './dto/create-aluno.dto.js';
import { UpdateAlunoDto } from './dto/update-aluno.dto.js';

@Injectable()
export class AlunoService {
  constructor(
    @InjectModel(Aluno.name) private readonly alunoModel: Model<Aluno>,
  ) {}

  async create(createAlunoDto: CreateAlunoDto): Promise<Aluno> {
  try {
    const { ra, password, ...rest } = createAlunoDto;

    const existingStudent = await this.alunoModel.findOne({ 
      ra: ra 
    });

    if (existingStudent) {
      throw new ConflictException('RA já cadastrado');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const student = new this.alunoModel({
      ...rest,
      ra,
      passwordHash: hashedPassword,
      role: Role.ALUNO,
    });

    await student.save();
    return student;
  } catch (error: any) {
    if (error instanceof ConflictException) {
      throw error;
    }
    throw new InternalServerErrorException('Erro ao criar aluno: ' + error.message);
  }
}

  findAll() {
    return this.alunoModel.find();
  }

  findOne(id: string) {
    return this.alunoModel.findById(id);
  }

  update(id: string, updateAlunoDto: UpdateAlunoDto) {
    return this.alunoModel.findByIdAndUpdate(id, updateAlunoDto, { new: true });
  }

  remove(id: string) {
    return this.alunoModel.findByIdAndDelete(id);
  }
}
