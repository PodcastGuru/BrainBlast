// utils/seeder.js - Database Seeder
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';
import colors from 'colors';
import fs from 'fs';
import { parse } from 'csv-parse/sync';

// Models
import User from '../models/User.js';
import Question from '../models/Question.js';
import Game from '../models/Game.js';

// Get __dirname equivalent in ES Module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load env vars
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// Connect to DB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

// Read and parse CSV file
const readSATQuestions = () => {
  try {
    const csvFilePath = path.resolve(__dirname, 'data/SAT_Question.csv');
    const fileContent = fs.readFileSync(csvFilePath, { encoding: 'utf-8' });
    
    // Parse CSV
    const records = parse(fileContent, {
      columns: true,
      skip_empty_lines: true
    });
    
    // Map CSV records to question format
    return records.map((record, index) => {
      // Generate a unique questionId if not present
      const questionId = record.ID || `ALG${String(index + 100).padStart(3, '0')}`;
      
      // Determine question type (multiple-choice or numeric)
      const hasOptions = record.A && record.B && record.C && record.D;
      const questionType = hasOptions ? 'multiple-choice' : 'numeric';
      
      // Create question object
      const question = {
        questionId,
        text: record.Question,
        type: questionType,
        difficulty: record['Difficulty '] ? record['Difficulty '].toLowerCase() : 'medium',
        subject: 'algebra',
        skillTag: record.Skill || questionId,
        correctAnswer: record['Correct Answer'],
        explanation: record['Formal Answer Explanation'] || 'Explanation not available'
      };
      
      // Add options for multiple-choice questions
      if (questionType === 'multiple-choice') {
        question.options = [
          { label: 'A', value: 'A', text: record.A },
          { label: 'B', value: 'B', text: record.B },
          { label: 'C', value: 'C', text: record.C },
          { label: 'D', value: 'D', text: record.D }
        ].filter(option => option.text); // Filter out empty options
      }
      
      return question;
    });
  } catch (error) {
    console.error(`Error reading or parsing CSV: ${error}`.red);
    return [];
  }
};

