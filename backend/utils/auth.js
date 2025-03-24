// utils/auth.js - Authentication Utilities
import crypto from 'crypto';

/**
 * Create and send token response with cookie
 * @param {Object} user - User object
 * @param {number} statusCode - HTTP status code
 * @param {Object} res - Express response object
 */
export const sendTokenResponse = (user, statusCode, res) => {
  // Create token
  const token = user.getSignedJwtToken();

  // Set cookie options
  const options = {
    expires: new Date(
      Date.now() + process.env.JWT_COOKIE_EXPIRE * 24 * 60 * 60 * 1000
    ),
    httpOnly: true
  };

  // Secure cookie in production
  if (process.env.NODE_ENV === 'production') {
    options.secure = true;
  }

  // Send response
  res
    .status(statusCode)
    .cookie('token', token, options)
    .json({
      success: true,
      token
    });
};

/**
 * Generate random token
 * @returns {string} Random token
 */
export const generateToken = () => {
  return crypto.randomBytes(20).toString('hex');
};

/**
 * Generate hashed token
 * @param {string} token - Token to hash
 * @returns {string} Hashed token
 */
export const getHashedToken = (token) => {
  return crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');
};

/**
 * Generate expiration date for tokens
 * @param {number} minutes - Minutes from now
 * @returns {Date} Expiration date
 */
export const getExpirationDate = (minutes = 10) => {
  return new Date(Date.now() + minutes * 60 * 1000);
};