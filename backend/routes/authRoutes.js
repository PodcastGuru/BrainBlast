// routes/authRoutes.js - Authentication Routes
import express from 'express';
import {
  register,
  login,
  getMe,
  logout,
  updateDetails,
  updatePassword
} from '../controllers/authController.js';
import { protect } from '../middlewares/authMiddleware.js';
import { validateBody, schemas } from '../middlewares/validator.js';

const router = express.Router();

// Public routes
router.post('/register', validateBody(schemas.register), register);
router.post('/login', validateBody(schemas.login), login);
router.get('/logout', logout);

// Protected routes (require authentication)
router.use(protect);
router.get('/me', getMe);
router.put('/updatedetails', updateDetails);
router.put('/updatepassword', updatePassword);

export default router;