import { requireJwtSecret } from './auth.module.js';

describe('requireJwtSecret', () => {
  it.each([undefined, '', '   ', 'curto'])(
    'recusa segredo ausente ou curto (%j)',
    (secret) => {
      expect(() => requireJwtSecret(secret)).toThrow(/JWT_SECRET/);
    },
  );

  it('não aceita mais o valor padrão antigo do código como fallback', () => {
    expect(() => requireJwtSecret(undefined)).toThrow();
  });

  it('aceita um segredo com 16 caracteres ou mais', () => {
    const secret = 'a'.repeat(32);
    expect(requireJwtSecret(secret)).toBe(secret);
  });
});
