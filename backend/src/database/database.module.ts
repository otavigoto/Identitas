import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: (config: Record<string, unknown>) => {
        config.MONGODB_URI = config.MONGODB_URI ?? config.MONGODB;
        if (
          typeof config.MONGODB_URI !== 'string' ||
          !config.MONGODB_URI.trim()
        ) {
          throw new Error(
            'MONGODB_URI é obrigatória. Configure o arquivo backend/.env.',
          );
        }
        return config;
      },
    }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.getOrThrow<string>('MONGODB_URI'),
        serverSelectionTimeoutMS: 5000,
        retryAttempts: 1,
      }),
    }),
  ],
})
export class DatabaseModule {}
