import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { AttendanceStatus } from '../dto/request/create-class.dto.js';

export type ClassDocument = Class & Document;

@Schema({ _id: false })
export class StudentAttendanceRecord {
  @Prop({ required: true })
  studentId: string;

  @Prop({ required: true })
  present: boolean;
}

@Schema({ _id: false })
export class AttendanceItem {
  @Prop({ required: true })
  date: Date;

  @Prop({ type: [StudentAttendanceRecord], required: true })
  students: StudentAttendanceRecord[];
}

export const AttendanceItemSchema = SchemaFactory.createForClass(AttendanceItem);

@Schema({ timestamps: true })
export class Class extends Document {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true })
  id_professor: string;

  @Prop({ type: [String], default: [] })
  enrolledStudents: string[];

  @Prop({ required: true })
  week: string;

  @Prop({ required: true })
  startTime: string;

  @Prop({ required: true })
  endTime: string;

  @Prop({
    required: true,
    enum: AttendanceStatus,
    default: AttendanceStatus.CLOSED,
  })
  attendanceStatus: AttendanceStatus;

  @Prop()
  attendanceTime?: Date;

  @Prop({ type: [AttendanceItemSchema], default: [] })
  attendanceList: AttendanceItem[];
}

export const ClassSchema = SchemaFactory.createForClass(Class);