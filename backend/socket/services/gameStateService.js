// socket/services/gameStateService.js - Fixed Game State Service
import Game from '../../models/Game.js';
import mongoose from 'mongoose';
import Question from '../../models/Question.js';
import logger from '../../utils/logger.js';

/**
 * Process a player's answer submission
 * @param {string} gameCode - Game code
 * @param {string} userId - User ID
 * @param {string} answer - Answer submitted by the player
 * @param {number} timeElapsed - Time taken to answer in seconds
 * @returns {Object} Result of the answer processing
 */
const processAnswer = async (gameCode, userId, answer, timeElapsed) => {
  try {
    // Find the game and populate question data
    const game = await Game.findOne({ gameCode })
      .populate('rounds.question');
    
    if (!game) {
      return { error: 'Game not found' };
    }
    
    // Check game status
    if (game.status !== 'active') {
      return { error: 'Game is not active' };
    }
    
    // Determine player type
    let playerType = null;
    if (game.players.player1.user.toString() === userId.toString()) {
      playerType = 'player1';
    } else if (game.players.player2.user.toString() === userId.toString()) {
      playerType = 'player2';
    }
    
    if (!playerType) {
      return { error: 'You are not a player in this game' };
    }
    
    // Check if it's this player's turn
    if (game.currentTurn !== playerType) {
      return { error: 'It is not your turn' };
    }
    
    // Get current round
    const currentRoundIndex = game.currentRound - 1;
    if (currentRoundIndex < 0 || currentRoundIndex >= game.rounds.length) {
      return { error: `Round not found: ${game.currentRound}` };
    }
    
    const round = game.rounds[currentRoundIndex];
    
    // Check if already answered
    if (round[`${playerType}Answer`] && round[`${playerType}Answer`].answer) {
      return { error: 'You have already answered this round' };
    }

    logger.debug(`Processing answer for gameCode=${gameCode}, player=${playerType}:`, { answer, timeElapsed });
    
    let isCorrect = false;
    let roundComplete = false;
    let roundWinner = null;
    
    try {
      // Record the answer directly in the game document
      round[`${playerType}Answer`] = {
        answer: answer,
        timeElapsed: timeElapsed,
        answeredAt: new Date()
      };
      
      // Check if the answer is correct
      const question = round.question;
      if (question) {
        // If question is a populated document
        if (typeof question !== 'string' && question._id) {
          // For multiple-choice questions
          if (question.type === 'multiple-choice') {
            isCorrect = answer === question.correctAnswer;
          }
          // For numeric questions
          else if (question.type === 'numeric') {
            const numericAnswer = parseFloat(String(answer).replace(/\s/g, ''));
            const correctAnswer = parseFloat(String(question.correctAnswer).replace(/\s/g, ''));
            
            if (!isNaN(numericAnswer) && !isNaN(correctAnswer)) {
              isCorrect = Math.abs(numericAnswer - correctAnswer) < 0.0001;
            } else {
              isCorrect = String(answer).trim() === String(question.correctAnswer).trim();
            }
          }
          // For text answers
          else {
            isCorrect = String(answer).trim().toLowerCase() === String(question.correctAnswer).trim().toLowerCase();
          }
          
          // Update the question usage stats if possible
          try {
            if (typeof question.updateUsageStats === 'function') {
              await question.updateUsageStats(isCorrect, timeElapsed);
            }
          } catch (statsError) {
            logger.error(`Error updating question stats: ${statsError.message}`);
          }
        }
        // If question is just an ID reference
        else {
          try {
            // Fetch the question
            const Question = mongoose.model('Question');
            const fullQuestion = await Question.findById(question);
            
            if (fullQuestion) {
              // For multiple-choice questions
              if (fullQuestion.type === 'multiple-choice') {
                isCorrect = answer === fullQuestion.correctAnswer;
              }
              // For numeric questions
              else if (fullQuestion.type === 'numeric') {
                const numericAnswer = parseFloat(String(answer).replace(/\s/g, ''));
                const correctAnswer = parseFloat(String(fullQuestion.correctAnswer).replace(/\s/g, ''));
                
                if (!isNaN(numericAnswer) && !isNaN(correctAnswer)) {
                  isCorrect = Math.abs(numericAnswer - correctAnswer) < 0.0001;
                } else {
                  isCorrect = String(answer).trim() === String(fullQuestion.correctAnswer).trim();
                }
              }
              // For text answers
              else {
                isCorrect = String(answer).trim().toLowerCase() === String(fullQuestion.correctAnswer).trim().toLowerCase();
              }
              
              // Update the question usage stats
              try {
                await fullQuestion.updateUsageStats(isCorrect, timeElapsed);
              } catch (statsError) {
                logger.error(`Error updating question stats: ${statsError.message}`);
              }
            } else {
              logger.error(`Question not found with id: ${question}`);
              isCorrect = false;
            }
          } catch (questionError) {
            logger.error(`Error getting question: ${questionError.message}`);
            isCorrect = false;
          }
        }
      } else {
        logger.error('Question not found in round');
        isCorrect = false;
      }
      
      // Set the correctness
      round[`${playerType}Answer`].isCorrect = isCorrect;
      
      // Update the player's last activity
      game.players[playerType].lastActivity = new Date();
      
      // Check if both players have answered
      const bothAnswered = round.player1Answer && round.player2Answer;
      
      if (bothAnswered) {
        // Evaluate the round
        // Determine winner based on correctness and time
        const player1Correct = round.player1Answer.isCorrect;
        const player2Correct = round.player2Answer.isCorrect;
        
        if (player1Correct && !player2Correct) {
          round.winner = 'player1';
          game.players.player1.score += 1;
        } else if (!player1Correct && player2Correct) {
          round.winner = 'player2';
          game.players.player2.score += 1;
        } else if (player1Correct && player2Correct) {
          // Both correct, faster player wins
          if (round.player1Answer.timeElapsed < round.player2Answer.timeElapsed) {
            round.winner = 'player1';
            game.players.player1.score += 1;
          } else if (round.player2Answer.timeElapsed < round.player1Answer.timeElapsed) {
            round.winner = 'player2';
            game.players.player2.score += 1;
          } else {
            // Exactly the same time (very unlikely) - tie
            round.winner = 'tie';
          }
        } else {
          // Both incorrect - tie
          round.winner = 'tie';
        }
        
        // Mark the round as complete
        round.roundComplete = true;
        roundComplete = true;
        roundWinner = round.winner;
        
        // Check if the game is over
        if (game.players.player1.score >= game.winningScore) {
          game.winner = 'player1';
          game.status = 'completed';
          game.completedAt = new Date();
        } else if (game.players.player2.score >= game.winningScore) {
          game.winner = 'player2';
          game.status = 'completed';
          game.completedAt = new Date();
        } else if (game.status === 'active') {
          // If game not over, prepare for next round
          if (game.currentRound < game.maxRounds) {
            try {
              // Set the turn to the opposite of the current round winner
              game.currentTurn = round.winner === 'player1' ? 'player2' : 'player1';
              
              // If tie, alternate from the current turn
              if (round.winner === 'tie') {
                game.currentTurn = game.currentTurn === 'player1' ? 'player2' : 'player1';
              }
              
              // Get a new question for the next round
              const query = { isActive: true };
              
              if (game.difficulty && game.difficulty !== 'mixed') {
                query.difficulty = game.difficulty;
              }
              
              if (game.subject && game.subject !== 'mixed') {
                query.subject = game.subject;
              }
              
              // Exclude questions already used
              const usedQuestionIds = game.rounds.map(r => 
                typeof r.question === 'string' ? r.question : r.question._id.toString()
              );
              
              if (usedQuestionIds.length > 0) {
                query._id = { $nin: usedQuestionIds };
              }
              
              // Count matching questions
              const count = await Question.countDocuments(query);
              
              if (count === 0) {
                // If no new questions available, use any question
                delete query._id;
                const fallbackCount = await Question.countDocuments({ isActive: true });
                
                if (fallbackCount === 0) {
                  throw new Error('No questions available');
                }
                
                const random = Math.floor(Math.random() * fallbackCount);
                const question = await Question.findOne({ isActive: true }).skip(random);
                
                // Increment round counter
                game.currentRound += 1;
                
                // Add new round
                game.rounds.push({
                  roundNumber: game.currentRound,
                  question: question._id
                });
              } else {
                // Get a random question
                const random = Math.floor(Math.random() * count);
                const question = await Question.findOne(query).skip(random);
                
                // Increment round counter
                game.currentRound += 1;
                
                // Add new round
                game.rounds.push({
                  roundNumber: game.currentRound,
                  question: question._id
                });
              }
            } catch (error) {
              logger.error(`Error selecting next question: ${error.message}`);
              
              // If we can't get a new question, end the game
              if (game.players.player1.score > game.players.player2.score) {
                game.winner = 'player1';
              } else if (game.players.player2.score > game.players.player1.score) {
                game.winner = 'player2';
              } else {
                // Tie game
                game.winner = null;
              }
              
              game.status = 'completed';
              game.completedAt = new Date();
            }
          } else {
            // If we've reached max rounds, determine the winner by score
            if (game.players.player1.score > game.players.player2.score) {
              game.winner = 'player1';
            } else if (game.players.player2.score > game.players.player1.score) {
              game.winner = 'player2';
            } else {
              // Tie game
              game.winner = null;
            }
            
            game.status = 'completed';
            game.completedAt = new Date();
          }
        }
      } else {
        // If the other player hasn't answered yet, switch turns
        game.currentTurn = playerType === 'player1' ? 'player2' : 'player1';
      }
      
      // Save the game
      await game.save();
      
      return {
        success: true,
        isCorrect,
        roundComplete,
        roundWinner,
        game
      };
    } catch (processError) {
      logger.error(`Error processing answer: ${processError.message}`);
      return { error: `Error processing answer: ${processError.message}` };
    }
  } catch (error) {
    logger.error(`Error in processAnswer: ${error.message}`);
    return { error: `Failed to process answer: ${error.message}` };
  }
};

