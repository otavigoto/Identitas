import { ForbiddenException } from '@nestjs/common';
import type { Request } from 'express';
import type { JwtPayload } from '../auth/auth.service.js';
import { Role } from '../common/enums/role.enum.js';
import { AssignNfcDto } from './dto/request/assing-nfc.dto.js';
import { UsersController } from './users.controller.js';
import { UsersService } from './users.service.js';

describe('UsersController NFC assignment', () => {
  const service = {
    assignNfcKey: vi.fn().mockResolvedValue({ id: 'user-id' }),
  };
  const controller = new UsersController(service as unknown as UsersService);
  const request = {
    user: { sub: 'user-id', role: Role.STUDENT, ra: 'RA001' },
  } as Request & { user: JwtPayload };
  const dto = { nfcUid: 'A1B2C3' } as AssignNfcDto;

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('allows a user to link NFC to their own account', async () => {
    await expect(
      controller.assignNfc('user-id', request, dto),
    ).resolves.toEqual({ id: 'user-id' });
    expect(service.assignNfcKey).toHaveBeenCalledWith('user-id', 'A1B2C3');
  });

  it('rejects linking NFC to another account', () => {
    expect(() => controller.assignNfc('other-user', request, dto)).toThrow(
      ForbiddenException,
    );
    expect(service.assignNfcKey).not.toHaveBeenCalled();
  });
});
