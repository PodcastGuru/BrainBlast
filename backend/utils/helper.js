// utils/helpers.js - Helper Functions
import crypto from 'crypto';

/**
 * Generate a random alphanumeric string
 * @param {number} length - Length of the string
 * @returns {string} Random string
 */
export const generateRandomString = (length = 10) => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

/**
 * Format date to ISO string without time
 * @param {Date} date - Date to format
 * @returns {string} Formatted date
 */
export const formatDate = (date) => {
  return date.toISOString().split('T')[0];
};

/**
 * Check if a value is a valid MongoDB ObjectId
 * @param {string} id - ID to check
 * @returns {boolean} Whether ID is valid
 */
export const isValidObjectId = (id) => {
  if (!id) return false;
  const regex = /^[0-9a-fA-F]{24}$/;
  return regex.test(id);
};

/**
 * Format time in seconds to MM:SS format
 * @param {number} seconds - Time in seconds
 * @returns {string} Formatted time
 */
export const formatTime = (seconds) => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
};

/**
 * Calculate elapsed time between two dates in seconds
 * @param {Date} startDate - Start date
 * @param {Date} endDate - End date (defaults to now)
 * @returns {number} Elapsed time in seconds
 */
export const calculateElapsedTime = (startDate, endDate = new Date()) => {
  return (endDate - startDate) / 1000;
};

/**
 * Parse CSV data to array of objects
 * @param {string} csvData - CSV data
 * @param {string} delimiter - CSV delimiter
 * @returns {Array} Array of objects
 */
export const parseCSV = (csvData, delimiter = ',') => {
  // Split into lines
  const lines = csvData.split('\n');
  if (lines.length === 0) return [];
  
  // Get headers
  const headers = lines[0].split(delimiter).map(header => header.trim());
  
  // Parse data lines
  const result = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    const values = line.split(delimiter);
    const obj = {};
    
    headers.forEach((header, index) => {
      obj[header] = values[index] ? values[index].trim() : '';
    });
    
    result.push(obj);
  }
  
  return result;
};

/**
 * Get a random item from an array
 * @param {Array} array - Array to get random item from
 * @returns {*} Random item
 */
export const getRandomItem = (array) => {
  if (!array || array.length === 0) return null;
  return array[Math.floor(Math.random() * array.length)];
};

/**
 * Shuffle an array using Fisher-Yates algorithm
 * @param {Array} array - Array to shuffle
 * @returns {Array} Shuffled array
 */
export const shuffleArray = (array) => {
  const result = [...array];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
};

/**
 * Generate a hash of a string
 * @param {string} str - String to hash
 * @returns {string} Hashed string
 */
export const generateHash = (str) => {
  return crypto.createHash('sha256').update(str).digest('hex');
};

/**
 * Truncate a string to a specified length and add ellipsis
 * @param {string} str - String to truncate
 * @param {number} length - Maximum length
 * @returns {string} Truncated string
 */
export const truncateString = (str, length = 100) => {
  if (!str || str.length <= length) return str;
  return str.slice(0, length) + '...';
};

/**
 * Deep clone an object
 * @param {Object} obj - Object to clone
 * @returns {Object} Cloned object
 */
export const deepClone = (obj) => {
  return JSON.parse(JSON.stringify(obj));
};

/**
 * Validate an email address format
 * @param {string} email - Email to validate
 * @returns {boolean} Whether email is valid
 */
export const isValidEmail = (email) => {
  const regex = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return regex.test(String(email).toLowerCase());
};

/**
 * Calculate average of an array of numbers
 * @param {Array} numbers - Array of numbers
 * @returns {number} Average value
 */
export const calculateAverage = (numbers) => {
  if (!numbers || numbers.length === 0) return 0;
  return numbers.reduce((sum, num) => sum + num, 0) / numbers.length;
};

/**
 * Convert a string to title case
 * @param {string} str - String to convert
 * @returns {string} Title case string
 */
export const toTitleCase = (str) => {
  if (!str) return '';
  return str.replace(
    /\w\S*/g,
    txt => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
  );
};