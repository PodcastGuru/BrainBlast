// socket/index.js - Socket.io Setup
import { Server } from 'socket.io';
import socketConfig from '../config/socket.js';
import socketAuth from './middleware/socketAuth.js';
import logger from '../utils/logger.js';
import setupGameEvents from './events/gameEvents.js';
import setupNotificationEvents from './events/notificationEvents.js';
import setupChallengeEvents from './events/challengeEvents.js';

/**
 * Set up Socket.io server and event handlers
 * @param {http.Server} server - HTTP server instance
 * @returns {Socket.io} Socket.io server instance
 */
const setupSocket = (server) => {
  logger.info('Setting up Socket.io server');
  
  // Create Socket.io server
  const io = new Server(server, socketConfig);
  
  // Middleware for authentication
  io.use(socketAuth);
  
  // Connection event
  io.on('connection', (socket) => {
    logger.info(`Socket connected: ${socket.id}`);
    
    // Store user data in socket
    const userId = socket.user ? socket.user._id : null;
    
    // Join user's personal room for direct messages
    if (userId) {
      socket.join(`user:${userId}`);
      logger.debug(`User ${userId} joined personal room`);
    }
    
    // Set up event handlers
    setupGameEvents(io, socket);
    setupNotificationEvents(io, socket);
    setupChallengeEvents(io, socket);
    
    // Disconnect event
    socket.on('disconnect', () => {
      logger.info(`Socket disconnected: ${socket.id}`);
    });
  });
  
  return io;
};

export default setupSocket;