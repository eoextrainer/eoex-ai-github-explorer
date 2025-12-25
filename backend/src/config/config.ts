import fs from 'fs';
import os from 'os';
import path from 'path';

function getEnvOrBashrc(varName: string): string {
  if (process.env[varName]) return process.env[varName] as string;
  try {
    const bashrc = fs.readFileSync(path.join(os.homedir(), '.bashrc'), 'utf-8');
    const match = bashrc.match(new RegExp(`^export ${varName}=(.*)$`, 'm'));
    if (match) {
      // Remove quotes if present
      return match[1].replace(/^['"]|['"]$/g, '');
    }
  } catch {}
  return '';
}

export const config = {
  PORT: process.env.PORT || 3001,
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
  GITHUB_TOKEN: getEnvOrBashrc('GITHUB_TOKEN'),
  DB_URL: getEnvOrBashrc('DATABASE_URL'),
};
