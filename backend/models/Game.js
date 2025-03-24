// models/Game.js - Game Model Schema
import mongoose from 'mongoose';

/**
 * Player schema - represents a player in a game
 */
const PlayerSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  score: {
    type: Number,
    default: 0
  },
  connected: {
    type: Boolean,
    default: true
  },
  lastActivity: {
    type: Date,
    default: Date.now
  }
});

const RoundSchema = new mongoose.Schema({
  roundNumber: {
    type: Number,
    required: true
  },
  question: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question',
    required: true
  },
  player1Answer: {
    answer: String,
    isCorrect: Boolean,
    timeElapsed: Number, // in seconds
    answeredAt: Date
  },
  player2Answer: {
    answer: String,
    isCorrect: Boolean,
    timeElapsed: Number, // in seconds
    answeredAt: Date
  },
  winner: {
    type: String,
    enum: ['player1', 'player2', 'tie', null],
    default: null
  },
  roundComplete: {
    type: Boolean,
    default: false
  }
});

const GameSchema = new mongoose.Schema({
  gameCode: {
    type: String,
    required: true,
    unique: true
  },
  players: {
    player1: PlayerSchema,
    player2: PlayerSchema
  },
  rounds: [RoundSchema],
  currentRound: {
    type: Number,
    default: 1
  },
  currentTurn: {
    type: String,
    enum: ['player1', 'player2'],
    default: 'player1'
  },
  status: {
    type: String,
    enum: ['waiting', 'active', 'paused', 'completed', 'abandoned'],
    default: 'waiting'
  },
  winner: {
    type: String,
    enum: ['player1', 'player2', null],
    default: null
  },
  winningScore: {
    type: Number,
    default: 3
  },
  gameType: {
    type: String,
    default: 'standard'
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard', 'mixed'],
    default: 'mixed'
  },
  subject: {
    type: String,
    enum: ['algebra', 'geometry', 'calculus', 'statistics', 'other', 'mixed'],
    default: 'mixed'
  },
  maxRounds: {
    type: Number,
    default: 5
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  startedAt: {
    type: Date
  },
  completedAt: {
    type: Date
  },
  timeoutAt: {
    type: Date
  },
  challengeInfo: {
    challenger: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    challenged: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'expired'],
      default: 'pending'
    },
    expiresAt: {
      type: Date,
      default: function () {
        // Default expiration time (e.g., 24 hours from now)
        const date = new Date();
        date.setHours(date.getHours() + 24);
        return date;
      }
    }
  }
}, {
  timestamps: true
});

// Generate a random game code
GameSchema.statics.generateGameCode = function () {
  const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return code;
};


/**
 * Check if an answer is correct for a given question
 * @param {Object} question - Question object
 * @param {string} answer - Answer to check
 * @returns {boolean} Whether the answer is correct
 */
GameSchema.methods.checkAnswer = function(question, answer) {
  console.log('Checking answer:', { 
    questionType: question.type, 
    correctAnswer: question.correctAnswer,
    submittedAnswer: answer 
  });
  
  // For multiple-choice questions
  if (question.type === 'multiple-choice') {
    return answer === question.correctAnswer;
  }
  
  // For numeric questions, allow for slight rounding differences
  if (question.type === 'numeric') {
    // Try to parse both as numbers
    const numericAnswer = parseFloat(String(answer).replace(/\s/g, ''));
    const correctAnswer = parseFloat(String(question.correctAnswer).replace(/\s/g, ''));
    
    if (isNaN(numericAnswer) || isNaN(correctAnswer)) {
      return String(answer).trim() === String(question.correctAnswer).trim();
    }
    
    // Allow for a small margin of error for floating point comparisons
    const epsilon = 0.0001;
    return Math.abs(numericAnswer - correctAnswer) < epsilon;
  }
  
  // For text answers, ignore case and whitespace
  return String(answer).trim().toLowerCase() === String(question.correctAnswer).trim().toLowerCase();
};


/**
 * Get the game state filtered for a specific player
 * @param {string} playerType - 'player1' or 'player2'
 * @returns {Object} Game state from the player's perspective
 */
