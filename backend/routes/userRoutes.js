// routes/userRoutes.js - User Routes
import express from 'express';
import {
  getUsers,
  getUser,
  createUser,
  updateUser,
  deleteUser,
  getUserProfile,
  getLeaderboard,
  getUserStats,
  getOnlineUsers
} from '../controllers/userController.js';
import { protect, authorize } from '../middlewares/authMiddleware.js';
import { validateQuery, schemas } from '../middlewares/validator.js';

const router = express.Router();

// Public routes
router.get('/profile/:username', getUserProfile);
router.get('/leaderboard', getLeaderboard);

// Protected routes (require authentication)
router.use(protect);
router.get('/stats', getUserStats);
router.get('/online', getOnlineUsers);

// Admin-only routes
router.use(authorize('admin'));
router.route('/')
  .get(validateQuery(schemas.paginationQuery), getUsers)
  .post(createUser);

router.route('/:id')
  .get(getUser)
  .put(updateUser)
  .delete(deleteUser);

export default router;