/**
 * Get the current state of a game for all players
 * @param {string} gameCode - Game code
 * @returns {Object} Game states for each player
 */
const getGameStates = async (gameCode) => {
  try {
    // Find the game and populate relevant data
    const game = await Game.findOne({ gameCode })
      .populate('rounds.question')
      .populate('players.player1.user', 'username avatar')
      .populate('players.player2.user', 'username avatar');
    
    if (!game) {
      return { error: 'Game not found' };
    }
    
    // Get states for both players
    const player1State = game.getStateForPlayer('player1');
    const player2State = game.getStateForPlayer('player2');
    
    return { 
      success: true, 
      player1State, 
      player2State 
    };
  } catch (error) {
    logger.error(`Error getting game states: ${error.message}`);
    return { error: 'Failed to get game states' };
  }
};

/**
 * Get the current state of a game for a specific player
 * @param {string} gameCode - Game code
 * @param {string} userId - User ID
 * @returns {Object} Game state for the player
 */
const getGameState = async (gameCode, userId) => {
  try {
    // Find the game and populate relevant data
    const game = await Game.findOne({ gameCode })
      .populate('rounds.question')
      .populate('players.player1.user', 'username avatar')
      .populate('players.player2.user', 'username avatar');
    
    if (!game) {
      return { error: 'Game not found' };
    }
    
    // Determine player type
    let playerType = null;
    if (game.players.player1.user._id.toString() === userId.toString()) {
      playerType = 'player1';
    } else if (game.players.player2?.user?._id.toString() === userId.toString()) {
      playerType = 'player2';
    }
    
    if (!playerType) {
      return { error: 'You are not a player in this game' };
    }
    
    // Get game state for this player
    const gameState = game.getStateForPlayer(playerType);
    
    return { success: true, gameState };
  } catch (error) {
    logger.error(`Error getting game state: ${error.message}`);
    return { error: 'Failed to get game state' };
  }
};

export default {
  processAnswer,
  getGameState,
  getGameStates
};