// Original sample SAT math questions (keeping as backup)
const originalQuestions = [
  {
    questionId: "ALG001",
    text: "If 5x + 2 = 3x + 10, what is the value of x?",
    type: "numeric",
    difficulty: "easy",
    subject: "algebra",
    skillTag: "ALG001",
    correctAnswer: "4",
    explanation: "To solve this equation, we subtract 3x from both sides to get 2x + 2 = 10. Then subtract 2 from both sides to get 2x = 8. Finally, divide both sides by 2 to get x = 4."
  },
  {
    questionId: "ALG002",
    text: "In the xy-plane, what is the y-coordinate of the midpoint of the line segment whose endpoints are (2, -4) and (8, 12)?",
    type: "numeric",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG002",
    correctAnswer: "4",
    explanation: "The midpoint of a line segment with endpoints (x₁, y₁) and (x₂, y₂) is ((x₁ + x₂)/2, (y₁ + y₂)/2). So the midpoint is ((2 + 8)/2, (-4 + 12)/2) = (5, 4). The y-coordinate is 4."
  },
  {
    questionId: "ALG003",
    text: "If the function f is defined by f(x) = 3x² + 2x - 4, what is the value of f(-2)?",
    type: "numeric",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG003",
    correctAnswer: "8",
    explanation: "Substitute x = -2 into the function: f(-2) = 3(-2)² + 2(-2) - 4 = 3(4) + (-4) - 4 = 12 - 4 - 4 = 4."
  },
  {
    questionId: "ALG004",
    text: "Which of the following is equivalent to (2x³y²)(3xy⁴)?",
    type: "multiple-choice",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG004",
    options: [
      { label: "A", value: "A", text: "5x⁴y⁶" },
      { label: "B", value: "B", text: "6x³y⁶" },
      { label: "C", value: "C", text: "6x⁴y⁶" },
      { label: "D", value: "D", text: "6x⁵y⁸" }
    ],
    correctAnswer: "C",
    explanation: "(2x³y²)(3xy⁴) = 2 × 3 × x³ × x × y² × y⁴ = 6x⁴y⁶"
  },
  {
    questionId: "GEO001",
    text: "A right triangle has a hypotenuse of length 10 and one leg of length 6. What is the length of the other leg?",
    type: "numeric",
    difficulty: "medium",
    subject: "geometry",
    skillTag: "GEO001",
    correctAnswer: "8",
    explanation: "Using the Pythagorean theorem: a² + b² = c², where c is the hypotenuse. We have 6² + b² = 10², so 36 + b² = 100. Thus, b² = 64, and b = 8."
  },
  {
    questionId: "ALG005",
    text: "A store sells notebooks for $1.80 each and pencils for $0.40 each. Kim buys 5 notebooks and a certain number of pencils for a total of $11.20. How many pencils does Kim buy?",
    type: "numeric",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG005",
    correctAnswer: "10",
    explanation: "5 notebooks cost 5 × $1.80 = $9.00. For the total to be $11.20, the cost of pencils is $11.20 - $9.00 = $2.20. Since each pencil costs $0.40, the number of pencils is $2.20 ÷ $0.40 = 5.5. Since we can't buy a partial pencil, there's an error in the problem. Let's check: 5 notebooks at $1.80 each = $9.00. 10 pencils at $0.40 each = $4.00. Total: $9.00 + $4.00 = $13.00. This is incorrect. Let's try 4 notebooks: 4 × $1.80 = $7.20. Remaining for pencils: $11.20 - $7.20 = $4.00. Number of pencils: $4.00 ÷ $0.40 = 10. This works! So the answer is 10 pencils."
  },
  {
    questionId: "ALG006",
    text: "If (x - 3)² = 36, what are the possible values of x?",
    type: "multiple-choice",
    difficulty: "easy",
    subject: "algebra",
    skillTag: "ALG006",
    options: [
      { label: "A", value: "A", text: "x = 3 only" },
      { label: "B", value: "B", text: "x = -3 only" },
      { label: "C", value: "C", text: "x = -3 or x = 9" },
      { label: "D", value: "D", text: "x = -3 or x = 3" }
    ],
    correctAnswer: "C",
    explanation: "If (x - 3)² = 36, then x - 3 = ±6. So x - 3 = 6 or x - 3 = -6. This gives us x = 9 or x = -3."
  },
  {
    questionId: "GEO002",
    text: "A circle has a circumference of 12π inches. What is its area in square inches?",
    type: "numeric",
    difficulty: "medium",
    subject: "geometry",
    skillTag: "GEO002",
    correctAnswer: "36π",
    explanation: "The circumference of a circle is 2πr, where r is the radius. So 2πr = 12π, which means r = 6. The area of a circle is πr², so the area is π(6)² = 36π square inches."
  },
  {
    questionId: "ALG007",
    text: "The expression 3⁴ × 3² is equivalent to:",
    type: "multiple-choice",
    difficulty: "easy",
    subject: "algebra",
    skillTag: "ALG007",
    options: [
      { label: "A", value: "A", text: "3⁶" },
      { label: "B", value: "B", text: "3⁸" },
      { label: "C", value: "C", text: "6⁶" },
      { label: "D", value: "D", text: "9⁶" }
    ],
    correctAnswer: "A",
    explanation: "Using the law of exponents, 3⁴ × 3² = 3⁴⁺² = 3⁶"
  },
  {
    questionId: "ALG008",
    text: "If f(x) = 2x² - 5x + 3, what is f(3)?",
    type: "numeric",
    difficulty: "easy",
    subject: "algebra",
    skillTag: "ALG008",
    correctAnswer: "12",
    explanation: "f(3) = 2(3)² - 5(3) + 3 = 2(9) - 15 + 3 = 18 - 15 + 3 = 6 + 3 = 12"
  },
  {
    questionId: "ALG009",
    text: "If 2x + 3y = 12 and 3x - y = 7, what is the value of x + y?",
    type: "numeric",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG009",
    correctAnswer: "5",
    explanation: "From the second equation, y = 3x - 7. Substituting this into the first equation: 2x + 3(3x - 7) = 12. Simplifying: 2x + 9x - 21 = 12, so 11x = 33, which means x = 3. Then y = 3(3) - 7 = 9 - 7 = 2. Therefore, x + y = 3 + 2 = 5."
  },
  {
    questionId: "GEO003",
    text: "The figure shows a triangle ABC. If the area of triangle ABC is 24 square units and the height from A to BC is 6 units, what is the length of BC?",
    type: "numeric",
    difficulty: "hard",
    subject: "geometry",
    skillTag: "GEO003",
    correctAnswer: "8",
    explanation: "The area of a triangle is (1/2) × base × height. Given that the area is 24 square units and the height is 6 units, we can solve for the base (BC): 24 = (1/2) × BC × 6. So BC = 24 × 2 / 6 = 8 units."
  },
  {
    questionId: "ALG010",
    text: "Which of the following is equivalent to (x² - 9) / (x - 3)?",
    type: "multiple-choice",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG010",
    options: [
      { label: "A", value: "A", text: "x - 3" },
      { label: "B", value: "B", text: "x + 3" },
      { label: "C", value: "C", text: "x" },
      { label: "D", value: "D", text: "x + 3, for x ≠ 3" }
    ],
    correctAnswer: "D",
    explanation: "We can factor the numerator: (x² - 9) = (x - 3)(x + 3). So (x² - 9) / (x - 3) = (x - 3)(x + 3) / (x - 3) = x + 3, for x ≠ 3 (since x - 3 = 0 when x = 3, and division by zero is undefined)."
  },
  {
    questionId: "ALG011",
    text: "In a geometric sequence, the first term is 6 and the common ratio is 2. What is the 5th term?",
    type: "numeric",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG011",
    correctAnswer: "96",
    explanation: "In a geometric sequence with first term a and common ratio r, the nth term is given by a × r^(n-1). So the 5th term is 6 × 2^(5-1) = 6 × 2^4 = 6 × 16 = 96."
  },
  {
    questionId: "ALG012",
    text: "If log₃(x) = 4, what is the value of x?",
    type: "numeric",
    difficulty: "medium",
    subject: "algebra",
    skillTag: "ALG012",
    correctAnswer: "81",
    explanation: "If log₃(x) = 4, then x = 3^4 = 81."
  },
  {
    questionId: "ALG013",
    text: "Liam and Emma bought books and notebooks from a stationery store. The price of each book was the same, and the price of each notebook was also the same. Liam purchased 6 books and 3 notebooks for $138, while Emma purchased 5 books and 7 notebooks for $250. Which of the following systems of linear equations represents this situation, if 𝑥 represents the price, in dollars, of each book and 𝑦 represents the price, in dollars, of each notebook?",
    type: "multiple-choice",
    difficulty: "easy",
    subject: "algebra",
    skillTag: "ALG013",
    options: [
      { label: "A", value: "A", text: "6𝑥+3𝑦=138 5𝑥+7𝑦=250" },
      { label: "B", value: "B", text: "6𝑥+5𝑦=138 3𝑥+7𝑦=250" },
      { label: "C", value: "C", text: "6𝑥+3𝑦=250 5𝑥+7𝑦=138" },
      { label: "D", value: "D", text: "6𝑥+5𝑦=250 3𝑥+7𝑦=138" }
    ],
    correctAnswer: "A",
    explanation: "Choice A is correct. Liam purchased 6 books, each costing x dollars, for a total of 6x dollars. He also bought 3 notebooks, each costing y dollars, for a total of 3y dollars. Thus, the total amount Liam spent can be represented by 6x+3y=138. Similarly, Emma purchased 5 books at x dollars each and 7 notebooks at y dollars each, for a total of 5x+7y=250."
  },
  {
    questionId: "ALG014",
    text: "8q=24, p-7q=-5 The solution to the given system of equations is (p,q). What is the value of p+q?",
    type: "multiple-choice",
    difficulty: "easy",
    subject: "algebra",
    skillTag: "ALG014",
    options: [
      { label: "A", value: "A", text: "-2" },
      { label: "B", value: "B", text: "-19" },
      { label: "C", value: "C", text: "19" },
      { label: "D", value: "D", text: "29" }
    ],
    correctAnswer: "C",
    explanation: "Choice C is correct. Adding the second equation of the given system to the first equation yields 8q+(p-7q)=24+(-5), which is equivalent to p+q=19. So the value of p+q is 19."
  }
];