// Simplified getStateForPlayer method for Game model
GameSchema.methods.getStateForPlayer = function(playerType) {
  try {
    // Defensive checks for input
    if (!playerType || (playerType !== 'player1' && playerType !== 'player2')) {
      console.error('Invalid playerType:', playerType);
      return {
        gameCode: this.gameCode,
        status: this.status,
        error: 'Invalid player type'
      };
    }

    // Get player and opponent information
    const player = this.players[playerType];
    if (!player) {
      console.error('Player not found:', playerType);
      return {
        gameCode: this.gameCode,
        status: this.status,
        error: 'Player not found'
      };
    }

    const opponentType = playerType === 'player1' ? 'player2' : 'player1';
    const opponent = this.players[opponentType];

    // Build the base state object with safe defaults
    const state = {
      gameCode: this.gameCode,
      status: this.status || 'waiting',
      gameType: this.gameType || 'standard',
      difficulty: this.difficulty || 'mixed',
      subject: this.subject || 'mixed',
      maxRounds: this.maxRounds || 5,
      winningScore: this.winningScore || 3,
      currentRound: this.currentRound || 1,
      currentTurn: this.currentTurn || 'player1',
      
      // Player info with safe values
      player: {
        type: playerType,
        score: player.score || 0,
        connected: player.connected || false,
        lastActivity: player.lastActivity || new Date()
      },
      
      // Opponent info with safe values
      opponent: opponent ? {
        type: opponentType,
        score: opponent.score || 0,
        connected: opponent.connected || false,
        lastActivity: opponent.lastActivity || null
      } : {
        type: opponentType,
        score: 0,
        connected: false,
        lastActivity: null
      },
      
      // For frontend compatibility
      yourScore: player.score || 0,
      opponentScore: opponent ? (opponent.score || 0) : 0,
      
      // Initialize empty rounds array
      rounds: []
    };

    // Add round data if available
    if (Array.isArray(this.rounds)) {
      this.rounds.forEach((round, index) => {
        // For completed rounds, show full information
        if (round.roundComplete) {
          state.rounds.push({
            roundNumber: round.roundNumber,
            question: round.question,
            yourAnswer: round[`${playerType}Answer`] || null,
            opponentAnswer: round[`${opponentType}Answer`] || null,
            winner: round.winner === playerType ? 'you' : 
                   round.winner === opponentType ? 'opponent' : 
                   round.winner === 'tie' ? 'tie' : null
          });
        } 
        // For current round, only show player's own answer
        else if (index === this.currentRound - 1) {
          state.rounds.push({
            roundNumber: round.roundNumber,
            question: round.question,
            yourAnswer: round[`${playerType}Answer`] || null,
            opponentAnswer: null, // Don't show opponent's answer for current round
            winner: null
          });
        }
      });
    }

    // Include the current question if it's this player's turn
    if (this.status === 'active' && this.currentTurn === playerType && this.currentRound > 0) {
      const currentRoundIndex = this.currentRound - 1;
      
      if (currentRoundIndex >= 0 && currentRoundIndex < this.rounds.length) {
        const currentRound = this.rounds[currentRoundIndex];
        
        // Make sure the question is populated before including it
        if (currentRound && currentRound.question) {
          // If the question is a populated document (not just an ID)
          if (typeof currentRound.question !== 'string' && currentRound.question._id) {
            // Create a sanitized version of the question (no correct answer)
            state.currentQuestion = {
              _id: currentRound.question._id.toString(),
              text: currentRound.question.text || '',
              type: currentRound.question.type || 'text',
              subject: currentRound.question.subject || 'other',
              difficulty: currentRound.question.difficulty || 'medium',
              skillTag: currentRound.question.skillTag || '',
              imageUrl: currentRound.question.imageUrl || null
            };
            
            // Include options for multiple-choice questions
            if (currentRound.question.type === 'multiple-choice' && 
                Array.isArray(currentRound.question.options)) {
              state.currentQuestion.options = [...currentRound.question.options];
            }
          } else {
            // If question is not populated, just include the ID reference
            state.currentQuestion = currentRound.question.toString();
          }
        }
      }
    }

    
    return state;
  } catch (error) {
    console.error('Error in getStateForPlayer:', error);
    // Return minimal state in case of error
    return {
      gameCode: this.gameCode,
      status: this.status || 'waiting',
      error: 'Error generating game state'
    };
  }
};


/**
 * Submit an answer for the current round
 * @param {string} playerType - 'player1' or 'player2'
 * @param {string} answer - The player's answer
 * @param {number} timeElapsed - Time taken to answer in seconds
 * @returns {Object} The answer object that was recorded
 */
