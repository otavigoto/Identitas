import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { isValidObjectId, Model } from 'mongoose';
import { Role } from '../common/enums/role.enum.js';
import { User, UserDocument } from '../users/entities/user.entity.js';
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
      qtdAulas,
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
      qtdAulas,
      startTime,
      endTime,
      attendanceStatus,
      attendanceTime,
      attendanceList,
    });
  }

  async remove(id: string, teacherId: string): Promise<ClassDocument> {
    await this.findOwned(id, teacherId);
    const deletedClass = await this.classModel.findByIdAndDelete(id).exec();

    if (!deletedClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return deletedClass;
  }

  async update(
    id: string,
    updateClassDto: UpdateClassDto,
    teacherId: string,
  ): Promise<ClassDocument> {
    await this.findOwned(id, teacherId);
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

  /** Lista só as turmas do professor informado (nunca as de outros). */
  async findAll(
    teacherId: string,
    week?: string,
    attendanceStatus?: string,
  ): Promise<ClassDocument[]> {
    this.validateReference(teacherId, 'Professor');
    const filters: Record<string, string> = { id_professor: teacherId };

    if (week) {
      filters.week = week;
    }

    if (attendanceStatus) {
      filters.attendanceStatus = attendanceStatus;
    }

    return this.classModel.find(filters).sort({ name: 1 }).exec();
  }

  async findOne(id: string): Promise<ClassDocument> {
    this.validateClassId(id);
    const foundClass = await this.classModel.findById(id).exec();

    if (!foundClass) {
      throw new NotFoundException('Turma não encontrada.');
    }

    return foundClass;
  }

  /** Busca a turma só se ela for do professor; senão, 404 como se não existisse. */
  async findOwned(id: string, teacherId: string): Promise<ClassDocument> {
    const foundClass = await this.findOne(id);
    this.assertClassTeacher(foundClass, teacherId);
    return foundClass;
  }

  async getHomeData(userId: string, role: Role, customDate?: string) {
    this.validateReference(userId, 'Usuário');
    const targetDate = this.parseDate(customDate);
    const user = await this.userModel
      .findById(userId)
      .select('_id name ra role')
      .exec();
    if (!user) {
      throw new NotFoundException('Usuário não encontrado.');
    }

    const classes = await this.classModel
      .find({
        ...(role === Role.STUDENT
          ? { enrolledStudents: userId }
          : { id_professor: userId }),
        week: { $regex: new RegExp(`^${this.getDayPrefix(targetDate)}`, 'i') },
      })
      .sort({ startTime: 1 })
      .exec();

    const dayKey = this.getDateKey(targetDate);
    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        ra: user.ra,
        role: user.role,
      },
      classes: classes.map((cls) => {
        const classData = this.getScheduleData(cls);
        if (role !== Role.STUDENT) {
          return classData;
        }

        const record = cls.attendanceList.find(
          (item) => this.getDateKey(item.date) === dayKey,
        );
        const studentRecord = record?.students.find(
          (item) => item.studentId.toString() === userId,
        );
        return {
          ...classData,
          attendanceRecorded: Boolean(record),
          present: studentRecord?.present ?? false,
        };
      }),
    };
  }

  async getWeeklyData(userId: string, role: Role) {
    this.validateReference(userId, 'Usuário');
    const user = await this.userModel
      .findById(userId)
      .select('_id name ra role')
      .exec();
    if (!user) {
      throw new NotFoundException('Usuário não encontrado.');
    }

    const classes = await this.classModel
      .find(
        role === Role.STUDENT
          ? { enrolledStudents: userId }
          : { id_professor: userId },
      )
      .sort({ week: 1, startTime: 1 })
      .exec();

    let totalLessons = 0;
    let presentLessons = 0;
    const classData = classes.map((cls) => {
      const schedule = this.getScheduleData(cls);
      if (role !== Role.STUDENT) {
        return schedule;
      }

      const history = cls.attendanceList
        .map((record) => ({
          date: record.date,
          present:
            record.students.find((item) => item.studentId.toString() === userId)
              ?.present ?? false,
        }))
        .sort(
          (left, right) =>
            new Date(left.date).getTime() - new Date(right.date).getTime(),
        );
      const present = history.filter((record) => record.present).length;
      const lessons = history.length;
      totalLessons += lessons;
      presentLessons += present;

      return {
        ...schedule,
        attendance: {
          lessons,
          present,
          absent: lessons - present,
          percentage: this.getPercentage(present, lessons),
          history,
        },
      };
    });

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        ra: user.ra,
        role: user.role,
      },
      classes: classData,
      ...(role === Role.STUDENT
        ? {
            overallAttendance: {
              lessons: totalLessons,
              present: presentLessons,
              absent: totalLessons - presentLessons,
              percentage: this.getPercentage(presentLessons, totalLessons),
            },
          }
        : {}),
    };
  }

  async getAttendanceList(id: string, teacherId: string, customDate?: string) {
    const foundClass = await this.findOne(id);
    this.assertClassTeacher(foundClass, teacherId);
    const targetDate = this.parseDate(customDate);
    const dayKey = this.getDateKey(targetDate);
    const record = foundClass.attendanceList.find(
      (item) => this.getDateKey(item.date) === dayKey,
    );
    const { students, missingStudentIds } =
      await this.getClassStudents(foundClass);
    const presentIds = new Set(
      record?.students
        .filter((item) => item.present)
        .map((item) => item.studentId.toString()) ?? [],
    );
    const studentList = students.map((student) => ({
      id: student._id.toString(),
      name: student.name,
      ra: student.ra,
      nfcUid: student.nfcUid ?? null,
      present: presentIds.has(student._id.toString()),
    }));
    const present = studentList.filter((student) => student.present).length;

    return {
      class: this.getScheduleData(foundClass),
      date: targetDate,
      attendanceRecorded: Boolean(record),
      totalStudents: studentList.length,
      present,
      absent: studentList.length - present,
      students: studentList,
      missingStudents: this.toMissingStudents(missingStudentIds),
    };
  }

  async getAllAttendanceList(id: string, teacherId: string) {
    const foundClass = await this.findOne(id);
    this.assertClassTeacher(foundClass, teacherId);
    const { students, missingStudentIds } =
      await this.getClassStudents(foundClass);
    const roster = students.map((student) => {
      const history = foundClass.attendanceList
        .map((record) => ({
          date: record.date,
          present:
            record.students.find(
              (item) => item.studentId.toString() === student._id.toString(),
            )?.present ?? false,
        }))
        .sort(
          (left, right) =>
            new Date(left.date).getTime() - new Date(right.date).getTime(),
        );
      const present = history.filter((record) => record.present).length;

      return {
        id: student._id.toString(),
        name: student.name,
        ra: student.ra,
        nfcUid: student.nfcUid ?? null,
        attendance: {
          lessons: history.length,
          present,
          absent: history.length - present,
          percentage: this.getPercentage(present, history.length),
          history,
        },
      };
    });
    const totalAttendance = foundClass.attendanceList.length * roster.length;
    const presentAttendance = roster.reduce(
      (total, student) => total + student.attendance.present,
      0,
    );

    return {
      class: this.getScheduleData(foundClass),
      attendance: {
        lessons: foundClass.attendanceList.length,
        studentRecords: totalAttendance,
        present: presentAttendance,
        absent: totalAttendance - presentAttendance,
        percentage: this.getPercentage(presentAttendance, totalAttendance),
      },
      students: roster,
      missingStudents: this.toMissingStudents(missingStudentIds),
    };
  }

  async scanProfessorNfc(classId: string, studentId: string, nfcUid: string) {
    this.validateReference(studentId, 'Aluno');
    const foundClass = await this.findOne(classId);
    const student = await this.userModel
      .findById(studentId)
      .select('_id')
      .exec();
    if (!student) {
      throw new NotFoundException('Aluno não encontrado.');
    }
    if (!foundClass.enrolledStudents.includes(studentId)) {
      throw new BadRequestException('Aluno não matriculado nesta turma.');
    }

    const professor = await this.userModel
      .findById(foundClass.id_professor)
      .select('nfcUid')
      .exec();
    if (
      !professor?.nfcUid ||
      professor.nfcUid.trim().toUpperCase() !== nfcUid.trim().toUpperCase()
    ) {
      throw new BadRequestException(
        'O NFC informado não pertence ao professor da turma.',
      );
    }

    return this.markAttendance(
      classId,
      {
        presentStudentIds: [studentId],
      },
      foundClass.id_professor,
    );
  }

  async findTodayClassesByStudent(studentId: string, customDate?: string) {
    this.validateReference(studentId, 'Aluno');
    const targetDate = this.parseDate(customDate);

    const classes = await this.classModel
      .find({
        enrolledStudents: studentId,
        week: { $regex: new RegExp(`^${this.getDayPrefix(targetDate)}`, 'i') },
      })
      .sort({ startTime: 1 })
      .exec();

    const targetDayString = this.getDateKey(targetDate);

    return classes.map((cls) => {
      const todayAttendance = cls.attendanceList.find(
        (item) => this.getDateKey(item.date) === targetDayString,
      );

      const studentRecord = todayAttendance?.students.find(
        (student) => student.studentId.toString() === studentId,
      );

      return {
        id: cls._id,
        name: cls.name,
        id_professor: cls.id_professor,
        week: cls.week,
        startTime: cls.startTime,
        endTime: cls.endTime,
        attendanceStatus: cls.attendanceStatus,
        attendanceRecorded: Boolean(todayAttendance),
        present: studentRecord?.present ?? false,
      };
    });
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

  async addStudent(
    id: string,
    studentIds: string[],
    teacherId: string,
  ): Promise<ClassDocument> {
    await this.findOwned(id, teacherId);
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
    teacherId: string,
  ): Promise<ClassDocument> {
    await this.findOwned(id, teacherId);

    if (!studentIds || studentIds.length === 0) {
      throw new BadRequestException('A lista de alunos não pode estar vazia.');
    }

    // Sem validar o formato do ID de propósito: matrículas antigas com ID
    // malformado precisam poder ser removidas da turma.
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

  private validateClassId(id: string) {
    if (!isValidObjectId(id)) {
      throw new BadRequestException('ID da turma inválido.');
    }
  }

  private validateReference(value: string, label: string) {
    if (!value || !isValidObjectId(value)) {
      throw new BadRequestException(`${label} inválido.`);
    }
  }

  private parseDate(customDate?: string): Date {
    const targetDate = customDate ? new Date(customDate) : new Date();
    if (Number.isNaN(targetDate.getTime())) {
      throw new BadRequestException('Data inválida.');
    }
    return targetDate;
  }

  private getDateKey(date: Date | string): string {
    const parsedDate = new Date(date);
    if (Number.isNaN(parsedDate.getTime())) {
      throw new BadRequestException('Data de presença inválida.');
    }
    return parsedDate.toISOString().slice(0, 10);
  }

  private getDayPrefix(date: Date): string {
    const daysOfWeek = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];
    return daysOfWeek[date.getDay()];
  }

  private getScheduleData(cls: ClassDocument) {
    return {
      id: cls._id.toString(),
      name: cls.name,
      id_professor: cls.id_professor,
      week: cls.week,
      qtdAulas: cls.qtdAulas,
      startTime: cls.startTime,
      endTime: cls.endTime,
    };
  }

  private getPercentage(present: number, lessons: number): number {
    return lessons === 0 ? 0 : Math.round((present / lessons) * 10000) / 100;
  }

  private async getClassStudents(foundClass: ClassDocument) {
    // IDs malformados (que não são ObjectId) também contam como "não
    // encontrado" e não vão para a consulta, que falharia com CastError.
    const validIds = foundClass.enrolledStudents.filter((studentId) =>
      isValidObjectId(studentId),
    );
    const students = await this.userModel
      .find({ _id: { $in: validIds } })
      .select('_id name ra nfcUid')
      .sort({ name: 1 })
      .exec();
    // Matriculados que não existem mais como usuário não derrubam a consulta:
    // voltam em `missingStudentIds` para o cliente avisar e permitir remover.
    const foundIds = new Set(students.map((student) => student._id.toString()));
    const missingStudentIds = foundClass.enrolledStudents.filter(
      (studentId) => !foundIds.has(studentId),
    );
    return { students, missingStudentIds };
  }

  private toMissingStudents(missingStudentIds: string[]) {
    return missingStudentIds.map((id) => ({
      id,
      message: 'Aluno não encontrado.',
    }));
  }

  private assertClassTeacher(foundClass: ClassDocument, teacherId: string) {
    this.validateReference(teacherId, 'Professor');
    if (foundClass.id_professor !== teacherId) {
      throw new NotFoundException('Turma não encontrada.');
    }
  }

  async openAttendance(id: string, teacherId: string): Promise<ClassDocument> {
    const foundClass = await this.findOne(id);
    this.assertClassTeacher(foundClass, teacherId);
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

  async closeAttendance(id: string, teacherId: string): Promise<ClassDocument> {
    const foundClass = await this.findOne(id);
    this.assertClassTeacher(foundClass, teacherId);
    const updatedClass = await this.classModel
      .findByIdAndUpdate(
        id,
        { attendanceStatus: AttendanceStatus.CLOSED },
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
    teacherId: string,
  ): Promise<ClassDocument> {
    this.validateClassId(id);

    const foundClass = await this.classModel.findById(id).exec();
    if (!foundClass) {
      throw new NotFoundException('Turma não encontrada.');
    }
    this.assertClassTeacher(foundClass, teacherId);

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

    const fullAttendance = attendanceStudentDto.students;
    const presentStudentIds =
      fullAttendance
        ?.filter((student) => student.present)
        .map((student) => student.studentId) ??
      attendanceStudentDto.presentStudentIds;
    if (!fullAttendance && !presentStudentIds) {
      throw new BadRequestException(
        'Informe a lista completa de alunos ou os IDs dos presentes.',
      );
    }

    // IDs de alunos são sempre ObjectIds; RA e NFC não substituem o ID interno.
    const enrolledSet = new Set(foundClass.enrolledStudents.map(String));
    const submittedIds = fullAttendance
      ? fullAttendance.map((student) => student.studentId)
      : (presentStudentIds ?? []);
    submittedIds.forEach((studentId) =>
      this.validateReference(studentId, 'Aluno'),
    );
    const invalidStudents = submittedIds.filter(
      (studentId) => !enrolledSet.has(studentId),
    );

    if (invalidStudents.length > 0) {
      throw new BadRequestException(
        `Alunos não matriculados nesta turma: ${invalidStudents.join(', ')}`,
      );
    }
    if (fullAttendance) {
      const submittedSet = new Set(submittedIds);
      if (
        submittedSet.size !== submittedIds.length ||
        submittedSet.size !== enrolledSet.size ||
        [...enrolledSet].some((studentId) => !submittedSet.has(studentId))
      ) {
        throw new BadRequestException(
          'A lista deve conter cada aluno matriculado exatamente uma vez.',
        );
      }
    }

    // 4. Verifica se já existe um registro de chamada para a data de hoje
    const targetDate = attendanceStudentDto.date ?? new Date();
    const targetDayString = this.getDateKey(targetDate);

    const existingRecord = foundClass.attendanceList.find(
      (item) => this.getDateKey(item.date) === targetDayString,
    );
    const submittedAttendance = fullAttendance
      ? fullAttendance.map(({ studentId, present }) => ({
          studentId,
          present,
        }))
      : undefined;

    // Uma lista completa substitui o estado daquele dia; leituras NFC continuam cumulativas.
    if (existingRecord) {
      if (submittedAttendance) {
        return (
          (await this.classModel
            .findOneAndUpdate(
              { _id: id, 'attendanceList.date': existingRecord.date },
              { $set: { 'attendanceList.$.students': submittedAttendance } },
              { new: true, runValidators: true },
            )
            .exec()) ?? foundClass
        );
      }
      if (presentStudentIds!.length === 0) {
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
                  $in: presentStudentIds,
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
    const presentSet = new Set(presentStudentIds);
    const studentsAttendance =
      submittedAttendance ??
      foundClass.enrolledStudents.map((studentId) => ({
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

  async markAttendanceByNfc(
    classId: string,
    dto: MarkAttendanceNfcDto,
    teacherId: string,
  ): Promise<ClassDocument> {
    this.validateClassId(classId);

    const normalizedUids = dto.nfcUids.map((uid) => uid.trim().toUpperCase());
    let studentIds: string[] = [];

    if (normalizedUids.length > 0) {
      const nfcUidPatterns = normalizedUids.map(
        (uid) => new RegExp(`^${this.escapeRegExp(uid)}$`, 'i'),
      );
      const students = await this.userModel
        .find({ nfcUid: { $in: nfcUidPatterns } })
        .exec();

      const foundUidsSet = new Set(
        students.map((student) => student.nfcUid?.trim().toUpperCase()),
      );
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
    return this.markAttendance(
      classId,
      {
        presentStudentIds: studentIds,
        date: dto.date,
      },
      teacherId,
    );
  }

  private escapeRegExp(value: string): string {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}
