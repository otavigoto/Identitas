import { Module } from '@nestjs/common';
import { RolesGuard } from '../../common/guards/roles.guard.js';

@Module({
  providers: [RolesGuard],
  exports: [RolesGuard],
})
export class AuthorizationModule {}