GameSchema.methods.submitAnswer = async function(playerType, answer, timeElapsed) {
  // Get the current round
  const currentRoundIndex = this.currentRound - 1;
  if (currentRoundIndex < 0 || currentRoundIndex >= this.rounds.length) {
    throw new Error(`Round not found: ${this.currentRound}`);
  }

  const round = this.rounds[currentRoundIndex];
  
  // Check if already answered
  if (round[`${playerType}Answer`] && round[`${playerType}Answer`].answer) {
    throw new Error(`${playerType} has already answered this round`);
  }
  
  // Get the question to check if the answer is correct
  let isCorrect = false;
  let question = round.question;
  
  try {
    // If the question is a populated document (not just an ID)
    if (typeof question !== 'string' && question._id) {
      // Use our checkAnswer function
      isCorrect = this.checkAnswer(question, answer);
      
      // Try to update usage stats if the question has this method
      try {
        if (typeof question.updateUsageStats === 'function') {
          await question.updateUsageStats(isCorrect, timeElapsed);
        }
      } catch (statsError) {
        console.error('Error updating question stats:', statsError.message);
      }
    } else {
      // If question is not populated, we need to fetch it
      const Question = mongoose.model('Question');
      question = await Question.findById(question);
      
      if (!question) {
        throw new Error('Question not found');
      }
      
      // Check the answer
      isCorrect = this.checkAnswer(question, answer);
      
      // Try to update usage stats
      try {
        if (typeof question.updateUsageStats === 'function') {
          await question.updateUsageStats(isCorrect, timeElapsed);
        }
      } catch (statsError) {
        console.error('Error updating question stats:', statsError.message);
      }
    }
  } catch (error) {
    console.error(`Error checking answer: ${error.message}`);
    // If we can't check the answer for some reason, default to incorrect
    isCorrect = false;
  }
  
  // Record the answer
  round[`${playerType}Answer`] = {
    answer: answer,
    isCorrect: isCorrect,
    timeElapsed: timeElapsed,
    answeredAt: new Date()
  };
  
  // Update the player's last activity
  this.players[playerType].lastActivity = new Date();
  
  console.log(`Player ${playerType} submitted answer:`, {
    answer,
    isCorrect,
    timeElapsed,
    roundNumber: round.roundNumber
  });
  
  // Save the game
  await this.save();
  
  return round[`${playerType}Answer`];
};


// Fixed evaluateRound method for Game model

/**
 * Evaluate the current round after both players have answered
 * @returns {Object} Result of the round evaluation
 */
