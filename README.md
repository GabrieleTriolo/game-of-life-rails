# Conway's Game of Life - Rails Implementation

A real-time implementation of Conway's Game of Life using Ruby on Rails with WebSocket communication for live updates.

## 🎮 Features

- **Real-time simulation** using WebSocket (ActionCable)
- **User authentication** with Devise
- **File upload** to initialize game state
- **Live grid updates** with smooth CSS transitions
- **Background processing** with Sidekiq
- **Docker containerization** for easy deployment

## 🛠️ Technology Stack

### Backend
- **Ruby on Rails 7.1** - Web framework
- **PostgreSQL** - Database
- **Redis** - Cache and ActionCable adapter
- **Sidekiq** - Background job processing

### Frontend
- **Stimulus.js** - JavaScript framework
- **ActionCable** - WebSocket communication
- **Turbo** - SPA-like navigation

### Infrastructure
- **Docker & Docker Compose** - Containerization

## 🚀 Getting Started

### Prerequisites

- Docker
- Docker Compose

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd game-of-life-rails
```

2. Build and start the containers:
```bash
docker-compose up --build
```

Or separately:
```bash
docker-compose build
docker-compose up
```

3. The application will be available at `http://localhost:3000`

### Test User

A demo user is automatically created via seeds:

- **Email**: `user@user.it`
- **Password**: `password`

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  encrypted_password VARCHAR NOT NULL,
  reset_password_token VARCHAR UNIQUE,
  reset_password_sent_at TIMESTAMP,
  remember_created_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Simulations Table
```sql
CREATE TABLE simulations (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  generation INTEGER,              -- Current generation number
  rows INTEGER,                    -- Grid height
  cols INTEGER,                    -- Grid width
  grid JSONB,                      -- Current grid state (2D array)
  grid_initial JSONB,              -- Initial grid state (for reset)
  generation_initial INTEGER,      -- Initial generation number
  status VARCHAR,                  -- 'pending', 'running', or 'finished'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**Key Fields:**
- `grid`: Stores the current state of the game as a 2D JSON array (`*` = alive, `.` = dead)
- `status`: Tracks simulation state (pending/running/finished)
- `grid_initial`: Stores the initial configuration for potential resets

## 🔌 WebSocket Architecture

The application uses **ActionCable** (Rails' WebSocket implementation) for real-time communication:

### Flow:

1. **User clicks "Start"** → HTTP request to `/api/simulations/:id/start`
2. **Rails enqueues background job** → `SimulationRunnerJob` via Sidekiq
3. **Job calculates next generation** → Updates database
4. **Job broadcasts via WebSocket** → Through ActionCable to subscribed clients
5. **Browser receives update** → Stimulus controller updates the DOM
6. **Repeat** until stopped or stable configuration reached

### Channel Structure:

```ruby
# Server-side (Ruby)
ActionCable.server.broadcast(
  "simulation:#{sim.id}:user:#{user.id}",
  { generation: 42, grid: [[...]], html: "..." }
)
```

```javascript
// Client-side (JavaScript)
consumer.subscriptions.create(
  { channel: "SimulationChannel", simulation_id: simId },
  {
    received(data) {
      // Update UI with data.generation, data.grid
    }
  }
)
```

## 🎲 Game Rules

Conway's Game of Life follows these rules:

1. Any live cell with < 2 live neighbors dies (underpopulation)
2. Any live cell with 2-3 live neighbors survives
3. Any live cell with > 3 live neighbors dies (overpopulation)
4. Any dead cell with exactly 3 live neighbors becomes alive (reproduction)

### Special Features:

- **Wrapping grid**: Edges wrap around (toroidal topology)
- **Auto-stop conditions**:
  - Stable configuration detected (pattern doesn't change)
  - All cells dead

## 📁 Input File Format

Upload a `.txt` file with the following format:

```
Generation 0:
5 5
.....
..*..
..**.
.....
.....
```

- **Line 1**: `Generation N:` (N = starting generation number)
- **Line 2**: `rows cols` (grid dimensions)
- **Lines 3+**: Grid state (`*` = alive, `.` = dead)

## 🗄️ Database Interaction

### Access PostgreSQL container:

```bash
docker exec -it gameoflife-db bash
psql -U postgres -d game_of_life_development
```

### Useful commands:

```sql
-- List all tables
\dt

-- View all users
SELECT * FROM users;

-- View all simulations
SELECT id, user_id, generation, status, created_at FROM simulations;

-- Exit
\q
```

## 🐛 Debugging

### View logs:

```bash
# Web server
docker logs -f gameoflife-web

# Background jobs
docker logs -f gameoflife-sidekiq

# Database
docker logs -f gameoflife-db
```

### Rails console:

```bash
docker-compose exec web rails console
```

## 📦 Services

The application runs 4 Docker containers:

1. **web** - Rails application (port 3000)
2. **sidekiq** - Background job processor
3. **db** - PostgreSQL database (port 5432)
4. **redis** - Cache and ActionCable adapter (port 6379)

## 🔧 Development

### Reset database:

```bash
docker-compose exec web rails db:drop db:create db:migrate db:seed
```

### Run migrations:

```bash
docker-compose exec web rails db:migrate
```

### Access Rails console:

```bash
docker-compose exec web rails console
```

## 🧪 Testing

The project includes comprehensive unit tests for all core logic.

### Run all tests:

```bash
# Ensure containers are running first
docker-compose up -d

# Run the entire test suite
docker-compose exec web rails test
```