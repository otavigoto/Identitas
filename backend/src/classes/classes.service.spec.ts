import { BadRequestException, NotFoundException } from '@nestjs/common';
import type { Model } from 'mongoose';
import { Role } from '../common/enums/role.enum.js';
import { UserDocument } from '../users/entities/user.entity.js';
import { ClassDocument } from './entities/class.entity.js';
import { ClassesService } from './classes.service.js';
import { AttendanceStatus } from './dto/request/create-class.dto.js';

const classId = '507f1f77bcf86cd799439011';
const teacherId = '507f1f77bcf86cd799439012';
const firstStudentId = '507f1f77bcf86cd799439013';
const secondStudentId = '507f1f77bcf86cd799439014';

function createService(
  classModel: Record<string, ReturnType<typeof vi.fn>>,
  userModel: Record<string, ReturnType<typeof vi.fn>>,
) {
  return new ClassesService(
    classModel as unknown as Model<ClassDocument>,
    userModel as unknown as Model<UserDocument>,
  );
}

describe('ClassesService attendance APIs', () => {
  it('calculates per-class and overall attendance for the student weekly view', async () => {
    const cls = {
      _id: { toString: () => classId },
      name: 'Banco de Dados',
      id_professor: teacherId,
      enrolledStudents: [firstStudentId],
      week: 'Segunda-feira',
      qtdAulas: 14,
      startTime: '08:00',
      endTime: '10:00',
      attendanceList: [
        {
          date: new Date('2026-11-16T12:00:00.000Z'),
          students: [{ studentId: firstStudentId, present: true }],
        },
        {
          date: new Date('2026-11-23T12:00:00.000Z'),
          students: [{ studentId: firstStudentId, present: false }],
        },
      ],
    } as unknown as ClassDocument;
    const classModel = {
      find: vi.fn(() => ({
        sort: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([cls]),
      })),
    };
    const userModel = {
      findById: vi.fn(() => ({
        select: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue({
          _id: { toString: () => firstStudentId },
          name: 'Ana',
          ra: 'RA001',
          role: Role.STUDENT,
        }),
      })),
    };
    const service = createService(classModel, userModel);

    await expect(
      service.getWeeklyData(firstStudentId, Role.STUDENT),
    ).resolves.toMatchObject({
      overallAttendance: {
        lessons: 2,
        present: 1,
        absent: 1,
        percentage: 50,
      },
      classes: [
        {
          id: classId,
          name: 'Banco de Dados',
          attendance: {
            lessons: 2,
            present: 1,
            absent: 1,
            percentage: 50,
          },
        },
      ],
    });
  });

  it('returns student identifiers, NFC and today attendance status in the roster', async () => {
    const date = new Date();
    const cls = {
      _id: { toString: () => classId },
      name: 'Banco de Dados',
      id_professor: teacherId,
      enrolledStudents: [firstStudentId, secondStudentId],
      week: 'Segunda-feira',
      startTime: '08:00',
      endTime: '10:00',
      attendanceStatus: AttendanceStatus.OPEN,
      attendanceList: [
        {
          date,
          students: [
            { studentId: firstStudentId, present: true },
            { studentId: secondStudentId, present: false },
          ],
        },
      ],
    } as unknown as ClassDocument;
    const students = [
      {
        _id: { toString: () => firstStudentId },
        name: 'Ana',
        ra: 'RA001',
        nfcUid: 'AA01',
      },
      {
        _id: { toString: () => secondStudentId },
        name: 'Bia',
        ra: 'RA002',
        nfcUid: 'BB02',
      },
    ];
    const classModel = {
      findById: vi.fn(() => ({ exec: vi.fn().mockResolvedValue(cls) })),
    };
    const userModel = {
      find: vi.fn(() => ({
        select: vi.fn().mockReturnThis(),
        sort: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue(students),
      })),
    };
    const service = createService(classModel, userModel);

    await expect(
      service.getAttendanceList(classId, teacherId),
    ).resolves.toMatchObject({
      totalStudents: 2,
      present: 1,
      absent: 1,
      students: [
        {
          id: firstStudentId,
          name: 'Ana',
          ra: 'RA001',
          nfcUid: 'AA01',
          present: true,
        },
        {
          id: secondStudentId,
          name: 'Bia',
          ra: 'RA002',
          nfcUid: 'BB02',
          present: false,
        },
      ],
    });
  });

  it('lists enrolled students that no longer exist instead of failing the roster', async () => {
    const cls = {
      _id: { toString: () => classId },
      name: 'Banco de Dados',
      id_professor: teacherId,
      enrolledStudents: [firstStudentId, secondStudentId],
      week: 'Segunda-feira',
      startTime: '08:00',
      endTime: '10:00',
      attendanceStatus: AttendanceStatus.CLOSED,
      attendanceList: [],
    } as unknown as ClassDocument;
    const classModel = {
      findById: vi.fn(() => ({ exec: vi.fn().mockResolvedValue(cls) })),
    };
    const userModel = {
      find: vi.fn(() => ({
        select: vi.fn().mockReturnThis(),
        sort: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          {
            _id: { toString: () => firstStudentId },
            name: 'Ana',
            ra: 'RA001',
            nfcUid: 'AA01',
          },
        ]),
      })),
    };
    const service = createService(classModel, userModel);

    await expect(
      service.getAttendanceList(classId, teacherId),
    ).resolves.toMatchObject({
      totalStudents: 1,
      students: [{ id: firstStudentId, name: 'Ana' }],
      missingStudents: [
        { id: secondStudentId, message: 'Aluno não encontrado.' },
      ],
    });
  });

  it('treats malformed enrolled IDs as missing students and still lists the others', async () => {
    const malformedId = '507f1f77bcf86cd79943901';
    const cls = {
      _id: { toString: () => classId },
      name: 'Banco de Dados',
      id_professor: teacherId,
      enrolledStudents: [firstStudentId, malformedId],
      week: 'Segunda-feira',
      startTime: '08:00',
      endTime: '10:00',
      attendanceStatus: AttendanceStatus.CLOSED,
      attendanceList: [],
    } as unknown as ClassDocument;
    const classModel = {
      findById: vi.fn(() => ({ exec: vi.fn().mockResolvedValue(cls) })),
    };
    const find = vi.fn(() => ({
      select: vi.fn().mockReturnThis(),
      sort: vi.fn().mockReturnThis(),
      exec: vi.fn().mockResolvedValue([
        {
          _id: { toString: () => firstStudentId },
          name: 'Ana',
          ra: 'RA001',
          nfcUid: 'AA01',
        },
      ]),
    }));
    const service = createService(classModel, { find });

    await expect(
      service.getAttendanceList(classId, teacherId),
    ).resolves.toMatchObject({
      students: [{ id: firstStudentId, name: 'Ana' }],
      missingStudents: [{ id: malformedId, message: 'Aluno não encontrado.' }],
    });
    expect(find).toHaveBeenCalledWith({ _id: { $in: [firstStudentId] } });
  });

  it('removes a student even when the stored ID is malformed', async () => {
    const malformedId = '507f1f77bcf86cd79943901';
    const exec = vi.fn().mockResolvedValue({ _id: classId });
    const classModel = {
      findByIdAndUpdate: vi.fn(() => ({ exec })),
    };
    const service = createService(classModel, {});

    await expect(
      service.removeStudent(classId, [malformedId]),
    ).resolves.toBeDefined();
    expect(classModel.findByIdAndUpdate).toHaveBeenCalledWith(
      classId,
      { $pull: { enrolledStudents: { $in: [malformedId] } } },
      expect.anything(),
    );
  });

  it('requires the full attendance submission to include every enrolled student', async () => {
    const cls = {
      _id: classId,
      id_professor: teacherId,
      enrolledStudents: [firstStudentId, secondStudentId],
      attendanceStatus: AttendanceStatus.OPEN,
      attendanceTime: new Date(),
      attendanceList: [],
    } as unknown as ClassDocument;
    const classModel = {
      findById: vi.fn(() => ({ exec: vi.fn().mockResolvedValue(cls) })),
      findByIdAndUpdate: vi.fn(),
    };
    const service = createService(classModel, {});

    await expect(
      service.markAttendance(
        classId,
        { students: [{ studentId: firstStudentId, present: true }] },
        teacherId,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(classModel.findByIdAndUpdate).not.toHaveBeenCalled();
  });

  it('replaces attendance for the day with the complete student status list', async () => {
    const date = new Date();
    const cls = {
      _id: classId,
      id_professor: teacherId,
      enrolledStudents: [firstStudentId, secondStudentId],
      attendanceStatus: AttendanceStatus.OPEN,
      attendanceTime: new Date(),
      attendanceList: [{ date, students: [] }],
    } as unknown as ClassDocument;
    const updatedClass = cls;
    const classModel = {
      findById: vi.fn(() => ({ exec: vi.fn().mockResolvedValue(cls) })),
      findOneAndUpdate: vi.fn(() => ({
        exec: vi.fn().mockResolvedValue(updatedClass),
      })),
    };
    const service = createService(classModel, {});

    await expect(
      service.markAttendance(
        classId,
        {
          students: [
            { studentId: firstStudentId, present: true },
            { studentId: secondStudentId, present: false },
          ],
        },
        teacherId,
      ),
    ).resolves.toBe(updatedClass);
    expect(classModel.findOneAndUpdate).toHaveBeenCalledWith(
      { _id: classId, 'attendanceList.date': date },
      {
        $set: {
          'attendanceList.$.students': [
            { studentId: firstStudentId, present: true },
            { studentId: secondStudentId, present: false },
          ],
        },
      },
      { new: true, runValidators: true },
    );
  });

  it('closes attendance only for the class teacher', async () => {
    const cls = {
      _id: classId,
      id_professor: teacherId,
      attendanceStatus: AttendanceStatus.OPEN,
    } as unknown as ClassDocument;
    const updatedClass = {
      _id: classId,
      id_professor: teacherId,
      attendanceStatus: AttendanceStatus.CLOSED,
    } as unknown as ClassDocument;
    const update = vi.fn(() => ({
      exec: vi.fn().mockResolvedValue(updatedClass),
    }));
    const classModel = {
      findById: vi.fn(() => ({ exec: vi.fn().mockResolvedValue(cls) })),
      findByIdAndUpdate: update,
    };
    const service = createService(classModel, {});

    await expect(
      service.closeAttendance(classId, teacherId),
    ).resolves.toMatchObject({ attendanceStatus: AttendanceStatus.CLOSED });
    expect(update).toHaveBeenCalledWith(
      classId,
      { attendanceStatus: AttendanceStatus.CLOSED },
      { new: true, runValidators: true },
    );

    await expect(
      service.closeAttendance(classId, firstStudentId),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(update).toHaveBeenCalledTimes(1);
  });
});
