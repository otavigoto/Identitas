import { Module } from '@nestjs/common';
//import { createObserveModule } from '@nestjs/observe';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { ClassesModule } from './classes/classes.module.js';


//export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MongooseModule.forRoot(process.env.MONGODB ?? ''),
    /*
    // Distributed tracing, auto-correlated logs, request/job metrics, error
    // telemetry, alarms, and more — out of the box. Sign up at https://observe.nestjs.com
    ObserveModule.forRoot({
      appKey: process.env.APP_KEY!,
      appSecret: process.env.APP_SECRET!,
      serviceId: 'backend',
    }),
    */
    ClassesModule,
  ],
})
export class AppModule {}
