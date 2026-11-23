import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { Roles } from '../common/decorators/roles.decorator.js';
import { Role } from '../common/enums/role.enum.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import type { JwtPayload } from '../auth/auth.service.js';
import { ClassesService } from './classes.service.js';
import { CreateClassDto } from './dto/request/create-class.dto.js';
import { ManageClassStudentDto } from './dto/request/manage-class-student.dto.js';
import { UpdateClassDto } from './dto/request/update-class.dto.js';
import { AttendanceStudentDto } from './dto/request/attendance-student.dto.js';
import { MarkAttendanceNfcDto } from './dto/request/mark-attendance-nfc.dto.js';
import { ScanProfessorNfcDto } from './dto/request/scan-professor-nfc.dto.js';

@Controller('classes')
export class ClassesController {
  constructor(private readonly classesService: ClassesService) {}

  // CRUD CLASSES -----------------------

  @Post()
  create(@Body() createClassDto: CreateClassDto) {
    return this.classesService.create(createClassDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.classesService.remove(id);
  }

  @Get()
  findAll(
    @Query('disciplina') disciplina?: string,
    @Query('semestre') semestre?: string,
  ) {
    return this.classesService.findAll(disciplina, semestre);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateClassDto: UpdateClassDto) {
    return this.classesService.update(id, updateClassDto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.classesService.findOne(id);
  }

  // FIM CRUD CLASSES -----------------------

  @Get('me/today')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.STUDENT, Role.PROFESSOR)
  getMyTodayClasses(
    @Req() req: Request & { user: JwtPayload },
    @Query('date') date?: string,
  ) {
    return this.classesService.getHomeData(req.user.sub, req.user.role, date);
  }

  @Get('me/weekly')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.STUDENT, Role.PROFESSOR)
  getMyWeeklyClasses(@Req() req: Request & { user: JwtPayload }) {
    return this.classesService.getWeeklyData(req.user.sub, req.user.role);
  }

  @Get('student/:studentId/today')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.STUDENT)
  findTodayClassesByStudent(
    @Param('studentId') studentId: string,
    @Req() req: Request & { user: JwtPayload },
    @Query('date') date?: string, // Opcional: permite testar passando ?date=2026-11-16
  ) {
    if (studentId !== req.user.sub) {
      throw new ForbiddenException(
        'Só é possível consultar suas próprias aulas.',
      );
    }
    return this.classesService.findTodayClassesByStudent(studentId, date);
  }

  @Get('teacher/:teacherId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  findByTeacher(
    @Param('teacherId') teacherId: string,
    @Req() req: Request & { user: JwtPayload },
  ) {
    if (teacherId !== req.user.sub) {
      throw new ForbiddenException(
        'Só é possível consultar suas próprias turmas.',
      );
    }
    return this.classesService.findByTeacher(teacherId);
  }

  @Get('student/:studentId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.STUDENT)
  findByStudent(
    @Param('studentId') studentId: string,
    @Req() req: Request & { user: JwtPayload },
  ) {
    if (studentId !== req.user.sub) {
      throw new ForbiddenException(
        'Só é possível consultar suas próprias aulas.',
      );
    }
    return this.classesService.findByStudent(studentId);
  }

  @Post(':id/students')
  @HttpCode(HttpStatus.OK)
  addStudent(
    @Param('id') id: string,
    @Body() manageClassStudentDto: ManageClassStudentDto,
  ) {
    return this.classesService.addStudent(
      id,
      manageClassStudentDto.enrolledStudents,
    );
  }

  @Delete(':id/students/:studentId')
  removeStudent(
    @Param('id') id: string,
    @Param('studentId') studentId: string,
  ) {
    return this.classesService.removeStudent(id, [studentId]);
  }

  // Funções de presença -----------------------

  @Get(':id/students')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  getAttendanceListToday(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
    @Query('date') date?: string,
  ) {
    return this.classesService.getAttendanceList(id, req.user.sub, date);
  }

  @Get(':id/students/all')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  getAllAttendanceList(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
  ) {
    return this.classesService.getAllAttendanceList(id, req.user.sub);
  }

  @Get(':id/attendance/summary')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  getAttendanceSummary(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
  ) {
    return this.classesService.getAllAttendanceList(id, req.user.sub);
  }

  @Patch(':id/attendance/open')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  openAttendance(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
  ) {
    return this.classesService.openAttendance(id, req.user.sub);
  }

  @Post(':id/students/attendance')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  @HttpCode(HttpStatus.OK)
  markAttendance(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
    @Body() attendanceStudentDto: AttendanceStudentDto,
  ) {
    return this.classesService.markAttendance(
      id,
      attendanceStudentDto,
      req.user.sub,
    );
  }

  @Post(':id/students/attendance/nfc')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PROFESSOR)
  @HttpCode(HttpStatus.OK)
  markAttendanceByNfc(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
    @Body() markAttendanceNfcDto: MarkAttendanceNfcDto,
  ) {
    return this.classesService.markAttendanceByNfc(
      id,
      markAttendanceNfcDto,
      req.user.sub,
    );
  }

  @Post(':id/attendance/scan-professor')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.STUDENT)
  @HttpCode(HttpStatus.OK)
  markAttendanceByProfessorNfc(
    @Param('id') id: string,
    @Req() req: Request & { user: JwtPayload },
    @Body() scanProfessorNfcDto: ScanProfessorNfcDto,
  ) {
    return this.classesService.scanProfessorNfc(
      id,
      req.user.sub,
      scanProfessorNfcDto.nfcUid,
    );
  }

  // FIM Funções de presença -----------------------
}
