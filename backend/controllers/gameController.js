// controllers/gameController.js - Game Controller
import asyncHandler from '../middlewares/asyncHandler.js';
import ErrorResponse from '../utils/errorResponse.js';
import Game from '../models/Game.js';
import Question from '../models/Question.js';
import User from '../models/User.js';

/**
 * @desc    Create a new game
 * @route   POST /api/games
 * @access  Private
 */
export const getGameHistory = asyncHandler(async (req, res, next) => {
  // Find all completed games where user is a player
  const games = await Game.find({
    $or: [
      { 'players.player1.user': req.user._id },
      { 'players.player2.user': req.user._id }
    ],
    status: 'completed'
  })
    .sort({ completedAt: -1 })
    .limit(10)
    .populate('players.player1.user', 'username avatar')
    .populate('players.player2.user', 'username avatar');

  res.status(200).json({
    success: true,
    count: games.length,
    data: games
  });
});

/**
 * @desc    Abandon a game
 * @route   PUT /api/games/:gameCode/abandon
 * @access  Private
 */
export const abandonGame = asyncHandler(async (req, res, next) => {
  const { gameCode } = req.params;

  // Find the game
  const game = await Game.findOne({ gameCode });

  if (!game) {
    return next(new ErrorResponse('Game not found', 404));
  }

  // Check if user is a player in this game
  let playerType = null;
  if (game.players.player1.user.toString() === req.user._id.toString()) {
    playerType = 'player1';
  } else if (game.players.player2.user?.toString() === req.user._id.toString()) {
    playerType = 'player2';
  }

  if (!playerType) {
    return next(new ErrorResponse('You are not a player in this game', 403));
  }

  // Can only abandon active or paused games
  if (!['active', 'paused', 'waiting'].includes(game.status)) {
    return next(new ErrorResponse(`Cannot abandon a game with status: ${game.status}`, 400));
  }

  // Mark game as abandoned
  game.status = 'abandoned';
  await game.save();

  res.status(200).json({
    success: true,
    data: { gameCode, status: game.status }
  });
});

// Helper function to get a random question
const getRandomQuestion = async (difficulty, subject) => {
  // Build query
  const query = { isActive: true };

  if (difficulty && difficulty !== 'mixed') {
    query.difficulty = difficulty;
  }

  if (subject && subject !== 'mixed') {
    query.subject = subject;
  }

  // Count matching questions
  const count = await Question.countDocuments(query);

  // If no questions, return null
  if (count === 0) {
    return null;
  }

  // Get random question
  const random = Math.floor(Math.random() * count);
  return await Question.findOne(query).skip(random);
};

// Helper function to check if an answer is correct
const checkAnswer = (question, answer) => {
  // For multiple-choice questions
  if (question.type === 'multiple-choice') {
    return answer === question.correctAnswer;
  }

  // For numeric questions, allow for slight rounding differences
  if (question.type === 'numeric') {
    // Try to parse both as numbers
    const numericAnswer = parseFloat(answer.replace(/\\s/g, ''));
    const correctAnswer = parseFloat(question.correctAnswer.replace(/\\s/g, ''));

    if (isNaN(numericAnswer) || isNaN(correctAnswer)) {
      return answer.trim() === question.correctAnswer.trim();
    }

    // Allow for a small margin of error for floating point comparisons
    const epsilon = 0.0001;
    return Math.abs(numericAnswer - correctAnswer) < epsilon;
  }

  // For text answers, ignore case and whitespace
  return answer.trim().toLowerCase() === question.correctAnswer.trim().toLowerCase();
};

