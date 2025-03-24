// socket/events/challengeEvents.js

import logger from '../../utils/logger.js';
import Game from '../../models/Game.js';

/**
 * Set up challenge-related socket events
 * @param {Object} io - Socket.io server instance
 * @param {Object} socket - Socket.io socket
 */
const setupChallengeEvents = (io, socket) => {
  const userId = socket.user?._id;
  
  if (!userId) return; // Only authenticated users can handle challenges
  
  // Listen for users coming online to update availability
  socket.on('user:online', async () => {
    try {
      // Broadcast to others that this user is online
      socket.broadcast.emit('user:status', { 
        userId: userId.toString(), 
        status: 'online' 
      });
      
      // Update any pending challenges that might have expired
      await Game.updateMany(
        {
          $or: [
            { 'challengeInfo.challenger': userId },
            { 'challengeInfo.challenged': userId }
          ],
          'challengeInfo.status': 'pending',
          'challengeInfo.expiresAt': { $lt: new Date() }
        },
        {
          $set: { 'challengeInfo.status': 'expired' }
        }
      );
    } catch (error) {
      logger.error(`Error in user:online handler: ${error.message}`);
    }
  });
  
  // Handle direct messages between users for challenge communication
  socket.on('challenge:message', async ({ recipientId, message }) => {
    try {
      io.to(`user:${recipientId}`).emit('challenge:message', {
        senderId: userId.toString(),
        message
      });
    } catch (error) {
      logger.error(`Error in challenge:message handler: ${error.message}`);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });
};

export default setupChallengeEvents;