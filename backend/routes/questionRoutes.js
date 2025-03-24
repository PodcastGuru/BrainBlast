// routes/questionRoutes.js - Question Routes
import express from 'express';
import {
  getQuestions,
  getQuestion,
  createQuestion,
  updateQuestion,
  deleteQuestion,
  getRandomQuestion,
  importQuestions
} from '../controllers/questionsController.js';
import { protect, authorize } from '../middlewares/authMiddleware.js';
import { validateBody, validateParams, validateQuery, schemas } from '../middlewares/validator.js';

const router = express.Router();

// Public routes
router.get('/random', getRandomQuestion);

// Protected routes (require authentication)
router.use(protect);

// Admin-only routes
router.use(authorize('admin'));
router.get('/', validateQuery(schemas.paginationQuery), getQuestions);
router.post('/', validateBody(schemas.createQuestion), createQuestion);
router.post('/import', importQuestions);

router.route('/:id')
  .get(getQuestion)
  .put(validateBody(schemas.createQuestion), updateQuestion)
  .delete(deleteQuestion);

export default router;