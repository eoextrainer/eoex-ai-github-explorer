"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = void 0;
const fs_1 = __importDefault(require("fs"));
const os_1 = __importDefault(require("os"));
const path_1 = __importDefault(require("path"));
function getEnvOrBashrc(varName) {
    if (process.env[varName])
        return process.env[varName];
    try {
        const bashrc = fs_1.default.readFileSync(path_1.default.join(os_1.default.homedir(), '.bashrc'), 'utf-8');
        const match = bashrc.match(new RegExp(`^export ${varName}=(.*)$`, 'm'));
        if (match) {
            // Remove quotes if present
            return match[1].replace(/^['"]|['"]$/g, '');
        }
    }
    catch { }
    return '';
}
exports.config = {
    PORT: process.env.PORT || 3001,
    CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
    GITHUB_TOKEN: getEnvOrBashrc('GITHUB_TOKEN'),
    DB_URL: getEnvOrBashrc('DATABASE_URL'),
};
