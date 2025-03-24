// services/gameService.js - Game Service
import Game from '../models/Game.js';
import Question from '../models/Question.js';
import User from '../models/User.js';
import ErrorResponse from '../utils/errorResponse.js';
import logger from '../utils/logger.js';
import { GAME_STATUS, PLAYER_TYPES, ROUND_OUTCOMES } from '../utils/constants.js';

/**
 * Game service for handling game-related business logic
 */
const gameService = {
  /**
   * Create a new game
   * @param {string} userId - User ID of the game creator
   * @param {Object} options - Game options
   * @returns {Object} Created game
   */
  createGame: async (userId, options = {}) => {
    try {
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
            user: userId
          }
        },
        status: GAME_STATUS.WAITING,
        ...(options.difficulty && { difficulty: options.difficulty }),
        ...(options.subject && { subject: options.subject }),
        ...(options.maxRounds && { maxRounds: options.maxRounds }),
        ...(options.winningScore && { winningScore: options.winningScore })
      });

      await game.save();

      return game;
    } catch (error) {
      logger.error(`Error creating game: ${error.message}`);
      throw new ErrorResponse('Failed to create game', 500);
    }
  },

  /**
   * Join an existing game
   * @param {string} gameCode - Game code
   * @param {string} userId - User ID of the joining player
   * @returns {Object} Updated game
   */
  joinGame: async (gameCode, userId) => {
    try {
      // Find the game
      const game = await Game.findOne({ gameCode });

      if (!game) {
        throw new ErrorResponse('Game not found', 404);
      }

      // Check if game already has two players
      if (game.players.player2 && game.players.player2.user) {
        throw new ErrorResponse('Game is already full', 400);
      }

      // Check if game is in waiting status
      if (game.status !== GAME_STATUS.WAITING) {
        throw new ErrorResponse('Game is not in waiting status', 400);
      }

      // Check if current user is already player1
      if (game.players.player1.user.toString() === userId) {
        throw new ErrorResponse('You are already in this game', 400);
      }

      // Add current user as player2
      game.players.player2 = {
        user: userId
      };

      // Set game to active
      game.status = GAME_STATUS.ACTIVE;
      game.startedAt = new Date();

      // Add first round with a random question
      const question = await gameService.getRandomQuestion(game.difficulty, game.subject);
      if (!question) {
        throw new ErrorResponse('No questions available', 500);
      }

      game.rounds.push({
        roundNumber: 1,
        question: question._id
      });

      await game.save();

      return game;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }

      logger.error(`Error joining game: ${error.message}`);
      throw new ErrorResponse('Failed to join game', 500);
    }
  },

  /**
   * Get a filtered game state for a specific player
   * @param {string} gameCode - Game code
   * @param {string} userId - User ID
   * @returns {Object} Filtered game state
   */
  getGameState: async (gameCode, userId) => {
    try {
      // Find the game and populate question data
      const game = await Game.findOne({ gameCode })
        .populate('rounds.question')
        .populate('players.player1.user', 'username avatar')
        .populate('players.player2.user', 'username avatar');

      if (!game) {
        throw new ErrorResponse('Game not found', 404);
      }

      // Check if user is a player in this game
      let playerType = null;
      if (game.players.player1.user._id.toString() === userId) {
        playerType = PLAYER_TYPES.PLAYER1;
      } else if (game.players.player2.user && game.players.player2.user._id.toString() === userId) {
        playerType = PLAYER_TYPES.PLAYER2;
      }

      if (!playerType) {
        throw new ErrorResponse('You are not a player in this game', 403);
      }

      // Get filtered game state for this player
      return game.getStateForPlayer(playerType);
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }

      logger.error(`Error getting game state: ${error.message}`);
      throw new ErrorResponse('Failed to get game state', 500);
    }
  },

  /**
   * Process an answer submission
   * @param {string} gameCode - Game code
   * @param {string} userId - User ID
   * @param {string} answer - Submitted answer
   * @param {number} timeElapsed - Time taken to answer in seconds
   * @returns {Object} Result of submission
   */
  submitAnswer: async (gameCode, userId, answer, timeElapsed) => {
    try {
      // Find the game
      const game = await Game.findOne({ gameCode })
        .populate('rounds.question');

      if (!game) {
        throw new ErrorResponse('Game not found', 404);
      }

      // Determine player type
      let playerType = null;
      if (game.players.player1.user.toString() === userId) {
        playerType = PLAYER_TYPES.PLAYER1;
      } else if (game.players.player2.user.toString() === userId) {
        playerType = PLAYER_TYPES.PLAYER2;
      }

      if (!playerType) {
        throw new ErrorResponse('You are not a player in this game', 403);
      }

      // Check if it's the player's turn
      if (game.currentTurn !== playerType) {
        throw new ErrorResponse('It is not your turn', 400);
      }

      // Get current round
      const currentRoundIndex = game.currentRound - 1;
      if (currentRoundIndex >= game.rounds.length) {
        throw new ErrorResponse('Round not found', 404);
      }

      const round = game.rounds[currentRoundIndex];

      // Check if already answered
      if (round[`${playerType}Answer`]) {
        throw new ErrorResponse('You have already answered this round', 400);
      }

      // Get question and check if answer is correct
      const question = round.question;
      const isCorrect = gameService.checkAnswer(question, answer);

      // Record the answer
      await game.submitAnswer(playerType, answer, timeElapsed);

      // Update the correctness of the answer
      round[`${playerType}Answer`].isCorrect = isCorrect;

      // Update question usage statistics
      await question.updateUsageStats(isCorrect, timeElapsed);

      // Update user's last activity
      game.players[playerType].lastActivity = new Date();

      // Check if both players have answered
      const bothAnswered =
        round.player1Answer &&
        round.player2Answer;

      let roundComplete = false;
      let roundWinner = null;

      if (bothAnswered) {
        // Evaluate the round
        await game.evaluateRound();
        roundComplete = true;
        roundWinner = round.winner;

        // If game is completed, update user stats
        if (game.status === GAME_STATUS.COMPLETED) {
          await gameService.updateUserStats(game);
        }
      } else {
        // Switch turns
        game.currentTurn = playerType === PLAYER_TYPES.PLAYER1 ? PLAYER_TYPES.PLAYER2 : PLAYER_TYPES.PLAYER1;
        await game.save();
      }

      return {
        isCorrect,
        roundComplete,
        roundWinner,
        gameState: game.getStateForPlayer(playerType),
        gameCompleted: game.status === GAME_STATUS.COMPLETED
      };
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }

      logger.error(`Error submitting answer: ${error.message}`);
      throw new ErrorResponse('Failed to submit answer', 500);
    }
  },

  /**
   * Check if an answer is correct for a given question
   * @param {Object} question - Question object
   * @param {string} answer - Answer to check
   * @returns {boolean} Whether the answer is correct
   */
  checkAnswer: (question, answer) => {
    // For multiple-choice questions
    if (question.type === 'multiple-choice') {
      return answer === question.correctAnswer;
    }

    // For numeric questions, allow for slight rounding differences
    if (question.type === 'numeric') {
      // Try to parse both as numbers
      const numericAnswer = parseFloat(answer.replace(/\s/g, ''));
      const correctAnswer = parseFloat(question.correctAnswer.replace(/\s/g, ''));

      if (isNaN(numericAnswer) || isNaN(correctAnswer)) {
        return answer.trim() === question.correctAnswer.trim();
      }

      // Allow for a small margin of error for floating point comparisons
      const epsilon = 0.0001;
      return Math.abs(numericAnswer - correctAnswer) < epsilon;
    }

    // For text answers, ignore case and whitespace
    return answer.trim().toLowerCase() === question.correctAnswer.trim().toLowerCase();
  },

  /**
   * Get a random question based on criteria
   * @param {string} difficulty - Difficulty level
   * @param {string} subject - Subject area
   * @param {Array} excludeIds - Question IDs to exclude
   * @returns {Object} Random question
   */
  getRandomQuestion: async (difficulty, subject, excludeIds = []) => {
    try {
      // Build query
      const query = { isActive: true };

      if (difficulty && difficulty !== 'mixed') {
        query.difficulty = difficulty;
      }

      if (subject && subject !== 'mixed') {
        query.subject = subject;
      }

      // Exclude specific questions
      if (excludeIds.length > 0) {
        query._id = { $nin: excludeIds };
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
    } catch (error) {
      logger.error(`Error getting random question: ${error.message}`);
      return null;
    }
  },

  /**
   * Update user statistics after a game is completed
   * @param {Object} game - Completed game
   */
  updateUserStats: async (game) => {
    try {
      if (game.status !== GAME_STATUS.COMPLETED) {
        return;
      }

      const { player1, player2 } = game.players;
      const player1User = await User.findById(player1.user);
      const player2User = await User.findById(player2.user);

      if (!player1User || !player2User) {
        logger.error(`Missing users for game ${game.gameCode}`);
        return;
      }

      // Calculate game statistics for each player
      const player1Correct = game.rounds.reduce((count, round) => {
        return count + (round.player1Answer?.isCorrect ? 1 : 0);
      }, 0);

      const player2Correct = game.rounds.reduce((count, round) => {
        return count + (round.player2Answer?.isCorrect ? 1 : 0);
      }, 0);

      const player1AvgTime = game.rounds.reduce((sum, round) => {
        return sum + (round.player1Answer?.timeElapsed || 0);
      }, 0) / game.rounds.length;

      const player2AvgTime = game.rounds.reduce((sum, round) => {
        return sum + (round.player2Answer?.timeElapsed || 0);
      }, 0) / game.rounds.length;

      // Update player 1 stats
      await player1User.updateStats({
        isWinner: game.winner === PLAYER_TYPES.PLAYER1,
        correctAnswers: player1Correct,
        averageResponseTime: player1AvgTime,
        pointsEarned: player1Correct * 10 + (game.winner === PLAYER_TYPES.PLAYER1 ? 50 : 0)
      });

      // Update player 2 stats
      await player2User.updateStats({
        isWinner: game.winner === PLAYER_TYPES.PLAYER2,
        correctAnswers: player2Correct,
        averageResponseTime: player2AvgTime,
        pointsEarned: player2Correct * 10 + (game.winner === PLAYER_TYPES.PLAYER2 ? 50 : 0)
      });
    } catch (error) {
      logger.error(`Error updating user stats: ${error.message}`);
    }
  },

  /**
   * Abandon a game
   * @param {string} gameCode - Game code
   * @param {string} userId - User ID
   * @returns {Object} Updated game
   */
  abandonGame: async (gameCode, userId) => {
    try {
      // Find the game
      const game = await Game.findOne({ gameCode });

      if (!game) {
        throw new ErrorResponse('Game not found', 404);
      }

      // Check if user is a player in this game
      let playerType = null;
      if (game.players.player1.user.toString() === userId) {
        playerType = PLAYER_TYPES.PLAYER1;
      } else if (game.players.player2.user?.toString() === userId) {
        playerType = PLAYER_TYPES.PLAYER2;
      }

      if (!playerType) {
        throw new ErrorResponse('You are not a player in this game', 403);
      }

      // Can only abandon active or paused games
      if (!['active', 'paused', 'waiting'].includes(game.status)) {
        throw new ErrorResponse(`Cannot abandon a game with status: ${game.status}`, 400);
      }

      // Mark game as abandoned
      game.status = GAME_STATUS.ABANDONED;
      await game.save();

      return game;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }

      logger.error(`Error abandoning game: ${error.message}`);
      throw new ErrorResponse('Failed to abandon game', 500);
    }
  },

  /**
   * Get active games for a user
   * @param {string} userId - User ID
   * @returns {Array} Active games
   */
  getActiveGames: async (userId) => {
    try {
      // Find all active games where user is a player
      return await Game.find({
        $or: [
          { 'players.player1.user': userId },
          { 'players.player2.user': userId }
        ],
        status: { $in: [GAME_STATUS.WAITING, GAME_STATUS.ACTIVE, GAME_STATUS.PAUSED] }
      })
        .select('gameCode status currentRound players.player1.user players.player2.user createdAt')
        .populate('players.player1.user', 'username avatar')
        .populate('players.player2.user', 'username avatar');
    } catch (error) {
      logger.error(`Error getting active games: ${error.message}`);
      throw new ErrorResponse('Failed to get active games', 500);
    }
  },

  /**
   * Get game history for a user
   * @param {string} userId - User ID
   * @param {number} limit - Number of games to return
   * @returns {Array} Game history
   */
  getGameHistory: async (userId, limit = 10) => {
    try {
      // Find all completed games where user is a player
      return await Game.find({
        $or: [
          { 'players.player1.user': userId },
          { 'players.player2.user': userId }
        ],
        status: GAME_STATUS.COMPLETED
      })
        .sort({ completedAt: -1 })
        .limit(limit)
        .populate('players.player1.user', 'username avatar')
        .populate('players.player2.user', 'username avatar');
    } catch (error) {
      logger.error(`Error getting game history: ${error.message}`);
      throw new ErrorResponse('Failed to get game history', 500);
    }
  },

  /**
   * Clean up abandoned games
   * Utility method to mark old games as abandoned
   */
  cleanupAbandonedGames: async () => {
    try {
      const timeoutThreshold = new Date();
      timeoutThreshold.setHours(timeoutThreshold.getHours() - 24);

      // Find games that haven't been updated in 24 hours
      const abandonedGames = await Game.updateMany(
        {
          status: { $in: [GAME_STATUS.WAITING, GAME_STATUS.ACTIVE, GAME_STATUS.PAUSED] },
          updatedAt: { $lt: timeoutThreshold }
        },
        {
          $set: { status: GAME_STATUS.ABANDONED }
        }
      );

      logger.info(`Cleaned up ${abandonedGames.modifiedCount} abandoned games`);
    } catch (error) {
      logger.error(`Error cleaning up abandoned games: ${error.message}`);
    }
  },


  /**
 * Create a new game with challenge info
 * @param {string} challengerId - User ID of the challenger
 * @param {string} challengedId - User ID of the challenged player
 * @param {Object} options - Game options
 * @returns {Object} Created game
 */
  createChallengeGame: async (challengerId, challengedId, options = {}) => {
    try {
      // Generate a unique game code
      let gameCode;
      let codeExists = true;

      while (codeExists) {
        gameCode = Game.generateGameCode();
        codeExists = await Game.findOne({ gameCode });
      }

      // Create game with challenge information
      const game = new Game({
        gameCode,
        players: {
          player1: {
            user: challengerId
          }
        },
        status: 'waiting',
        challengeInfo: {
          challenger: challengerId,
          challenged: challengedId,
          status: 'pending'
        },
        ...(options.difficulty && { difficulty: options.difficulty }),
        ...(options.subject && { subject: options.subject }),
        ...(options.maxRounds && { maxRounds: options.maxRounds }),
        ...(options.winningScore && { winningScore: options.winningScore })
      });

      await game.save();

      return game;
    } catch (error) {
      logger.error(`Error creating challenge game: ${error.message}`);
      throw new ErrorResponse('Failed to create challenge game', 500);
    }
  },

  /**
   * Respond to a game challenge
   * @param {string} gameCode - Game code
   * @param {string} userId - User ID of the responder
   * @param {string} response - Response (accept/reject)
   * @returns {Object} Updated game info
   */
  respondToChallenge: async (gameCode, userId, response) => {
    try {
      // Find the game
      const game = await Game.findOne({
        gameCode,
        'challengeInfo.challenged': userId,
        'challengeInfo.status': 'pending'
      });

      if (!game) {
        throw new ErrorResponse('Challenge not found or already responded to', 404);
      }

      if (response === 'accept') {
        // Add user as player2
        game.players.player2 = {
          user: userId
        };

        // Update challenge status
        game.challengeInfo.status = 'accepted';

        // Set game to active
        game.status = 'active';
        game.startedAt = new Date();

        // Add first round with a random question
        const question = await gameService.getRandomQuestion(game.difficulty, game.subject);
        if (!question) {
          throw new ErrorResponse('No questions available', 500);
        }

        game.rounds.push({
          roundNumber: 1,
          question: question._id
        });
      } else {
        // Update challenge status to rejected
        game.challengeInfo.status = 'rejected';
      }

      await game.save();

      return {
        gameCode: game.gameCode,
        status: game.challengeInfo.status,
        challengerId: game.challengeInfo.challenger
      };
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }

      logger.error(`Error responding to challenge: ${error.message}`);
      throw new ErrorResponse('Failed to respond to challenge', 500);
    }
  },

  /**
   * Get all challenges for a user
   * @param {string} userId - User ID
   * @returns {Object} Sent and received challenges
   */
  getUserChallenges: async (userId) => {
    try {
      // Find sent challenges
      const sentChallenges = await Game.find({
        'challengeInfo.challenger': userId,
        'challengeInfo.status': { $in: ['pending', 'accepted', 'rejected'] }
      })
        .populate('challengeInfo.challenged', 'username avatar')
        .select('gameCode challengeInfo createdAt');

      // Find received challenges
      const receivedChallenges = await Game.find({
        'challengeInfo.challenged': userId,
        'challengeInfo.status': { $in: ['pending', 'accepted', 'rejected'] }
      })
        .populate('challengeInfo.challenger', 'username avatar')
        .select('gameCode challengeInfo createdAt');

      return {
        sent: sentChallenges,
        received: receivedChallenges
      };
    } catch (error) {
      logger.error(`Error getting user challenges: ${error.message}`);
      throw new ErrorResponse('Failed to get challenges', 500);
    }
  },
};

export default gameService;