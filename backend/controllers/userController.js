// controllers/userController.js - User Controller
import asyncHandler from '../middlewares/asyncHandler.js';
import ErrorResponse from '../utils/errorResponse.js';
import User from '../models/User.js';
import Game from '../models/Game.js';
import { getOnlineUserIds } from '../utils/socketManager.js';

/**
 * @desc    Get all users
 * @route   GET /api/users
 * @access  Private (Admin only)
 */
export const getUsers = asyncHandler(async (req, res, next) => {
  // Query parameters
  const {
    search,
    role,
    isVerified,
    page = 1,
    limit = 10,
    sort = '-createdAt'
  } = req.query;

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

  res.status(200).json({
    success: true,
    pagination,
    data: users
  });
});

/**
 * @desc    Get single user
 * @route   GET /api/users/:id
 * @access  Private (Admin only)
 */
export const getUser = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id).select('-password');

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  res.status(200).json({
    success: true,
    data: user
  });
});

/**
 * @desc    Create user
 * @route   POST /api/users
 * @access  Private (Admin only)
 */
export const createUser = asyncHandler(async (req, res, next) => {
  const user = await User.create(req.body);

  res.status(201).json({
    success: true,
    data: user
  });
});

/**
 * @desc    Update user
 * @route   PUT /api/users/:id
 * @access  Private (Admin only)
 */
export const updateUser = asyncHandler(async (req, res, next) => {
  let user = await User.findById(req.params.id);

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  user = await User.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true
  }).select('-password');

  res.status(200).json({
    success: true,
    data: user
  });
});

/**
 * @desc    Delete user
 * @route   DELETE /api/users/:id
 * @access  Private (Admin only)
 */
export const deleteUser = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  await user.deleteOne();

  res.status(200).json({
    success: true,
    data: {}
  });
});

/**
 * @desc    Get user profile
 * @route   GET /api/users/profile/:username
 * @access  Public
 */
export const getUserProfile = asyncHandler(async (req, res, next) => {
  const user = await User.findOne({ username: req.params.username })
    .select('username avatar stats createdAt');

  if (!user) {
    return next(new ErrorResponse(`User not found with username ${req.params.username}`, 404));
  }

  res.status(200).json({
    success: true,
    data: user
  });
});

/**
 * @desc    Get leaderboard
 * @route   GET /api/users/leaderboard
 * @access  Public
 */
export const getLeaderboard = asyncHandler(async (req, res, next) => {
  const {
    sortBy = 'totalPoints',
    limit = 10
  } = req.query;

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

  res.status(200).json({
    success: true,
    data: users
  });
});

/**
 * @desc    Get user stats
 * @route   GET /api/users/stats
 * @access  Private
 */
export const getUserStats = asyncHandler(async (req, res, next) => {
  // Get user stats
  const user = await User.findById(req.user._id)
    .select('stats');

  // Get additional stats from games
  const gamesCount = await Game.countDocuments({
    $or: [
      { 'players.player1.user': req.user._id },
      { 'players.player2.user': req.user._id }
    ]
  });

  const activeGamesCount = await Game.countDocuments({
    $or: [
      { 'players.player1.user': req.user._id },
      { 'players.player2.user': req.user._id }
    ],
    status: { $in: ['waiting', 'active', 'paused'] }
  });

  const completedGamesCount = await Game.countDocuments({
    $or: [
      { 'players.player1.user': req.user._id },
      { 'players.player2.user': req.user._id }
    ],
    status: 'completed'
  });

  res.status(200).json({
    success: true,
    data: {
      ...user.stats.toObject(),
      gamesCount,
      activeGamesCount,
      completedGamesCount
    }
  });
});


export const getOnlineUsers = asyncHandler(async (req, res, next) => {
  // Get all users except current user
  const users = await User.find({
    _id: { $ne: req.user._id },
    'stats.gamesPlayed': { $gt: 0 }
  })
    .select('username avatar stats.gamesPlayed stats.gamesWon')
    .limit(50);

  // Get online user IDs from socket manager
  const onlineUserIds = getOnlineUserIds();

  // Add online status to user objects
  const usersWithStatus = users.map(user => ({
    ...user.toObject(),
    isOnline: onlineUserIds.includes(user._id.toString())
  }));

  res.status(200).json({
    success: true,
    data: usersWithStatus
  });
});