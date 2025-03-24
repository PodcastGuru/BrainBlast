// middlewares/asyncHandler.js - Async Function Handler
/**
 * Wrapper for async controller functions to eliminate try-catch blocks
 * @param {Function} fn - Async controller function
 * @returns {Function} Express middleware function
 */
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
  
  export default asyncHandler;