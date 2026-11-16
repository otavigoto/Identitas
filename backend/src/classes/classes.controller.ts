import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ClassesService } from './classes.service.js';
import { CreateClassDto } from './dto/request/create-class.dto.js';
import { ManageClassStudentDto } from './dto/request/manage-class-student.dto.js';
import { UpdateClassDto } from './dto/request/update-class.dto.js';
import { AttendanceStudentDto } from './dto/request/attendance-student.dto.js';
import { MarkAttendanceNfcDto } from './dto/request/mark-attendance-nfc.dto.js';

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

  @Get('student/:studentId/today')
  findTodayClassesByStudent(
    @Param('studentId') studentId: string,
    @Query('date') date?: string, // Opcional: permite testar passando ?date=2026-11-16
  ) {
    return this.classesService.findTodayClassesByStudent(studentId, date);
  }

  @Get('teacher/:teacherId')
  findByTeacher(@Param('teacherId') teacherId: string) {
    return this.classesService.findByTeacher(teacherId);
  }

  @Get('student/:studentId')
  findByStudent(@Param('studentId') studentId: string) {
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

  @Patch(':id/attendance/open')
  openAttendance(@Param('id') id: string) {
    return this.classesService.openAttendance(id);
  }

  @Post(':id/students/attendance')
  @HttpCode(HttpStatus.OK)
  markAttendance(
    @Param('id') id: string,
    @Body() attendanceStudentDto: AttendanceStudentDto,
  ) {
    return this.classesService.markAttendance(id, attendanceStudentDto);
  }

  @Post(':id/students/attendance/nfc')
  @HttpCode(HttpStatus.OK)
  markAttendanceByNfc(
    @Param('id') id: string,
    @Body() markAttendanceNfcDto: MarkAttendanceNfcDto,
  ) {
    return this.classesService.markAttendanceByNfc(id, markAttendanceNfcDto);
  }

  //TODO Conseguir pegar a data e hora do servidor e não do cliente, para evitar que o aluno consiga burlar a presença. (ia q gerou esse comment)

  //TODO LER O UID NFC DO PROFESSOR E CONSEGUIR PRESENÇA DESSA FORMA

  // FIM Funções de presença -----------------------
}
