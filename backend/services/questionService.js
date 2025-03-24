
// services/questionService.js - Question Service
import Question from '../models/Question.js';
import ErrorResponse from '../utils/errorResponse.js';
import logger from '../utils/logger.js';
import { parseCSV } from '../utils/helpers.js';

/**
 * Question service for handling question-related business logic
 */
const questionService = {
  /**
   * Get questions with filtering and pagination
   * @param {Object} queryParams - Query parameters for filtering and pagination
   * @returns {Object} Questions and pagination info
   */
  getQuestions: async (queryParams) => {
    try {
      const { 
        difficulty, 
        subject, 
        type, 
        isActive, 
        skillTag,
        page = 1,
        limit = 10,
        sort = '-createdAt'
      } = queryParams;
      
      // Build query
      const query = {};
      
      if (difficulty) query.difficulty = difficulty;
      if (subject) query.subject = subject;
      if (type) query.type = type;
      if (isActive !== undefined) query.isActive = isActive === 'true';
      if (skillTag) query.skillTag = skillTag;
      
      // Pagination
      const startIndex = (page - 1) * limit;
      const endIndex = page * limit;
      const total = await Question.countDocuments(query);
      
      // Get questions
      const questions = await Question.find(query)
        .skip(startIndex)
        .limit(parseInt(limit))
        .sort(sort);
      
      // Pagination result
      const pagination = {
        total,
        pages: Math.ceil(total / limit),
        page: parseInt(page),
        limit: parseInt(limit)
      };
      
      // Add next/prev pages
      if (endIndex < total) {
        pagination.next = parseInt(page) + 1;
      }
      
      if (startIndex > 0) {
        pagination.prev = parseInt(page) - 1;
      }
      
      return { questions, pagination };
    } catch (error) {
      logger.error(`Error getting questions: ${error.message}`);
      throw new ErrorResponse('Failed to get questions', 500);
    }
  },
  
  /**
   * Get a single question by ID
   * @param {string} id - Question ID
   * @returns {Object} Question
   */
  getQuestion: async (id) => {
    try {
      const question = await Question.findById(id);
      
      if (!question) {
        throw new ErrorResponse(`Question not found with id ${id}`, 404);
      }
      
      return question;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error getting question: ${error.message}`);
      throw new ErrorResponse('Failed to get question', 500);
    }
  },
  
  /**
   * Create a new question
   * @param {Object} questionData - Question data
   * @param {string} userId - User ID of creator (optional)
   * @returns {Object} Created question
   */
  createQuestion: async (questionData, userId = null) => {
    try {
      // Set creator if provided
      if (userId) {
        questionData.createdBy = userId;
      }
      
      // Validate required fields
      const requiredFields = ['questionId', 'text', 'type', 'difficulty', 'correctAnswer', 'explanation'];
      
      for (const field of requiredFields) {
        if (!questionData[field]) {
          throw new ErrorResponse(`${field} is required`, 400);
        }
      }
      
      // Validate options for multiple-choice questions
      if (questionData.type === 'multiple-choice' && (!questionData.options || questionData.options.length < 2)) {
        throw new ErrorResponse('Multiple-choice questions must have at least 2 options', 400);
      }
      
      const question = await Question.create(questionData);
      
      return question;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      // Handle duplicate key error
      if (error.code === 11000) {
        throw new ErrorResponse('Question with this ID already exists', 400);
      }
      
      logger.error(`Error creating question: ${error.message}`);
      throw new ErrorResponse('Failed to create question', 500);
    }
  },
  
  /**
   * Update an existing question
   * @param {string} id - Question ID
   * @param {Object} updateData - Data to update
   * @returns {Object} Updated question
   */
  updateQuestion: async (id, updateData) => {
    try {
      let question = await Question.findById(id);
      
      if (!question) {
        throw new ErrorResponse(`Question not found with id ${id}`, 404);
      }
      
      // Validate options for multiple-choice questions
      if (updateData.type === 'multiple-choice' && (!updateData.options || updateData.options.length < 2)) {
        throw new ErrorResponse('Multiple-choice questions must have at least 2 options', 400);
      }
      
      question = await Question.findByIdAndUpdate(id, updateData, {
        new: true,
        runValidators: true
      });
      
      return question;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error updating question: ${error.message}`);
      throw new ErrorResponse('Failed to update question', 500);
    }
  },
  
  /**
   * Delete a question
   * @param {string} id - Question ID
   */
  deleteQuestion: async (id) => {
    try {
      const question = await Question.findById(id);
      
      if (!question) {
        throw new ErrorResponse(`Question not found with id ${id}`, 404);
      }
      
      await question.deleteOne();
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error deleting question: ${error.message}`);
      throw new ErrorResponse('Failed to delete question', 500);
    }
  },
  
  /**
   * Get a random question based on criteria
   * @param {Object} criteria - Criteria for selecting a question
   * @returns {Object} Random question
   */
  getRandomQuestion: async (criteria = {}) => {
    try {
      const { difficulty, subject, type, excludeIds = [] } = criteria;
      
      // Build query
      const query = { isActive: true };
      
      if (difficulty && difficulty !== 'mixed') {
        query.difficulty = difficulty;
      }
      
      if (subject && subject !== 'mixed') {
        query.subject = subject;
      }
      
      if (type) {
        query.type = type;
      }
      
      // Exclude specific questions
      if (excludeIds.length > 0) {
        query._id = { $nin: excludeIds };
      }
      
      // Count matching questions
      const count = await Question.countDocuments(query);
      
      if (count === 0) {
        throw new ErrorResponse('No questions found matching the criteria', 404);
      }
      
      // Get random question
      const random = Math.floor(Math.random() * count);
      const question = await Question.findOne(query).skip(random);
      
      return question;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error getting random question: ${error.message}`);
      throw new ErrorResponse('Failed to get random question', 500);
    }
  },
  
  /**
   * Import questions in bulk
   * @param {Array} questions - Array of question objects
   * @param {string} userId - User ID of creator (optional)
   * @returns {Array} Imported questions
   */
  importQuestions: async (questions, userId = null) => {
    try {
      if (!questions || !Array.isArray(questions) || questions.length === 0) {
        throw new ErrorResponse('Please provide an array of questions', 400);
      }
      
      // Set creator for all questions
      if (userId) {
        questions.forEach(question => {
          question.createdBy = userId;
        });
      }
      
      const importedQuestions = await Question.insertMany(questions);
      
      return importedQuestions;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      // Handle duplicate key error
      if (error.code === 11000) {
        throw new ErrorResponse('One or more questions already exist', 400);
      }
      
      logger.error(`Error importing questions: ${error.message}`);
      throw new ErrorResponse('Failed to import questions', 500);
    }
  },
  
  /**
   * Import questions from CSV
   * @param {string} csvData - CSV data string
   * @param {string} userId - User ID of creator (optional)
   * @returns {Array} Imported questions
   */
  importQuestionsFromCSV: async (csvData, userId = null) => {
    try {
      // Parse CSV
      const parsedData = parseCSV(csvData);
      
      if (!parsedData || parsedData.length === 0) {
        throw new ErrorResponse('No valid data found in CSV', 400);
      }
      
      const questions = parsedData.map(row => {
        // Common fields
        const question = {
          questionId: row.IDSkillTags || `Q${Date.now()}`,
          text: row.Question || '',
          type: row.ABCD ? 'multiple-choice' : 'numeric',
          difficulty: row.Difficulty?.toLowerCase() || 'medium',
          correctAnswer: row['Correct Answer'] || '',
          explanation: row['Formal Answer Explanation'] || '',
          skillTag: row.IDSkillTags?.split(' ')[0] || '',
          subject: 'other'  // Default
        };
        
        // Determine subject based on skill tag
        if (question.skillTag.startsWith('ALG')) {
          question.subject = 'algebra';
        } else if (question.skillTag.startsWith('GEO')) {
          question.subject = 'geometry';
        } else if (question.skillTag.startsWith('CALC')) {
          question.subject = 'calculus';
        } else if (question.skillTag.startsWith('STAT')) {
          question.subject = 'statistics';
        }
        
        // Add image URL if available
        if (row['IMG URL']) {
          question.imageUrl = row['IMG URL'];
        }
        
        // Add step-by-step link if available
        if (row['Step-by-Step Answer Explanation Link']) {
          question.stepByStepLink = row['Step-by-Step Answer Explanation Link'];
        }
        
        // Add options for multiple-choice questions
        if (question.type === 'multiple-choice' && row.ABCD) {
          const options = [];
          const optionsText = row.ABCD.split(' ');
          
          for (let i = 0; i < optionsText.length; i++) {
            const label = String.fromCharCode(65 + i);  // A, B, C, D...
            options.push({
              label,
              value: label,
              text: optionsText[i]
            });
          }
          
          question.options = options;
        }
        
        return question;
      });
      
      // Set creator for all questions
      if (userId) {
        questions.forEach(question => {
          question.createdBy = userId;
        });
      }
      
      // Filter out invalid questions
      const validQuestions = questions.filter(q => 
        q.text && 
        q.correctAnswer && 
        (q.type !== 'multiple-choice' || (q.options && q.options.length >= 2))
      );
      
      if (validQuestions.length === 0) {
        throw new ErrorResponse('No valid questions found in CSV', 400);
      }
      
      const importedQuestions = await Question.insertMany(validQuestions);
      
      return importedQuestions;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
    }

    try {
      
      const highestQuestion = await Question.findOne({ 
        questionId: { $regex: regex } 
      }).sort({ questionId: -1 });
      
      if (!highestQuestion) {
        return `${prefix}001`;
      }
      
      // Extract the number part
      const match = highestQuestion.questionId.match(/\d+$/);
      if (!match) {
        return `${prefix}001`;
      }
      
      // Increment the number
      const num = parseInt(match[0]) + 1;
      return `${prefix}${num.toString().padStart(3, '0')}`;
    } catch (error) {
      logger.error(`Error generating question ID: ${error.message}`);
      return `${prefix}${Date.now()}`;
    }
  }
};

export default questionService;