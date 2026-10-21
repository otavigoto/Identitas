import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateTurmaDto } from './dto/create-turma.dto.js';
import { UpdateTurmaDto } from './dto/update-turma.dto.js';
import { Turma, TurmaDocument } from './schema/turma.schema.js';

@Injectable()
export class TurmaService {
  constructor(
    @InjectModel(Turma.name) private turmaModel: Model<TurmaDocument>,
  ) {}

  async create(createTurmaDto: CreateTurmaDto): Promise<Turma> {
    const novaTurma = new this.turmaModel(createTurmaDto);
    return novaTurma.save();
  }

  async findAll(): Promise<Turma[]> {
    return this.turmaModel.find().exec();
  }

  async findOne(id: string): Promise<Turma> {
    const turma = await this.turmaModel.findById(id).exec();
    if (!turma) {
      throw new NotFoundException(`Turma com ID #${id} não encontrada`);
    }
    return turma;
  }

  async update(id: string, updateTurmaDto: UpdateTurmaDto): Promise<Turma> {
    const turmaAtualizada = await this.turmaModel
      .findByIdAndUpdate(id, updateTurmaDto, { new: true })
      .exec();
    if (!turmaAtualizada) {
      throw new NotFoundException(`Turma com ID #${id} não encontrada`);
    }
    return turmaAtualizada;
  }

  async remove(id: string): Promise<Turma> {
    const turmaRemovida = await this.turmaModel.findByIdAndDelete(id).exec();
    if (!turmaRemovida) {
      throw new NotFoundException(`Turma com ID #${id} não encontrada`);
    }
    return turmaRemovida;
  }
}