export const createGame = asyncHandler(async (req, res, next) => {
  const { difficulty, subject, maxRounds, winningScore } = req.body;

  // Generate a unique game code
  let gameCode;
  let codeExists = true;

  while (codeExists) {
    gameCode = Game.generateGameCode();
    codeExists = await Game.findOne({ gameCode });
  }

  // Create game with current user as player1
  const game = new Game({
    gameCode,
    players: {
      player1: {
        user: req.user._id
      }
    },
    status: 'waiting',
    ...(difficulty && { difficulty }),
    ...(subject && { subject }),
    ...(maxRounds && { maxRounds }),
    ...(winningScore && { winningScore })
  });

  await game.save();

  res.status(201).json({
    success: true,
    data: {
      gameCode,
      status: game.status
    }
  });
});

/**
 * @desc    Join an existing game
 * @route   POST /api/games/join
 * @access  Private
 */
export const joinGame = asyncHandler(async (req, res, next) => {
  const { gameCode } = req.body;

  // Find the game
  const game = await Game.findOne({ gameCode });

  if (!game) {
    return next(new ErrorResponse('Game not found', 404));
  }

  // Check if game already has two players
  if (game.players.player2 && game.players.player2.user) {
    return next(new ErrorResponse('Game is already full', 400));
  }

  // Check if game is in waiting status
  if (game.status !== 'waiting') {
    return next(new ErrorResponse('Game is not in waiting status', 400));
  }

  // Check if current user is already player1
  if (game.players.player1.user.toString() === req.user._id.toString()) {
    return next(new ErrorResponse('You are already in this game', 400));
  }

  // Add current user as player2
  game.players.player2 = {
    user: req.user._id
  };

  // Set game to active
  game.status = 'active';
  game.startedAt = new Date();

  // Add first round with a random question
  const question = await getRandomQuestion(game.difficulty, game.subject);
  if (!question) {
    return next(new ErrorResponse('No questions available', 500));
  }

  game.rounds.push({
    roundNumber: 1,
    question: question._id
  });

  await game.save();

  res.status(200).json({
    success: true,
    data: {
      gameCode,
      status: game.status,
      currentRound: game.currentRound
    }
  });
});

/**
 * @desc    Get game state
 * @route   GET /api/games/:gameCode
 * @access  Private
 */
export const getGameState = asyncHandler(async (req, res, next) => {
  const { gameCode } = req.params;

  // Find the game and populate question data
  const game = await Game.findOne({ gameCode })
    .populate('rounds.question')
    .populate('players.player1.user', 'username avatar')
    .populate('players.player2.user', 'username avatar');

  if (!game) {
    return next(new ErrorResponse('Game not found', 404));
  }

  // Check if user is a player in this game
  let playerType = null;
  if (game.players.player1.user._id.toString() === req.user._id.toString()) {
    playerType = 'player1';
  } else if (game.players.player2 && game.players.player2.user &&
    game.players.player2.user._id.toString() === req.user._id.toString()) {
    playerType = 'player2';
  }

  if (!playerType) {
    return next(new ErrorResponse('You are not a player in this game', 403));
  }

  // Get filtered game state for this player
  const gameState = game.getStateForPlayer(playerType);

  res.status(200).json({
    success: true,
    data: gameState
  });
});

/**
 * @desc    Submit answer for current round
 * @route   POST /api/games/:gameCode/answer
 * @access  Private
 */
