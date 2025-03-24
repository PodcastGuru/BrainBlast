// utils/errorResponse.js - Custom Error Response Class
/**
 * Custom error class for API responses
 * @extends Error
 */
class ErrorResponse extends Error {
    /**
     * Create an ErrorResponse
     * @param {string} message - Error message
     * @param {number} statusCode - HTTP status code
     */
    constructor(message, statusCode) {
      super(message);
      this.statusCode = statusCode;
      
      // Capture stack trace
      Error.captureStackTrace(this, this.constructor);
    }
  }
  
  export default ErrorResponse;