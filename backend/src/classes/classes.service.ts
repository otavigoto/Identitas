import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { isValidObjectId, Model } from 'mongoose';
import { User, UserDocument } from '../users/entities/user.entity.js'; // Ajuste o caminho
import { AttendanceStudentDto } from './dto/request/attendance-student.dto.js';
import {
  AttendanceStatus,
  CreateClassDto,
} from './dto/request/create-class.dto.js';
import { MarkAttendanceNfcDto } from './dto/request/mark-attendance-nfc.dto.js';
import { UpdateClassDto } from './dto/request/update-class.dto.js';
import { Class, ClassDocument } from './entities/class.entity.js';

@Injectable()
export class ClassesService {
  constructor(
    @InjectModel(Class.name)
    private readonly classModel: Model<ClassDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
  ) {}

  async create(createClassDto: CreateClassDto): Promise<ClassDocument> {
    const {
      name,
      id_professor,
      enrolledStudents = [],
      week,
      startTime,
      endTime,
      attendanceStatus,
      attendanceTime,
      attendanceList = [],
    } = createClassDto;

    return this.classModel.create({
      name,
      id_professor,
      enrolledStudents,
      week,
      startTime,
      endTime,
      attendanceStatus,
      attendanceTime,
      attendanceList,
    });
  }

  async findAll(
    week?: string,
    attendanceStatus?: string,
  ): Promise<ClassDocument[]> {
    const filters: Record<string, string> = {};

    if (week) {
      filters.week = week;
    }

    if (attendanceStatus) {
      filters.attendanceStatus = attendanceStatus;
    }

    return this.classModel.find(filters).sort({ name: 1 }).exec();
  }

  async findByTeacher(teacherId: string): Promise<ClassDocument[]> {
    this.validateReference(teacherId, 'Professor');
    return this.classModel
      .find({ id_professor: teacherId })
      .sort({ name: 1 })
      .exec();
  }

  async findByStudent(studentId: string): Promise<ClassDocument[]> {
    this.validateReference(studentId, 'Aluno');
    return this.classModel
      .find({ enrolledStudents: studentId })
      .sort({ name: 1 })
      .exec();
  }

