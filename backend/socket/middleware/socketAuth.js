// socket/middleware/socketAuth.js - Socket Authentication Middleware
import jwt from 'jsonwebtoken';
import User from '../../models/User.js';
import logger from '../../utils/logger.js';

/**
 * Socket.io authentication middleware
 * Verifies JWT token if provided and attaches user to socket
 * @param {Object} socket - Socket.io socket
 * @param {Function} next - Next function
 */
const socketAuth = async (socket, next) => {
  try {
    // Get token from handshake auth or query
    const token = 
      socket.handshake.auth?.token || 
      socket.handshake.headers?.authorization?.split(' ')[1] ||
      socket.handshake.query?.token;
    
    // If no token, proceed as guest
    if (!token) {
      logger.debug('No auth token, connecting as guest');
      return next();
    }
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from the token
    const user = await User.findById(decoded.id);
    
    // If user not found, proceed as guest
    if (!user) {
      logger.debug('User not found with token, connecting as guest');
      return next();
    }
    
    // Attach user to socket
    socket.user = user;
    logger.debug(`Socket authenticated for user: ${user._id}`);
    
    next();
  } catch (error) {
    logger.error(`Socket auth error: ${error.message}`);
    // Proceed as guest on error
    next();
  }
};

export default socketAuth;