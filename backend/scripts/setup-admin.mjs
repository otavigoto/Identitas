import { readFile, writeFile } from 'node:fs/promises';
import { randomBytes, scryptSync } from 'node:crypto';
import { createInterface } from 'node:readline/promises';
import { Writable } from 'node:stream';

let muted = false;
const output = new Writable({
  write(chunk, encoding, callback) {
    if (!muted) process.stdout.write(chunk, encoding);
    callback();
  },
});
const rl = createInterface({ input: process.stdin, output, terminal: true });
try {
  const login = (await rl.question('Login do administrador: ')).trim();
  process.stdout.write('Senha (mínimo 12 caracteres; entrada oculta): ');
  muted = true;
  const password = await rl.question('');
  muted = false;
  process.stdout.write('\nConfirme a senha: ');
  muted = true;
  const confirmation = await rl.question('');
  muted = false;
  process.stdout.write('\n');
  if (
    !login ||
    login.length > 150 ||
    password.length < 12 ||
    password.length > 256 ||
    password !== confirmation
  ) {
    throw new Error('Login ou senha inválidos, ou confirmação diferente.');
  }
  const file = new URL('../.env', import.meta.url);
  let content;
  try {
    content = await readFile(file, 'utf8');
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    content = 'MONGODB_URI=mongodb://127.0.0.1:27017/identitas\n';
  }
  const salt = randomBytes(16).toString('hex');
  const hash = `scrypt:${salt}:${scryptSync(password, salt, 64).toString('hex')}`;
  const values = {
    ADMIN_LOGIN: JSON.stringify(login),
    ADMIN_PASSWORD_HASH: hash,
    JWT_SECRET: randomBytes(48).toString('hex'),
  };
  for (const [key, value] of Object.entries(values)) {
    const pattern = new RegExp(`^${key}=.*$`, 'm');
    content = pattern.test(content)
      ? content.replace(pattern, () => `${key}=${value}`)
      : `${content.trimEnd()}\n${key}=${value}\n`;
  }
  await writeFile(file, content, { mode: 0o600 });
  process.stdout.write(
    'Administrador configurado no .env. Reinicie o backend. Tokens anteriores foram invalidados.\n',
  );
} catch (error) {
  muted = false;
  process.stderr.write(`\n${error.message}\n`);
  process.exitCode = 1;
} finally {
  muted = false;
  rl.close();
}
