import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClassesService } from './classes.service.js';
import { ClassesController } from './classes.controller.js';
import { Class, ClassSchema } from './entities/class.entity.js';
import { User, UserSchema } from '../users/entities/user.entity.js'; // Ajuste o caminho
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [
    AuthModule,
    MongooseModule.forFeature([
      { name: Class.name, schema: ClassSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [ClassesController],
  providers: [ClassesService],
})
export class ClassesModule {}
