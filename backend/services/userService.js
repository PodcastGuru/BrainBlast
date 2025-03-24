// services/userService.js - User Service
import User from '../models/User.js';
import Game from '../models/Game.js';
import ErrorResponse from '../utils/errorResponse.js';
import logger from '../utils/logger.js';
import { isValidEmail } from '../utils/helpers.js';

/**
 * User service for handling user-related business logic
 */
const userService = {
  /**
   * Get all users with filtering and pagination
   * @param {Object} queryParams - Query parameters for filtering and pagination
   * @returns {Object} Users and pagination info
   */
  getUsers: async (queryParams) => {
    try {
      const { 
        search,
        role,
        isVerified,
        page = 1,
        limit = 10,
        sort = '-createdAt'
      } = queryParams;
      
      // Build query
      const query = {};
      
      if (search) {
        query.$or = [
          { username: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } }
        ];
      }
      
      if (role) query.role = role;
      if (isVerified !== undefined) query.isVerified = isVerified === 'true';
      
      // Pagination
      const startIndex = (page - 1) * limit;
      const endIndex = page * limit;
      const total = await User.countDocuments(query);
      
      // Get users
      const users = await User.find(query)
        .select('-password')
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
      
      return { users, pagination };
    } catch (error) {
      logger.error(`Error getting users: ${error.message}`);
      throw new ErrorResponse('Failed to get users', 500);
    }
  },
  
  /**
   * Get a single user by ID
   * @param {string} id - User ID
   * @returns {Object} User
   */
  getUser: async (id) => {
    try {
      const user = await User.findById(id).select('-password');
      
      if (!user) {
        throw new ErrorResponse(`User not found with id ${id}`, 404);
      }
      
      return user;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error getting user: ${error.message}`);
      throw new ErrorResponse('Failed to get user', 500);
    }
  },
  
  /**
   * Create a new user
   * @param {Object} userData - User data
   * @returns {Object} Created user
   */
  createUser: async (userData) => {
    try {
      // Validate required fields
      const requiredFields = ['username', 'email', 'password'];
      
      for (const field of requiredFields) {
        if (!userData[field]) {
          throw new ErrorResponse(`${field} is required`, 400);
        }
      }
      
      // Validate email format
      if (!isValidEmail(userData.email)) {
        throw new ErrorResponse('Invalid email format', 400);
      }
      
      // Check if user with this email already exists
      const existingEmail = await User.findOne({ email: userData.email });
      if (existingEmail) {
        throw new ErrorResponse('Email already in use', 400);
      }
      
      // Check if user with this username already exists
      const existingUsername = await User.findOne({ username: userData.username });
      if (existingUsername) {
        throw new ErrorResponse('Username already taken', 400);
      }
      
      const user = await User.create(userData);
      
      return user;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      // Handle duplicate key error
      if (error.code === 11000) {
        throw new ErrorResponse('User with this email or username already exists', 400);
      }
      
      logger.error(`Error creating user: ${error.message}`);
      throw new ErrorResponse('Failed to create user', 500);
    }
  },
  
  /**
   * Update an existing user
   * @param {string} id - User ID
   * @param {Object} updateData - Data to update
   * @returns {Object} Updated user
   */
  updateUser: async (id, updateData) => {
    try {
      let user = await User.findById(id);
      
      if (!user) {
        throw new ErrorResponse(`User not found with id ${id}`, 404);
      }
      
      // Don't allow password updates through this method
      if (updateData.password) {
        delete updateData.password;
      }
      
      // Check for email uniqueness if being updated
      if (updateData.email && updateData.email !== user.email) {
        const existingEmail = await User.findOne({ email: updateData.email });
        if (existingEmail) {
          throw new ErrorResponse('Email already in use', 400);
        }
      }
      
      // Check for username uniqueness if being updated
      if (updateData.username && updateData.username !== user.username) {
        const existingUsername = await User.findOne({ username: updateData.username });
        if (existingUsername) {
          throw new ErrorResponse('Username already taken', 400);
        }
      }
      
      user = await User.findByIdAndUpdate(id, updateData, {
        new: true,
        runValidators: true
      }).select('-password');
      
      return user;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error updating user: ${error.message}`);
      throw new ErrorResponse('Failed to update user', 500);
    }
  },
  
  /**
   * Delete a user
   * @param {string} id - User ID
   */
  deleteUser: async (id) => {
    try {
      const user = await User.findById(id);
      
      if (!user) {
        throw new ErrorResponse(`User not found with id ${id}`, 404);
      }
      
      await user.deleteOne();
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error deleting user: ${error.message}`);
      throw new ErrorResponse('Failed to delete user', 500);
    }
  },
  
  /**
   * Get user profile by username
   * @param {string} username - Username
   * @returns {Object} User profile
   */
  getUserProfile: async (username) => {
    try {
      const user = await User.findOne({ username })
        .select('username avatar stats createdAt');
      
      if (!user) {
        throw new ErrorResponse(`User not found with username ${username}`, 404);
      }
      
      return user;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error getting user profile: ${error.message}`);
      throw new ErrorResponse('Failed to get user profile', 500);
    }
  },
  
  /**
   * Update user password
   * @param {string} id - User ID
   * @param {string} currentPassword - Current password
   * @param {string} newPassword - New password
   * @returns {Object} Updated user
   */
  updatePassword: async (id, currentPassword, newPassword) => {
    try {
      const user = await User.findById(id).select('+password');
      
      if (!user) {
        throw new ErrorResponse(`User not found with id ${id}`, 404);
      }
      
      // Check if current password matches
      const isMatch = await user.matchPassword(currentPassword);
      
      if (!isMatch) {
        throw new ErrorResponse('Current password is incorrect', 401);
      }
      
      // Update password
      user.password = newPassword;
      await user.save();
      
      return user;
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error updating password: ${error.message}`);
      throw new ErrorResponse('Failed to update password', 500);
    }
  },
  
  /**
   * Get leaderboard
   * @param {string} sortBy - Field to sort by
   * @param {number} limit - Number of users to return
   * @returns {Array} Top users
   */
  getLeaderboard: async (sortBy = 'totalPoints', limit = 10) => {
    try {
      // Valid sort fields
      const validSortFields = ['totalPoints', 'gamesWon', 'winRate', 'totalCorrectAnswers', 'averageResponseTime'];
      
      // Default to totalPoints if invalid sort field
      const sortField = validSortFields.includes(sortBy) ? sortBy : 'totalPoints';
      
      // Sort direction (descending for all except averageResponseTime)
      const sortDirection = sortField === 'averageResponseTime' ? 1 : -1;
      
      // Get top users
      const users = await User.find({
        'stats.gamesPlayed': { $gt: 0 } // Only include users who have played games
      })
        .select('username avatar stats')
        .sort({ [`stats.${sortField}`]: sortDirection })
        .limit(parseInt(limit));
      
      return users;
    } catch (error) {
      logger.error(`Error getting leaderboard: ${error.message}`);
      throw new ErrorResponse('Failed to get leaderboard', 500);
    }
  },
  
  /**
   * Get user statistics
   * @param {string} userId - User ID
   * @returns {Object} User statistics
   */
  getUserStats: async (userId) => {
    try {
      // Get user stats
      const user = await User.findById(userId).select('stats');
      
      if (!user) {
        throw new ErrorResponse(`User not found with id ${userId}`, 404);
      }
      
      // Get additional stats from games
      const gamesCount = await Game.countDocuments({
        $or: [
          { 'players.player1.user': userId },
          { 'players.player2.user': userId }
        ]
      });
      
      const activeGamesCount = await Game.countDocuments({
        $or: [
          { 'players.player1.user': userId },
          { 'players.player2.user': userId }
        ],
        status: { $in: ['waiting', 'active', 'paused'] }
      });
      
      const completedGamesCount = await Game.countDocuments({
        $or: [
          { 'players.player1.user': userId },
          { 'players.player2.user': userId }
        ],
        status: 'completed'
      });
      
      // Get recent games
      const recentGames = await Game.find({
        $or: [
          { 'players.player1.user': userId },
          { 'players.player2.user': userId }
        ],
        status: 'completed'
      })
        .sort({ completedAt: -1 })
        .limit(5)
        .select('gameCode players.player1.score players.player2.score winner completedAt')
        .populate('players.player1.user', 'username')
        .populate('players.player2.user', 'username');
      
      return {
        ...user.stats.toObject(),
        gamesCount,
        activeGamesCount,
        completedGamesCount,
        recentGames
      };
    } catch (error) {
      if (error instanceof ErrorResponse) {
        throw error;
      }
      
      logger.error(`Error getting user stats: ${error.message}`);
      throw new ErrorResponse('Failed to get user stats', 500);
    }
  }
};

export default userService;