GameSchema.methods.evaluateRound = async function() {
  // Get the current round
  const currentRoundIndex = this.currentRound - 1;
  if (currentRoundIndex < 0 || currentRoundIndex >= this.rounds.length) {
    throw new Error(`Round not found: ${this.currentRound}`);
  }

  const round = this.rounds[currentRoundIndex];
  
  // Ensure both players have answered
  if (!round.player1Answer || !round.player2Answer) {
    throw new Error('Both players must answer before evaluating the round');
  }
  
  // Determine winner based on correctness and time
  const player1Correct = round.player1Answer.isCorrect;
  const player2Correct = round.player2Answer.isCorrect;
  
  if (player1Correct && !player2Correct) {
    round.winner = 'player1';
    this.players.player1.score += 1;
  } else if (!player1Correct && player2Correct) {
    round.winner = 'player2';
    this.players.player2.score += 1;
  } else if (player1Correct && player2Correct) {
    // Both correct, faster player wins
    if (round.player1Answer.timeElapsed < round.player2Answer.timeElapsed) {
      round.winner = 'player1';
      this.players.player1.score += 1;
    } else if (round.player2Answer.timeElapsed < round.player1Answer.timeElapsed) {
      round.winner = 'player2';
      this.players.player2.score += 1;
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
  
  // Check if the game is over
  let gameWinner = null;
  
  // Manual winner check (in case checkForWinner method isn't available)
  if (this.players.player1.score >= this.winningScore) {
    this.winner = 'player1';
    this.status = 'completed';
    this.completedAt = new Date();
    gameWinner = 'player1';
  } else if (this.players.player2.score >= this.winningScore) {
    this.winner = 'player2';
    this.status = 'completed'; 
    this.completedAt = new Date();
    gameWinner = 'player2';
  } else {
    // If game is not over, prepare next round
    if (this.status === 'active') {
      // Create next round if we haven't reached max rounds
      if (this.currentRound < this.maxRounds) {
        // Set the turn to the opposite of the current round winner
        this.currentTurn = round.winner === 'player1' ? 'player2' : 'player1';
        
        // If tie, alternate from the current turn
        if (round.winner === 'tie') {
          this.currentTurn = this.currentTurn === 'player1' ? 'player2' : 'player1';
        }
        
        try {
          // Get a new question for the next round
          const query = { isActive: true };
          
          if (this.difficulty && this.difficulty !== 'mixed') {
            query.difficulty = this.difficulty;
          }
          
          if (this.subject && this.subject !== 'mixed') {
            query.subject = this.subject;
          }
          
          // Try to get a question we haven't used yet
          const usedQuestionIds = this.rounds.map(r => 
            typeof r.question === 'string' ? r.question : r.question._id.toString()
          );
          
          if (usedQuestionIds.length > 0) {
            query._id = { $nin: usedQuestionIds };
          }
          
          // Get a random question
          const Question = mongoose.model('Question');
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
            this.currentRound += 1;
            
            // Add new round
            this.rounds.push({
              roundNumber: this.currentRound,
              question: question._id
            });
          } else {
            // Get a random question
            const random = Math.floor(Math.random() * count);
            const question = await Question.findOne(query).skip(random);
            
            // Increment round counter
            this.currentRound += 1;
            
            // Add new round
            this.rounds.push({
              roundNumber: this.currentRound,
              question: question._id
            });
          }
        } catch (error) {
          console.error('Error selecting next question:', error);
          
          // If we can't get a new question, end the game
          if (this.players.player1.score > this.players.player2.score) {
            this.winner = 'player1';
          } else if (this.players.player2.score > this.players.player1.score) {
            this.winner = 'player2';
          } else {
            // Tie game
            this.winner = null;
          }
          
          this.status = 'completed';
          this.completedAt = new Date();
        }
      } else {
        // If we've reached max rounds, determine the winner by score
        if (this.players.player1.score > this.players.player2.score) {
          this.winner = 'player1';
        } else if (this.players.player2.score > this.players.player1.score) {
          this.winner = 'player2';
        } else {
          // Tie game
          this.winner = null;
        }
        
        this.status = 'completed';
        this.completedAt = new Date();
      }
    }
  }
  
  // Save the game
  await this.save();
  
  return {
    roundComplete: true,
    roundWinner: round.winner,
    gameComplete: this.status === 'completed',
    gameWinner: this.winner
  };
};

/**
 * Check if either player has reached the winning score
 * @returns {string|null} The winner ('player1', 'player2') or null if no winner yet
 */
GameSchema.methods.checkForWinner = function() {
  const { player1, player2 } = this.players;

  if (player1.score >= this.winningScore) {
    this.winner = 'player1';
    this.status = 'completed';
    this.completedAt = new Date();
  } else if (player2.score >= this.winningScore) {
    this.winner = 'player2';
    this.status = 'completed';
    this.completedAt = new Date();
  }

  return this.winner;
};

/**
 * Add a new round to the game with a specific question
 * @param {string|ObjectId} questionId - Question ID
 * @returns {Object} The newly added round
 */
GameSchema.methods.addNewRound = async function(questionId) {
  // Create the new round
  const newRound = {
    roundNumber: this.currentRound,
    question: questionId,
    roundComplete: false
  };
  
  // Add to rounds array
  this.rounds.push(newRound);
  
  // Save the game
  await this.save();
  
  return newRound;
};

/**
 * Add a new round to the game with a randomly selected question
 * @returns {Object} The newly added round with the question
 */
GameSchema.methods.addNewRoundWithRandomQuestion = async function() {
  try {
    // Build query for question selection
    const query = { isActive: true };
    
    if (this.difficulty && this.difficulty !== 'mixed') {
      query.difficulty = this.difficulty;
    }
    
    if (this.subject && this.subject !== 'mixed') {
      query.subject = this.subject;
    }
    
    // Get IDs of already used questions to exclude them
    const usedQuestionIds = this.rounds.map(r => r.question);
    if (usedQuestionIds.length > 0) {
      query._id = { $nin: usedQuestionIds };
    }
    
    // Count matching questions
    const Question = this.constructor.model('Question');
    const count = await Question.countDocuments(query);
    
    // Select question
    let question;
    
    if (count === 0) {
      // If no new questions available, use any question (including already used ones)
      delete query._id;
      const fallbackCount = await Question.countDocuments(query);
      
      if (fallbackCount === 0) {
        throw new Error('No questions available');
      }
      
      const random = Math.floor(Math.random() * fallbackCount);
      question = await Question.findOne(query).skip(random);
    } else {
      // Get a random question from available ones
      const random = Math.floor(Math.random() * count);
      question = await Question.findOne(query).skip(random);
    }
    
    // Create the new round
    const newRound = {
      roundNumber: this.currentRound,
      question: question._id,
      roundComplete: false
    };
    
    // Add to rounds array
    this.rounds.push(newRound);
    
    // Save the game
    await this.save();
    
    return { round: newRound, question };
  } catch (error) {
    throw new Error(`Failed to add new round: ${error.message}`);
  }
};


const Game = mongoose.model('Game', GameSchema);


export default Game;