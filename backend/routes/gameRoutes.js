// routes/gameRoutes.js - Game Routes
import express from 'express';
import {
  createGame,
  joinGame,
  getGameState,
  submitAnswer,
  getActiveGames,
  getGameHistory,
  abandonGame,
  challengeUser,
  getChallenges,
  respondToChallenge,
} from '../controllers/gameController.js';
import { protect } from '../middlewares/authMiddleware.js';
import { validateBody, validateParams, schemas } from '../middlewares/validator.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

// Game management routes
router.post('/', validateBody(schemas.createGame), createGame);
router.post('/join', validateBody(schemas.joinGame), joinGame);
router.get('/active', getActiveGames);
router.get('/history', getGameHistory);

// Game-specific routes
router.get('/:gameCode', getGameState);
router.post('/:gameCode/answer', validateBody(schemas.submitAnswer), submitAnswer);
router.put('/:gameCode/abandon', abandonGame);

// Challenge routes
router.post('/challenge', validateBody(schemas.challengeUser), challengeUser);
router.put('/challenge/:gameCode/respond', validateBody(schemas.respondToChallenge), respondToChallenge);
router.get('/challenges', getChallenges);

export default router;