// utils/constants.js - Application Constants

// Game settings
export const GAME_SETTINGS = {
    DEFAULT_WINNING_SCORE: 3,
    DEFAULT_MAX_ROUNDS: 5,
    PLAYER_TIMEOUT_MINUTES: 5,
    MAX_ANSWER_TIME_SECONDS: 120, // 2 minutes
  };
  
  // User roles
  export const USER_ROLES = {
    USER: 'user',
    ADMIN: 'admin',
  };
  
  // Game statuses
  export const GAME_STATUS = {
    WAITING: 'waiting',
    ACTIVE: 'active',
    PAUSED: 'paused',
    COMPLETED: 'completed',
    ABANDONED: 'abandoned',
  };
  
  // Player types
  export const PLAYER_TYPES = {
    PLAYER1: 'player1',
    PLAYER2: 'player2',
  };
  
  // Round outcomes
  export const ROUND_OUTCOMES = {
    PLAYER1_WIN: 'player1',
    PLAYER2_WIN: 'player2',
    TIE: 'tie',
  };
  
  // Question difficulty levels
  export const DIFFICULTY_LEVELS = {
    EASY: 'easy',
    MEDIUM: 'medium',
    HARD: 'hard',
    MIXED: 'mixed',
  };
  
  // Question subjects
  export const SUBJECTS = {
    ALGEBRA: 'algebra',
    GEOMETRY: 'geometry',
    CALCULUS: 'calculus',
    STATISTICS: 'statistics',
    OTHER: 'other',
    MIXED: 'mixed',
  };
  
  // Question types
  export const QUESTION_TYPES = {
    MULTIPLE_CHOICE: 'multiple-choice',
    NUMERIC: 'numeric',
    TEXT: 'text',
  };
  
  // Socket.io events
  export const SOCKET_EVENTS = {
    // Connection events
    CONNECT: 'connect',
    DISCONNECT: 'disconnect',
    ERROR: 'error',
    
    // Game events
    GAME_JOIN: 'game:join',
    GAME_STATE: 'game:state',
    GAME_SUBMIT_ANSWER: 'game:submitAnswer',
    GAME_ANSWER_PROCESSED: 'game:answerProcessed',
    GAME_ROUND_COMPLETE: 'game:roundComplete',
    GAME_COMPLETE: 'game:complete',
    GAME_YOUR_TURN: 'game:yourTurn',
    GAME_PLAYER_CONNECTED: 'game:playerConnected',
    GAME_PLAYER_DISCONNECTED: 'game:playerDisconnected',
    
    // Notification events
    NOTIFICATIONS_SUBSCRIBE: 'notifications:subscribe',
    NOTIFICATIONS_SUBSCRIBED: 'notifications:subscribed',
    NOTIFICATIONS_MARK_READ: 'notifications:markRead',
    NOTIFICATIONS_MARKED: 'notifications:marked',
    NOTIFICATIONS_CLEAR_ALL: 'notifications:clearAll',
    NOTIFICATIONS_CLEARED: 'notifications:cleared',
    NOTIFICATION_RECEIVED: 'notification:received',
  };
  
  // HTTP status codes
  export const HTTP_STATUS = {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    INTERNAL_SERVER_ERROR: 500,
  };
  
  // Pagination defaults
  export const PAGINATION = {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 10,
    MAX_LIMIT: 100,
  };