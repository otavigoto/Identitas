import {
  ConflictException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import { Professor } from './entities/professor.entity.js';
import { CreateProfessorDto } from './dto/create-professor.dto.js';
import { UpdateProfessorDto } from './dto/update-professor.dto.js';

@Injectable()
export class ProfessorService {
  constructor(
    @InjectModel(Professor.name)
    private readonly professorModel: Model<Professor>,
  ) {}

  async create(createProfessorDto: CreateProfessorDto) {
    try {
      // Await unique indexes before accepting concurrent registrations.
      await this.professorModel.init();
      const professor = await this.professorModel.create(createProfessorDto);
      return {
        id: professor._id.toString(),
        nome: professor.nome,
        email: professor.email,
        matriculaFuncional: professor.matriculaFuncional,
        createdAt: professor.createdAt,
        updatedAt: professor.updatedAt,
      };
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 11000
      ) {
        throw new ConflictException(
          'E-mail ou matrícula funcional já cadastrado.',
        );
      }
      throw new InternalServerErrorException(
        'Não foi possível cadastrar o professor.',
      );
    }
  }

  findAll() {
    return `This action returns all professor`;
  }

  findOne(id: number) {
    return `This action returns a #${id} professor`;
  }

  update(id: number, updateProfessorDto: UpdateProfessorDto) {
    return `This action updates a #${id} professor`;
  }

  remove(id: number) {
    return `This action removes a #${id} professor`;
  }
}
