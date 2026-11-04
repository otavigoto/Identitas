import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { ClassesModule } from './classes/classes.module.js';
import { AuthorizationModule } from './modules/auth/authorization.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MongooseModule.forRoot(process.env.MONGODB ?? ''),
    ClassesModule,
    AuthorizationModule,
  ],
})
export class AppModule {}
