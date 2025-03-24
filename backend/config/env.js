// config/env.js - Environment Variables Setup
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent in ES Module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from .env file
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// Set default values if not provided in .env
process.env.NODE_ENV = process.env.NODE_ENV || 'development';
process.env.PORT = process.env.PORT || 5000;
process.env.MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/math_duel';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';
process.env.JWT_EXPIRE = process.env.JWT_EXPIRE || '30d';
process.env.JWT_COOKIE_EXPIRE = process.env.JWT_COOKIE_EXPIRE || 30;
process.env.CLIENT_URL = process.env.CLIENT_URL || 'http://localhost:3000';