// socket/events/gameEvents.js - Simplified Game Socket Events
import logger from '../../utils/logger.js';
import Game from '../../models/Game.js';
import mongoose from 'mongoose';
import { SOCKET_EVENTS } from '../../utils/constants.js';

/**
 * Set up game-related socket events
 * @param {Object} io - Socket.io server instance
 * @param {Object} socket - Socket.io socket
 */
const setupGameEvents = (io, socket) => {
  const userId = socket.user?._id;

  // Join game room
  socket.on(SOCKET_EVENTS.GAME_JOIN, async ({ gameCode }) => {
    try {
      if (!gameCode) {
        return socket.emit('error', { message: 'Game code is required' });
      }

      logger.debug(`User ${userId} joining game ${gameCode}`);

      // Find game by code
      const game = await Game.findOne({ gameCode }).populate('rounds.question');

      if (!game) {
        return socket.emit('error', { message: 'Game not found' });
      }

      // Join the game room
      socket.join(`game:${gameCode}`);
      logger.debug(`Socket ${socket.id} joined game room: ${gameCode}`);

      // Determine if this user is player1 or player2
      let playerType = null;
      if (game.players.player1.user.toString() === userId?.toString()) {
        playerType = 'player1';
      } else if (game.players.player2?.user && game.players.player2.user.toString() === userId?.toString()) {
        playerType = 'player2';
      }

      // Update connection status
      if (playerType) {
        game.players[playerType].connected = true;
        game.players[playerType].lastActivity = new Date();
        await game.save();

        // Notify other player about connection
        io.to(`game:${gameCode}`).emit(SOCKET_EVENTS.GAME_PLAYER_CONNECTED, { playerType });
      }

      // Get game state for this player
      let gameState;
      try {
        gameState = playerType ? game.getStateForPlayer(playerType) : { gameCode, status: game.status };
      } catch (stateError) {
        logger.error(`Error getting game state: ${stateError.message}`);
        gameState = { gameCode, status: game.status, error: 'Error getting game state' };
      }

      // Send game state to the client
      socket.emit(SOCKET_EVENTS.GAME_STATE, gameState);
    } catch (error) {
      logger.error(`Error in game:join: ${error.message}`);
      socket.emit('error', { message: 'Failed to join game' });
    }
  });

  // Submit answer
  socket.on(SOCKET_EVENTS.GAME_SUBMIT_ANSWER, async ({ gameCode, answer, timeElapsed }) => {
    try {
      if (!gameCode || answer === undefined || timeElapsed === undefined) {
        return socket.emit('error', { message: 'Invalid submission data' });
      }

      if (!userId) {
        return socket.emit('error', { message: 'Authentication required' });
      }

      logger.debug(`User ${userId} submitting answer in game ${gameCode}: ${answer}, time: ${timeElapsed}`);

      // Find the game
      const game = await Game.findOne({ gameCode }).populate('rounds.question');
      
      if (!game) {
        return socket.emit('error', { message: 'Game not found' });
      }
      
      // Determine player type
      let playerType = null;
      if (game.players.player1.user.toString() === userId.toString()) {
        playerType = 'player1';
      } else if (game.players.player2?.user && game.players.player2.user.toString() === userId.toString()) {
        playerType = 'player2';
      }
      
      if (!playerType) {
        return socket.emit('error', { message: 'You are not a player in this game' });
      }
      
      // Check if it's the player's turn
      if (game.currentTurn !== playerType) {
        return socket.emit('error', { message: 'It is not your turn' });
      }
      
      // Get the current round
      const currentRoundIndex = game.currentRound - 1;
      if (currentRoundIndex < 0 || currentRoundIndex >= game.rounds.length) {
        return socket.emit('error', { message: `Invalid round: ${game.currentRound}` });
      }
      
      const round = game.rounds[currentRoundIndex];
      
      // Check if already answered
      if (round[`${playerType}Answer`] && round[`${playerType}Answer`].answer) {
        return socket.emit('error', { message: 'You have already answered this round' });
      }
      
      try {
        // Record the answer
        let isCorrect = false;
        const question = round.question;
        
        // Record the answer directly
        round[`${playerType}Answer`] = {
          answer: answer,
          timeElapsed: timeElapsed,
          answeredAt: new Date()
        };
        
        // Check if the answer is correct
        if (question) {
          if (typeof question !== 'string' && question._id) {
            // Multiple-choice
            if (question.type === 'multiple-choice') {
              isCorrect = answer === question.correctAnswer;
            }
            // Numeric
            else if (question.type === 'numeric') {
              const numericAnswer = parseFloat(String(answer).replace(/\s/g, ''));
              const correctAnswer = parseFloat(String(question.correctAnswer).replace(/\s/g, ''));
              
              if (!isNaN(numericAnswer) && !isNaN(correctAnswer)) {
                isCorrect = Math.abs(numericAnswer - correctAnswer) < 0.0001;
              } else {
                isCorrect = String(answer).trim() === String(question.correctAnswer).trim();
              }
            }
            // Text
            else {
              isCorrect = String(answer).trim().toLowerCase() === String(question.correctAnswer).trim().toLowerCase();
            }
            
            // Update question stats if possible
            try {
              if (typeof question.updateUsageStats === 'function') {
                await question.updateUsageStats(isCorrect, timeElapsed);
              }
            } catch (statsError) {
              logger.error(`Error updating question stats: ${statsError.message}`);
            }
          } else {
            // Question is not populated, need to fetch it
            try {
              const Question = mongoose.model('Question');
              const fullQuestion = await Question.findById(question);
              
              if (fullQuestion) {
                // Multiple-choice
                if (fullQuestion.type === 'multiple-choice') {
                  isCorrect = answer === fullQuestion.correctAnswer;
                }
                // Numeric
                else if (fullQuestion.type === 'numeric') {
                  const numericAnswer = parseFloat(String(answer).replace(/\s/g, ''));
                  const correctAnswer = parseFloat(String(fullQuestion.correctAnswer).replace(/\s/g, ''));
                  
                  if (!isNaN(numericAnswer) && !isNaN(correctAnswer)) {
                    isCorrect = Math.abs(numericAnswer - correctAnswer) < 0.0001;
                  } else {
                    isCorrect = String(answer).trim() === String(fullQuestion.correctAnswer).trim();
                  }
                }
                // Text
                else {
                  isCorrect = String(answer).trim().toLowerCase() === String(fullQuestion.correctAnswer).trim().toLowerCase();
                }
                
                // Update stats
                try {
                  await fullQuestion.updateUsageStats(isCorrect, timeElapsed);
                } catch (statsError) {
                  logger.error(`Error updating question stats: ${statsError.message}`);
                }
              }
            } catch (questionError) {
              logger.error(`Error getting question: ${questionError.message}`);
            }
          }
        }
        
        // Set the correctness
        round[`${playerType}Answer`].isCorrect = isCorrect;
        
        // Check if both players have answered
        const bothAnswered = round.player1Answer && round.player2Answer;
        let roundComplete = false;
        let roundWinner = null;
        
        if (bothAnswered) {
          // Evaluate round
          const player1Correct = round.player1Answer.isCorrect;
          const player2Correct = round.player2Answer.isCorrect;
          
          if (player1Correct && !player2Correct) {
            round.winner = 'player1';
            game.players.player1.score += 1;
          } else if (!player1Correct && player2Correct) {
            round.winner = 'player2';
            game.players.player2.score += 1;
          } else if (player1Correct && player2Correct) {
            if (round.player1Answer.timeElapsed < round.player2Answer.timeElapsed) {
              round.winner = 'player1';
              game.players.player1.score += 1;
            } else if (round.player2Answer.timeElapsed < round.player1Answer.timeElapsed) {
              round.winner = 'player2';
              game.players.player2.score += 1;
            } else {
              round.winner = 'tie';
            }
          } else {
            round.winner = 'tie';
          }
          
          round.roundComplete = true;
          roundComplete = true;
          roundWinner = round.winner;
          
          // Check if game is over
          if (game.players.player1.score >= game.winningScore) {
            game.winner = 'player1';
            game.status = 'completed';
            game.completedAt = new Date();
          } else if (game.players.player2.score >= game.winningScore) {
            game.winner = 'player2';
            game.status = 'completed';
            game.completedAt = new Date();
          } else if (game.currentRound >= game.maxRounds) {
            // Game ended by max rounds
            if (game.players.player1.score > game.players.player2.score) {
              game.winner = 'player1';
            } else if (game.players.player2.score > game.players.player1.score) {
              game.winner = 'player2';
            }
            
            game.status = 'completed';
            game.completedAt = new Date();
          } else {
            // Continue with next round
            try {
              // Switch turns based on who won
              game.currentTurn = round.winner === 'player1' ? 'player2' : 'player1';
              
              // If tie, alternate from current turn
              if (round.winner === 'tie') {
                game.currentTurn = game.currentTurn === 'player1' ? 'player2' : 'player1';
              }
              
              // Find a new question
              const Question = mongoose.model('Question');
              const randomQuestion = await Question.findOne({ isActive: true }).skip(
                Math.floor(Math.random() * await Question.countDocuments({ isActive: true }))
              );
              
              if (randomQuestion) {
                // Increment round
                game.currentRound += 1;
                
                // Add new round
                game.rounds.push({
                  roundNumber: game.currentRound,
                  question: randomQuestion._id
                });
              } else {
                logger.error('No questions available');
                
                // End the game if no questions
                if (game.players.player1.score > game.players.player2.score) {
                  game.winner = 'player1';
                } else if (game.players.player2.score > game.players.player1.score) {
                  game.winner = 'player2';
                }
                
                game.status = 'completed';
                game.completedAt = new Date();
              }
            } catch (nextRoundError) {
              logger.error(`Error setting up next round: ${nextRoundError.message}`);
              
              // End the game if error
              if (game.players.player1.score > game.players.player2.score) {
                game.winner = 'player1';
              } else if (game.players.player2.score > game.players.player1.score) {
                game.winner = 'player2';
              }
              
              game.status = 'completed';
              game.completedAt = new Date();
            }
          }
        } else {
          // Switch turns if the other player hasn't answered
          game.currentTurn = playerType === 'player1' ? 'player2' : 'player1';
        }
        
        // Save the game
        await game.save();
        
        // Re-fetch the game after saving to ensure we have latest data
        const updatedGame = await Game.findOne({ gameCode }).populate('rounds.question');
        
        // Get the player states
        let player1State, player2State;
        try {
          player1State = updatedGame.getStateForPlayer('player1');
          player2State = updatedGame.getStateForPlayer('player2');
        } catch (stateError) {
          logger.error(`Error getting player states: ${stateError.message}`);
        }
        
        // Send answer processed confirmation
        socket.emit(SOCKET_EVENTS.GAME_ANSWER_PROCESSED, playerType === 'player1' ? player1State : player2State);
        
        // Notify the other player if it's their turn
        const otherPlayerType = playerType === 'player1' ? 'player2' : 'player1';
        const otherPlayerId = updatedGame.players[otherPlayerType]?.user;
        
        if (updatedGame.status === 'active' && updatedGame.currentTurn === otherPlayerType && otherPlayerId) {
          io.to(`user:${otherPlayerId.toString()}`).emit(SOCKET_EVENTS.GAME_YOUR_TURN, {
            gameCode,
            currentRound: updatedGame.currentRound
          });
          
          // Also send the updated game state
          io.to(`user:${otherPlayerId.toString()}`).emit(SOCKET_EVENTS.GAME_STATE, 
            otherPlayerType === 'player1' ? player1State : player2State
          );
        }
        
        // If round is complete, notify both players
        if (roundComplete) {
          io.to(`game:${gameCode}`).emit(SOCKET_EVENTS.GAME_ROUND_COMPLETE, {
            roundNumber: updatedGame.currentRound - 1,
            winner: roundWinner
          });
        }
        
        // If game is complete, notify both players
        if (updatedGame.status === 'completed') {
          io.to(`game:${gameCode}`).emit(SOCKET_EVENTS.GAME_COMPLETE, {
            winner: updatedGame.winner
          });
        }
      } catch (processError) {
        logger.error(`Error processing answer: ${processError.message}`);
        socket.emit('error', { message: `Failed to process answer: ${processError.message}` });
      }
    } catch (error) {
      logger.error(`Error in game:submitAnswer: ${error.message}`);
      socket.emit('error', { message: 'Failed to process answer' });
    }
  });

  // Player left/disconnected
  socket.on('disconnect', async () => {
    try {
      if (!userId) return;

      // Find active games for this user
      const activeGames = await Game.find({
        $or: [
          { 'players.player1.user': userId, status: { $in: ['active', 'waiting'] } },
          { 'players.player2.user': userId, status: { $in: ['active', 'waiting'] } }
        ]
      });

      // Update connection status for each game
      for (const game of activeGames) {
        if (game.players.player1.user.toString() === userId.toString()) {
          game.players.player1.connected = false;
          await game.save();

          // Notify other player
          io.to(`game:${game.gameCode}`).emit(SOCKET_EVENTS.GAME_PLAYER_DISCONNECTED, {
            playerType: 'player1'
          });
        } else if (game.players.player2.user.toString() === userId.toString()) {
          game.players.player2.connected = false;
          await game.save();

          // Notify other player
          io.to(`game:${game.gameCode}`).emit(SOCKET_EVENTS.GAME_PLAYER_DISCONNECTED, {
            playerType: 'player2'
          });
        }
      }
    } catch (error) {
      logger.error(`Error handling disconnect: ${error.message}`);
    }
  });
};

export default setupGameEvents;