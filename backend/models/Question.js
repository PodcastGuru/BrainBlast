// models/Question.js - Question Model Schema
import mongoose from 'mongoose';

const QuestionSchema = new mongoose.Schema({
  questionId: {
    type: String,
    required: [true, 'Question ID is required'],
    unique: true,
    trim: true
  },
  text: {
    type: String,
    required: [true, 'Question text is required'],
    trim: true
  },
  type: {
    type: String,
    enum: ['multiple-choice', 'numeric', 'text'],
    required: [true, 'Question type is required']
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    required: [true, 'Difficulty level is required']
  },
  subject: {
    type: String,
    enum: ['algebra', 'geometry', 'calculus', 'statistics', 'other'],
    default: 'other'
  },
  skillTag: {
    type: String,
    default: ''
  },
  options: {
    type: [{
      label: String,
      value: String,
      text: String
    }],
    validate: {
      validator: function(options) {
        // Only required for multiple-choice questions
        return this.type !== 'multiple-choice' || options.length >= 2;
      },
      message: 'Multiple-choice questions must have at least 2 options'
    }
  },
  correctAnswer: {
    type: String,
    required: [true, 'Correct answer is required']
  },
  explanation: {
    type: String,
    required: [true, 'Explanation is required']
  },
  stepByStepLink: {
    type: String,
    default: ''
  },
  imageUrl: {
    type: String,
    default: ''
  },
  usageStats: {
    timesUsed: {
      type: Number,
      default: 0
    },
    correctAnswerRate: {
      type: Number,
      default: 0
    },
    averageResponseTime: {
      type: Number,
      default: 0
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Update usage statistics
QuestionSchema.methods.updateUsageStats = function(wasCorrect, responseTime) {
  // Increment times used
  this.usageStats.timesUsed += 1;
  
  // Update correct answer rate
  const oldCorrectCount = this.usageStats.correctAnswerRate * (this.usageStats.timesUsed - 1);
  const newCorrectCount = oldCorrectCount + (wasCorrect ? 1 : 0);
  this.usageStats.correctAnswerRate = newCorrectCount / this.usageStats.timesUsed;
  
  // Update average response time
  const oldTotalTime = this.usageStats.averageResponseTime * (this.usageStats.timesUsed - 1);
  const newTotalTime = oldTotalTime + responseTime;
  this.usageStats.averageResponseTime = newTotalTime / this.usageStats.timesUsed;
  
  return this.save();
};

// Indexes for efficient querying
QuestionSchema.index({ difficulty: 1, subject: 1, isActive: 1 });
QuestionSchema.index({ skillTag: 1 });
QuestionSchema.index({ type: 1 });

const Question = mongoose.model('Question', QuestionSchema);

export default Question;