export const submitAnswer = asyncHandler(async (req, res, next) => {
  const { gameCode } = req.params;
  const { answer, timeElapsed } = req.body;

  // Find the game
  const game = await Game.findOne({ gameCode })
    .populate('rounds.question');

  if (!game) {
    return next(new ErrorResponse('Game not found', 404));
  }

  // Determine player type
  let playerType = null;
  if (game.players.player1.user.toString() === req.user._id.toString()) {
    playerType = 'player1';
  } else if (game.players.player2.user.toString() === req.user._id.toString()) {
    playerType = 'player2';
  }

  if (!playerType) {
    return next(new ErrorResponse('You are not a player in this game', 403));
  }

  // Check if it's the player's turn
  if (game.currentTurn !== playerType) {
    return next(new ErrorResponse('It is not your turn', 400));
  }

  // Get current round
  const currentRoundIndex = game.currentRound - 1;
  if (currentRoundIndex >= game.rounds.length) {
    return next(new ErrorResponse('Round not found', 404));
  }

  const round = game.rounds[currentRoundIndex];

  // Check if already answered
  if (round[`${playerType}Answer`]) {
    return next(new ErrorResponse('You have already answered this round', 400));
  }

  // Get question and check if answer is correct
  const question = round.question;
  const isCorrect = checkAnswer(question, answer);

  // Record the answer
  await game.submitAnswer(playerType, answer, timeElapsed);

  // Update the correctness of the answer
  round[`${playerType}Answer`].isCorrect = isCorrect;

  // Update user's last activity
  game.players[playerType].lastActivity = new Date();

  // Check if both players have answered
  const bothAnswered =
    round.player1Answer &&
    round.player2Answer;

  if (bothAnswered) {
    // Evaluate the round
    await game.evaluateRound();
  } else {
    // Switch turns
    game.currentTurn = playerType === 'player1' ? 'player2' : 'player1';
    await game.save();
  }

  // Get updated game state for this player
  const gameState = game.getStateForPlayer(playerType);

  res.status(200).json({
    success: true,
    data: {
      isCorrect,
      gameState
    }
  });
});

/**
 * @desc    Get active games for current user
 * @route   GET /api/games/active
 * @access  Private
 */
export const getActiveGames = asyncHandler(async (req, res, next) => {
  // Find all active games where user is a player
  const games = await Game.find({
    $or: [
      { 'players.player1.user': req.user._id },
      { 'players.player2.user': req.user._id }
    ],
    status: { $in: ['waiting', 'active', 'paused'] }
  }).select('gameCode status currentRound players.player1.user players.player2.user createdAt');

  res.status(200).json({
    success: true,
    count: games.length,
    data: games
  });
});


/**
 * @desc    Challenge another user to a game
 * @route   POST /api/games/challenge
 * @access  Private
 */
export const challengeUser = asyncHandler(async (req, res, next) => {
  const { userId, gameOptions } = req.body;

  // Check if challenged user exists
  const challengedUser = await User.findById(userId);
  if (!challengedUser) {
    return next(new ErrorResponse('User not found', 404));
  }

  // Create a new game with challenge info
  const game = await gameService.createChallengeGame(req.user.id, userId, gameOptions);

  // Notify the challenged user via socket
  io.to(`user:${userId}`).emit('challenge:received', {
    gameCode: game.gameCode,
    challenger: {
      id: req.user.id,
      username: req.user.username,
      avatar: req.user.avatar
    },
    gameOptions,
    expiresAt: game.challengeInfo.expiresAt
  });

  res.status(201).json({
    success: true,
    data: {
      gameCode: game.gameCode,
      status: 'pending',
      expiresAt: game.challengeInfo.expiresAt
    }
  });
});


/**
 * @desc    Respond to a game challenge (accept/reject)
 * @route   PUT /api/games/challenge/:gameCode/respond
 * @access  Private
 */
export const respondToChallenge = asyncHandler(async (req, res, next) => {
  const { gameCode } = req.params;
  const { response } = req.body; // 'accept' or 'reject'

  const result = await gameService.respondToChallenge(gameCode, req.user.id, response);

  // Notify the challenger via socket
  io.to(`user:${result.challengerId}`).emit('challenge:response', {
    gameCode,
    status: response,
    responder: {
      id: req.user.id,
      username: req.user.username
    }
  });

  res.status(200).json({
    success: true,
    data: result
  });
});

/**
 * @desc    Get all challenges (sent and received) for the current user
 * @route   GET /api/games/challenges
 * @access  Private
 */
export const getChallenges = asyncHandler(async (req, res, next) => {
  const challenges = await gameService.getUserChallenges(req.user.id);

  res.status(200).json({
    success: true,
    data: challenges
  });
});