// Sample admin user
const adminUser = {
  username: 'admin',
  email: 'admin@example.com',
  password: 'password123',
  role: 'admin',
  isVerified: true
};

// sample normal user
const normalUser = {
  username: 'user',
  email: 'aniket@dshgsonic.com',
  password: 'password123',
  role: 'user',
  isVerified: true
};

// Connect to DB with improved connection handling
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`.cyan.underline);
    return conn;
  } catch (error) {
    console.error(`Error: ${error.message}`.red.underline.bold);
    process.exit(1);
  }
};

// Import data
const importData = async () => {
  try {
    // Connect to database
    await connectDB();

    // Clear existing data
    await Question.deleteMany();
    await User.deleteMany();
    await Game.deleteMany();
    
    console.log('Previous data cleared...'.yellow);

    // Create admin user
    const user = await User.create(adminUser);
    console.log('Admin user created...'.green);

    // Create normal user
    await User.create(normalUser);
    console.log('Normal user created...'.green);
    
    // Get questions from CSV
    const csvQuestions = readSATQuestions();
    console.log(`${csvQuestions.length} questions loaded from CSV file`.cyan);
    
    // Use CSV questions if available, otherwise use original questions
    const questionsToImport = csvQuestions.length > 0 ? csvQuestions : originalQuestions;
    
    // Add created by to questions
    const questionsWithCreator = questionsToImport.map(question => ({
      ...question, 
      createdBy: user._id 
    }));
    
    // Create questions in batches to avoid MongoDB limitations
    const batchSize = 100;
    for (let i = 0; i < questionsWithCreator.length; i += batchSize) {
      const batch = questionsWithCreator.slice(i, i + batchSize);
      await Question.insertMany(batch);
      console.log(`Imported questions ${i+1} to ${Math.min(i+batchSize, questionsWithCreator.length)}`.green);
    }
    
    console.log(`${questionsWithCreator.length} total questions imported!`.green.bold);
    console.log('Data import complete!'.green.inverse);
    process.exit(0);
  } catch (err) {
    console.error(`Error during import: ${err}`.red);
    console.error(err.stack);
    process.exit(1);
  }
};

// Delete data
const deleteData = async () => {
  try {
    // Connect to database
    await connectDB();

    // Clear database
    await Question.deleteMany();
    await User.deleteMany();
    await Game.deleteMany();
    
    console.log('Data destroyed!'.red.inverse);
    process.exit(0);
  } catch (err) {
    console.error(`Error during deletion: ${err}`.red);
    console.error(err.stack);
    process.exit(1);
  }
};

// Command line arguments
const runScript = async () => {
  const arg = process.argv[2];
  
  switch(arg) {
    case '-i':
      await importData();
      break;
    case '-d':
      await deleteData();
      break;
    default:
      console.log(`
Usage:
  Import data: node seeder.js -i
  Delete data: node seeder.js -d
      `.yellow);
      process.exit(0);
  }
};

// Run the script
runScript().catch(console.error);