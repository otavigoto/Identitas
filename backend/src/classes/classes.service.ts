import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { isValidObjectId, Model } from 'mongoose';
import { CreateClassDto } from './dto/request/create-class.dto.js';
import { UpdateClassDto } from './dto/request/update-class.dto.js';
import { Turma, TurmaDocument } from './schemas/turma.schema.js';

@Injectable()
export class ClassesService {
  constructor(
    @InjectModel(Turma.name)
    private readonly turmaModel: Model<Turma>,
  ) {}

  async create(createClassDto: CreateClassDto): Promise<TurmaDocument> {
    const { nome, disciplina, semestre, id_professor, listaAlunos = [] } =
      createClassDto;

    return this.turmaModel.create({
      nome,
      disciplina,
      semestre,
      id_professor,
      listaAlunos,
    });
  }

  async findAll(disciplina?: string, semestre?: string): Promise<Turma[]> {
    const filters: Record<string, string> = {};

    if (disciplina) {
      filters.disciplina = disciplina;
    }

    if (semestre) {
      filters.semestre = semestre;
    }

    return this.turmaModel.find(filters).sort({ nome: 1 }).exec();
  }
  
  async findByTeacher(teacherId: string): Promise<Turma[]> {
    this.validateReference(teacherId, 'Professor');
    return this.turmaModel
      .find({ id_professor: teacherId })
      .sort({ nome: 1 })
      .exec();
  }

  async findByStudent(studentId: string): Promise<Turma[]> {
    this.validateReference(studentId, 'Aluno');
    return this.turmaModel
      .find({ listaAlunos: studentId })
      .sort({ nome: 1 })
      .exec();
  }

  async findOne(id: string): Promise<Turma> {
    this.validateClassId(id);
    const turma = await this.turmaModel.findById(id).exec();

    if (!turma) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return turma;
  }

  async update(
    id: string,
    updateClassDto: UpdateClassDto,
  ): Promise<Turma> {
    this.validateClassId(id);
    const turma = await this.turmaModel
      .findByIdAndUpdate(id, updateClassDto, {
        new: true,
        runValidators: true,
      })
      .exec();

    if (!turma) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return turma;
  }

  async addStudent(id: string, alunoId: string): Promise<Turma> {
    this.validateClassId(id);
    this.validateReference(alunoId, 'Aluno');
    const turma = await this.turmaModel
      .findByIdAndUpdate(
        id,
        { $addToSet: { listaAlunos: alunoId } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!turma) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return turma;
  }

  async removeStudent(id: string, alunoId: string): Promise<Turma> {
    this.validateClassId(id);
    this.validateReference(alunoId, 'Aluno');
    const turma = await this.turmaModel
      .findByIdAndUpdate(
        id,
        { $pull: { listaAlunos: alunoId } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!turma) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return turma;
  }

  async remove(id: string): Promise<Turma> {
    this.validateClassId(id);
    const turma = await this.turmaModel.findByIdAndDelete(id).exec();

    if (!turma) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return turma;
  }

  private validateClassId(id: string) {
    if (!isValidObjectId(id)) {
      throw new BadRequestException('ID da turma inválido.');
    }
  }

  private validateReference(value: string, label: string) {
    if (!value.trim()) {
      throw new BadRequestException(`${label} inválido.`);
    }
  }
}
