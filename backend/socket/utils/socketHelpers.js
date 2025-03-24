// socket/utils/socketHelpers.js - Socket Helper Functions
import logger from '../../utils/logger.js';

/**
 * Emit an event to a specific user via their personal room
 * @param {Object} io - Socket.io server instance
 * @param {string} userId - User ID
 * @param {string} event - Event name
 * @param {*} data - Event data
 */
export const emitToUser = (io, userId, event, data) => {
  if (!userId || !event) {
    logger.warn('Invalid parameters for emitToUser');
    return;
  }
  
  io.to(`user:${userId}`).emit(event, data);
  logger.debug(`Emitted ${event} to user ${userId}`);
};

/**
 * Emit an event to all players in a game
 * @param {Object} io - Socket.io server instance
 * @param {string} gameCode - Game code
 * @param {string} event - Event name
 * @param {*} data - Event data
 */
export const emitToGame = (io, gameCode, event, data) => {
  if (!gameCode || !event) {
    logger.warn('Invalid parameters for emitToGame');
    return;
  }
  
  io.to(`game:${gameCode}`).emit(event, data);
  logger.debug(`Emitted ${event} to game ${gameCode}`);
};

/**
 * Get the number of connected clients in a room
 * @param {Object} io - Socket.io server instance
 * @param {string} room - Room name
 * @returns {number} Count of clients in the room
 */
export const getClientsInRoom = async (io, room) => {
  if (!room) {
    logger.warn('Invalid room parameter for getClientsInRoom');
    return 0;
  }
  
  try {
    const sockets = await io.in(room).fetchSockets();
    return sockets.length;
  } catch (error) {
    logger.error(`Error getting clients in room ${room}: ${error.message}`);
    return 0;
  }
};

/**
 * Check if a user is connected to a specific room
 * @param {Object} io - Socket.io server instance
 * @param {string} userId - User ID
 * @param {string} room - Room name
 * @returns {boolean} Whether the user is in the room
 */
export const isUserInRoom = async (io, userId, room) => {
  if (!userId || !room) {
    logger.warn('Invalid parameters for isUserInRoom');
    return false;
  }
  
  try {
    const sockets = await io.in(`user:${userId}`).fetchSockets();
    
    for (const socket of sockets) {
      const rooms = socket.rooms;
      if (rooms.has(room)) {
        return true;
      }
    }
    
    return false;
  } catch (error) {
    logger.error(`Error checking if user ${userId} is in room ${room}: ${error.message}`);
    return false;
  }
};