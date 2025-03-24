# Brain Blast 

## 🏗 Architecture

Brain Blast follows a clean architecture pattern with clear separation of concerns:

1. **MVC Pattern**: Models, Controllers, Views separated
2. **Service Layer**: Business logic isolated from controllers
3. **Repository Pattern**: Data access abstracted
4. **Middleware Layer**: Request processing and validation
5. **Socket Events**: Organized by feature

### Request Flow:
```
Client Request → Routes → Middleware → Controllers → Services → Models → Database
```

### Real-time Flow:
```
Client Socket Event → Socket Event Handlers → Services → Database → Socket Emission → Client
```

## 📜 Game Rules

1. **Setup**:
   - Players can create new games or join existing ones
   - Players can directly challenge specific opponents
   - Game parameters can be customized (difficulty, subject, rounds)

2. **Gameplay**:
   - Each player answers the same randomly selected SAT math question per round
   - Players take turns answering questions (asynchronously)
   - Each player's timer starts when they begin viewing a question
   - Players receive immediate feedback on their answers

3. **Scoring**:
   - If both players answer correctly, the faster player wins the round
   - If both answer incorrectly, the round is a tie
   - If one answers correctly and the other incorrectly, the correct player wins
   - The first player to win 3 rounds (default, configurable) wins the game

4. **Challenge System**:
   - Players can browse other online users
   - Players can send game challenges with custom settings
   - Challenged players can accept or reject challenges
   - Both players receive real-time notifications about challenge status

## 📚 API Documentation

### Authentication Endpoints

| Endpoint | Method | Description | Access |
|----------|--------|-------------|--------|
| `/api/auth/register` | POST | Register new user | Public |
| `/api/auth/login` | POST | Login user | Public |
| `/api/auth/me` | GET | Get current user | Private |
| `/api/auth/logout` | GET | Logout user | Private |
| `/api/auth/updatedetails` | PUT | Update user details | Private |
| `/api/auth/updatepassword` | PUT | Update password | Private |

### Game Endpoints

| Endpoint | Method | Description | Access |
|----------|--------|-------------|--------|
| `/api/games` | POST | Create new game | Private |
| `/api/games/join` | POST | Join existing game | Private |
| `/api/games/active` | GET | Get active games | Private |
| `/api/games/history` | GET | Get game history | Private |
| `/api/games/:gameCode` | GET | Get game state | Private |
| `/api/games/:gameCode/answer` | POST | Submit answer | Private |
| `/api/games/:gameCode/abandon` | PUT | Abandon game | Private |
| `/api/games/challenge` | POST | Challenge another user | Private |
| `/api/games/challenge/:gameCode/respond` | PUT | Respond to challenge | Private |
| `/api/games/challenges` | GET | Get all challenges | Private |

### User Endpoints

| Endpoint | Method | Description | Access |
|----------|--------|-------------|--------|
| `/api/users/profile/:username` | GET | Get user profile | Public |
| `/api/users/leaderboard` | GET | Get leaderboard | Public |
| `/api/users/stats` | GET | Get current user stats | Private |
| `/api/users/online` | GET | Get online users | Private |
| `/api/users` | GET | Get all users | Admin |
| `/api/users/:id` | GET | Get user by ID | Admin |
| `/api/users/:id` | PUT | Update user | Admin |
| `/api/users/:id` | DELETE | Delete user | Admin |

### Question Endpoints

| Endpoint | Method | Description | Access |
|----------|--------|-------------|--------|
| `/api/questions/random` | GET | Get random question | Private |
| `/api/questions` | GET | Get all questions | Admin |
| `/api/questions` | POST | Create question | Admin |
| `/api/questions/import` | POST | Bulk import questions | Admin |
| `/api/questions/:id` | GET | Get question by ID | Admin |
| `/api/questions/:id` | PUT | Update question | Admin |
| `/api/questions/:id` | DELETE | Delete question | Admin |

## 🔌 Socket.io Events

### Connection Events
- `connect`: Client connected
- `disconnect`: Client disconnected

### Game Events
- `game:join`: Join a game room with game code
- `game:state`: Get current game state
- `game:submitAnswer`: Submit answer for current round
- `game:answerProcessed`: Answer has been processed
- `game:roundComplete`: Round is complete
- `game:complete`: Game is complete
- `game:yourTurn`: Notify player it's their turn
- `game:playerConnected`: Player has connected
- `game:playerDisconnected`: Player has disconnected

### User Status Events
- `user:online`: User is online
- `user:status`: User status has changed

### Challenge Events
- `challenge:received`: New challenge received
- `challenge:response`: Response to a challenge
- `challenge:message`: Direct message related to challenge

## 🚀 Installation

### Prerequisites
- Node.js (v14.x or higher)
- MongoDB (v4.x or higher)
- npm or yarn

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/PodcastGuru/BrainBlast.git
   cd BrainBlast/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.sample .env
   # Edit .env file with your configuration
   ```

4. **Seed the database with sample questions**
   ```bash
   node utils/seeder.js -i
   ```

5. **Start the development server**
   ```bash
   npm run dev
   ```

6. **For production**
   ```bash
   npm run start
   ```

## 🔑 Environment Variables

Create a `.env` file in the root directory with the following variables:

```dotenv
# Server Configuration
NODE_ENV=development
PORT=5000

# MongoDB
MONGO_URI=mongodb://localhost:27017/test

# JWT
JWT_SECRET=your_jwt_secret_key_change_this_in_production
JWT_EXPIRE=30d
JWT_COOKIE_EXPIRE=30

# Client
CLIENT_URL=http://localhost:3000

# Logging
LOG_LEVEL=debug
```

## 🔄 Project Flow

### Standard Game Flow

1. **Game Creation**
   - Player 1 creates a game via API
   - Backend generates a game code
   - Player 1 connects to socket.io with game code

2. **Game Joining**
   - Player 2 joins with game code via API
   - Backend adds player to game, creates first round
   - Both players connect to socket.io with game code
   - Backend notifies Player 1 it's their turn

3. **Gameplay Loop**
   - Current player receives notification
   - Player submits answer via socket
   - Backend processes answer, switches turn
   - Next player receives turn notification
   - After both players answer, backend evaluates round
   - Both players receive round results
   - Process repeats until win condition met

4. **Game Completion**
   - Backend determines winner
   - Both players receive game completion notification
   - Player statistics are updated
