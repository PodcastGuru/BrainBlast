// controllers/questionController.js - Question Controller
import asyncHandler from '../middlewares/asyncHandler.js';
import ErrorResponse from '../utils/errorResponse.js';
import Question from '../models/Question.js';

/**
 * @desc    Get all questions
 * @route   GET /api/questions
 * @access  Private (Admin only)
 */
export const getQuestions = asyncHandler(async (req, res, next) => {
  // Query parameters
  const { 
    difficulty, 
    subject, 
    type, 
    isActive, 
    skillTag,
    page = 1,
    limit = 10,
    sort = '-createdAt'
  } = req.query;
  
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
  
  res.status(200).json({
    success: true,
    pagination,
    data: questions
  });
});

/**
 * @desc    Get single question
 * @route   GET /api/questions/:id
 * @access  Private (Admin only)
 */
export const getQuestion = asyncHandler(async (req, res, next) => {
  const question = await Question.findById(req.params.id);
  
  if (!question) {
    return next(new ErrorResponse(`Question not found with id ${req.params.id}`, 404));
  }
  
  res.status(200).json({
    success: true,
    data: question
  });
});

/**
 * @desc    Create new question
 * @route   POST /api/questions
 * @access  Private (Admin only)
 */
export const createQuestion = asyncHandler(async (req, res, next) => {
  // Set creator if authenticated
  if (req.user) {
    req.body.createdBy = req.user._id;
  }
  
  const question = await Question.create(req.body);
  
  res.status(201).json({
    success: true,
    data: question
  });
});

/**
 * @desc    Update question
 * @route   PUT /api/questions/:id
 * @access  Private (Admin only)
 */
export const updateQuestion = asyncHandler(async (req, res, next) => {
  let question = await Question.findById(req.params.id);
  
  if (!question) {
    return next(new ErrorResponse(`Question not found with id ${req.params.id}`, 404));
  }
  
  question = await Question.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true
  });
  
  res.status(200).json({
    success: true,
    data: question
  });
});

/**
 * @desc    Delete question
 * @route   DELETE /api/questions/:id
 * @access  Private (Admin only)
 */
export const deleteQuestion = asyncHandler(async (req, res, next) => {
  const question = await Question.findById(req.params.id);
  
  if (!question) {
    return next(new ErrorResponse(`Question not found with id ${req.params.id}`, 404));
  }
  
  await question.deleteOne();
  
  res.status(200).json({
    success: true,
    data: {}
  });
});

/**
 * @desc    Get random question
 * @route   GET /api/questions/random
 * @access  Private
 */
export const getRandomQuestion = asyncHandler(async (req, res, next) => {
  const { difficulty, subject, type } = req.query;
  
  // Build query
  const query = { isActive: true };
  
  if (difficulty) query.difficulty = difficulty;
  if (subject) query.subject = subject;
  if (type) query.type = type;
  
  // Count matching questions
  const count = await Question.countDocuments(query);
  
  if (count === 0) {
    return next(new ErrorResponse('No questions found matching the criteria', 404));
  }
  
  // Get random question
  const random = Math.floor(Math.random() * count);
  const question = await Question.findOne(query).skip(random);
  
  res.status(200).json({
    success: true,
    data: question
  });
});

/**
 * @desc    Import questions in bulk
 * @route   POST /api/questions/import
 * @access  Private (Admin only)
 */
export const importQuestions = asyncHandler(async (req, res, next) => {
  const { questions } = req.body;
  
  if (!questions || !Array.isArray(questions) || questions.length === 0) {
    return next(new ErrorResponse('Please provide an array of questions', 400));
  }
  
  // Set creator for all questions
  if (req.user) {
    questions.forEach(question => {
      question.createdBy = req.user._id;
    });
  }
  
  const importedQuestions = await Question.insertMany(questions);
  
  res.status(201).json({
    success: true,
    count: importedQuestions.length,
    data: importedQuestions
  });
});