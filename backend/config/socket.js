// config/socket.js - Socket.io Configuration
import logger from '../utils/logger.js';

/**
 * Socket.io configuration options
 * @type {Object}
 */
const socketConfig = {
  // Set CORS options for socket.io
  cors: {
    origin: process.env.CLIENT_URL || '*',
    methods: ['GET', 'POST'],
    allowedHeaders: ['Authorization'],
    credentials: true
  },
  
  // Enable persistent connections
  transports: ['websocket', 'polling'],
  
  // Connection timeout in milliseconds
  connectTimeout: 10000,
  
  // Ping interval in milliseconds
  pingInterval: 10000,
  
  // Ping timeout in milliseconds
  pingTimeout: 5000,
  
  // Maximum number of retries for socket.io-client
  reconnectionAttempts: 5,
  
  // Initial delay before reconnection attempt in milliseconds
  reconnectionDelay: 1000,
  
  // Maximum delay between reconnection attempts
  reconnectionDelayMax: 5000,
  
  // Cookie configuration for socket.io
  cookie: {
    name: 'mathduel.sid',
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
};

export default socketConfig;