  async findOne(id: string): Promise<ClassDocument> {
    this.validateClassId(id);
    const foundClass = await this.classModel.findById(id).exec();

    if (!foundClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return foundClass;
  }

  async update(
    id: string,
    updateClassDto: UpdateClassDto,
  ): Promise<ClassDocument> {
    this.validateClassId(id);
    const updatedClass = await this.classModel
      .findByIdAndUpdate(id, updateClassDto, {
        new: true,
        runValidators: true,
      })
      .exec();

    if (!updatedClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return updatedClass;
  }

  async addStudent(id: string, studentIds: string[]): Promise<ClassDocument> {
    this.validateClassId(id);
    if (!studentIds || studentIds.length === 0) {
      throw new BadRequestException('A lista de alunos não pode estar vazia.');
    }
    studentIds.forEach((studentId) =>
      this.validateReference(studentId, 'Aluno'),
    );
    const updatedClass = await this.classModel
      .findByIdAndUpdate(
        id,
        { $addToSet: { enrolledStudents: { $each: studentIds } } },
        { new: true, runValidators: true },
      )
      .exec();
    if (!updatedClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return updatedClass;
  }

  async removeStudent(
    id: string,
    studentIds: string[],
  ): Promise<ClassDocument> {
    this.validateClassId(id);

    if (!studentIds || studentIds.length === 0) {
      throw new BadRequestException('A lista de alunos não pode estar vazia.');
    }

    studentIds.forEach((studentId) =>
      this.validateReference(studentId, 'Aluno'),
    );

    const updatedClass = await this.classModel
      .findByIdAndUpdate(
        id,
        { $pull: { enrolledStudents: { $in: studentIds } } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updatedClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return updatedClass;
  }

  async remove(id: string): Promise<ClassDocument> {
    this.validateClassId(id);
    const deletedClass = await this.classModel.findByIdAndDelete(id).exec();

    if (!deletedClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return deletedClass;
  }

  private validateClassId(id: string) {
    if (!isValidObjectId(id)) {
      throw new BadRequestException('ID da turma inválido.');
    }
  }

  private validateReference(value: string, label: string) {
    if (!value || !value.trim()) {
      throw new BadRequestException(`${label} inválido.`);
    }
  }

  async openAttendance(id: string): Promise<ClassDocument> {
    this.validateClassId(id);

    const updatedClass = await this.classModel
      .findByIdAndUpdate(
        id,
        {
          attendanceStatus: AttendanceStatus.OPEN,
          attendanceTime: new Date(),
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updatedClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return updatedClass;
  }

  async markAttendance(
    id: string,
    attendanceStudentDto: AttendanceStudentDto,
  ): Promise<ClassDocument> {
    this.validateClassId(id);

    const foundClass = await this.classModel.findById(id).exec();
    if (!foundClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    // 1. Verifica se a chamada está fechada
    if (foundClass.attendanceStatus === AttendanceStatus.CLOSED) {
      throw new BadRequestException(
        'A lista de presença desta turma está fechada.',
      );
    }

    // 2. Verifica se já passaram mais de 5 minutos desde a última abertura (data + hora)
    const FIVE_MINUTES_IN_MS = 5 * 60 * 1000;
    if (foundClass.attendanceTime) {
      const elapsedMs =
        Date.now() - new Date(foundClass.attendanceTime).getTime();

      if (elapsedMs > FIVE_MINUTES_IN_MS) {
        await this.classModel
          .findByIdAndUpdate(id, { attendanceStatus: AttendanceStatus.CLOSED })
          .exec();

        throw new BadRequestException(
          'O tempo limite de 5 minutos expirou. A lista de presença foi fechada.',
        );
      }
    }

    // 3. Valida se todos os alunos enviados estão matriculados na turma
    const enrolledSet = new Set(foundClass.enrolledStudents);
    const invalidStudents = attendanceStudentDto.presentStudentIds.filter(
      (studentId) => !enrolledSet.has(studentId),
    );

    if (invalidStudents.length > 0) {
      throw new BadRequestException(
        `Alunos não matriculados nesta turma: ${invalidStudents.join(', ')}`,
      );
    }

    // 4. Verifica se já existe um registro de chamada para a data de hoje
    const targetDate = attendanceStudentDto.date ?? new Date();
    const targetDayString = targetDate.toISOString().slice(0, 10); // Ex: "2026-11-16"

    const existingRecord = foundClass.attendanceList.find(
      (item) =>
        new Date(item.date).toISOString().slice(0, 10) === targetDayString,
    );

    // Cenário A: Já existe chamada hoje -> apenas marca present: true nos novos alunos
    if (existingRecord) {
      if (attendanceStudentDto.presentStudentIds.length === 0) {
        return foundClass;
      }

      const updatedClass = await this.classModel
        .findOneAndUpdate(
          { _id: id, 'attendanceList.date': existingRecord.date },
          {
            $set: {
              'attendanceList.$.students.$[elem].present': true,
            },
          },
          {
            arrayFilters: [
              {
                'elem.studentId': {
                  $in: attendanceStudentDto.presentStudentIds,
                },
              },
            ],
            new: true,
            runValidators: true,
          },
        )
        .exec();

      return updatedClass!;
    }

    // Cenário B: Primeira leitura do dia -> cria o registro com todos os matriculados
    const presentSet = new Set(attendanceStudentDto.presentStudentIds);
    const studentsAttendance = foundClass.enrolledStudents.map((studentId) => ({
      studentId,
      present: presentSet.has(studentId),
    }));

    const newAttendanceRecord = {
      date: targetDate,
      students: studentsAttendance,
    };

    const updatedClass = await this.classModel
      .findByIdAndUpdate(
        id,
        { $push: { attendanceList: newAttendanceRecord } },
        { new: true, runValidators: true },
      )
      .exec();

    return updatedClass!;
  }

  // No constructor do ClassesService:

  // Novo método para leitura NFC:
  async markAttendanceByNfc(
    classId: string,
    dto: MarkAttendanceNfcDto,
  ): Promise<ClassDocument> {
    this.validateClassId(classId);

    const normalizedUids = dto.nfcUids.map((uid) => uid.trim().toUpperCase());
    let studentIds: string[] = [];

    if (normalizedUids.length > 0) {
      const students = await this.userModel
        .find({ nfcUid: { $in: normalizedUids } })
        .exec();

      const foundUidsSet = new Set(students.map((s) => s.nfcUid));
      const unknownUids = normalizedUids.filter(
        (uid) => !foundUidsSet.has(uid),
      );

      if (unknownUids.length > 0) {
        throw new NotFoundException(
          `Cartões NFC não encontrados ou não vinculados: ${unknownUids.join(', ')}`,
        );
      }

      studentIds = students.map((student) => student._id.toString());
    }

    // Executa exatamente a mesma lógica e retorna exatamente o mesmo ClassDocument
    return this.markAttendance(classId, {
      presentStudentIds: studentIds,
      date: dto.date,
    });
  }
}
