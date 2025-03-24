// middlewares/validator.js - Request Validation Middleware
import Joi from 'joi';
import ErrorResponse from '../utils/errorResponse.js';

/**
 * Validate request body against a Joi schema
 * @param {Object} schema - Joi validation schema
 * @returns {Function} Express middleware function
 */
export const validateBody = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { 
      abortEarly: false,
      stripUnknown: true
    });
    
    if (error) {
      const errorMessages = error.details.map(detail => detail.message).join(', ');
      return next(new ErrorResponse(errorMessages, 400));
    }
    
    next();
  };
};

/**
 * Validate request params against a Joi schema
 * @param {Object} schema - Joi validation schema
 * @returns {Function} Express middleware function
 */
export const validateParams = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.params, { 
      abortEarly: false,
      stripUnknown: true
    });
    
    if (error) {
      const errorMessages = error.details.map(detail => detail.message).join(', ');
      return next(new ErrorResponse(errorMessages, 400));
    }
    
    next();
  };
};

/**
 * Validate request query against a Joi schema
 * @param {Object} schema - Joi validation schema
 * @returns {Function} Express middleware function
 */
export const validateQuery = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.query, { 
      abortEarly: false,
      stripUnknown: true
    });
    
    if (error) {
      const errorMessages = error.details.map(detail => detail.message).join(', ');
      return next(new ErrorResponse(errorMessages, 400));
    }
    
    next();
  };
};

// Common validation schemas
export const schemas = {
  // Auth schemas
  register: Joi.object({
    username: Joi.string().min(3).max(20).required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required()
  }),
  
  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),
  
  // Game schemas
  createGame: Joi.object({
    difficulty: Joi.string().valid('easy', 'medium', 'hard', 'mixed'),
    subject: Joi.string().valid('algebra', 'geometry', 'calculus', 'statistics', 'other', 'mixed'),
    maxRounds: Joi.number().integer().min(1).max(10),
    winningScore: Joi.number().integer().min(1).max(10)
  }),
  
  joinGame: Joi.object({
    gameCode: Joi.string().required()
  }),
  
  submitAnswer: Joi.object({
    answer: Joi.string().required(),
    timeElapsed: Joi.number().positive().required()
  }),
  
  // Question schemas
  createQuestion: Joi.object({
    questionId: Joi.string().required(),
    text: Joi.string().required(),
    type: Joi.string().valid('multiple-choice', 'numeric', 'text').required(),
    difficulty: Joi.string().valid('easy', 'medium', 'hard').required(),
    subject: Joi.string().valid('algebra', 'geometry', 'calculus', 'statistics', 'other'),
    skillTag: Joi.string().allow(''),
    options: Joi.array().items(
      Joi.object({
        label: Joi.string().required(),
        value: Joi.string().required(),
        text: Joi.string().required()
      })
    ),
    correctAnswer: Joi.string().required(),
    explanation: Joi.string().required(),
    stepByStepLink: Joi.string().allow(''),
    imageUrl: Joi.string().allow('')
  }),
  
  // Query params
  paginationQuery: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(10),
    sort: Joi.string(),
    fields: Joi.string()
  }),

  challengeUser: Joi.object({
    userId: Joi.string().required(),
    gameOptions: Joi.object({
      difficulty: Joi.string().valid('easy', 'medium', 'hard', 'mixed'),
      subject: Joi.string().valid('algebra', 'geometry', 'calculus', 'statistics', 'other', 'mixed'),
      maxRounds: Joi.number().integer().min(1).max(10),
      winningScore: Joi.number().integer().min(1).max(10)
    }).default({})
  }),
  
  respondToChallenge: Joi.object({
    response: Joi.string().valid('accept', 'reject').required()
  }),

};