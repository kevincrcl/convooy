# Convooy Backend API

A TypeScript backend API for sharing navigation trips with multiple users. Allows users to create trips with destinations and collaboratively add stops along the way.

## Features

- 🚗 **Trip Management**: Create, update, and share navigation trips
- 📍 **Stop Management**: Add, remove, and reorder stops collaboratively
- 🔗 **Easy Sharing**: Share trips via simple codes or URLs
- ⚡ **Real-time Updates**: Live synchronization using WebSockets
- 🛡️ **Type Safety**: Full TypeScript implementation with Zod validation
- 🗄️ **Database**: PostgreSQL with Prisma ORM
- 🐳 **Docker Ready**: Complete containerization setup

## Quick Start

### Prerequisites

- Node.js 22+ 
- PostgreSQL 15+
- npm or yarn

### Development Setup

1. **Clone and install dependencies**
```bash
cd backend
npm install
```

2. **Set up environment variables**
```bash
cp env.example .env
# Edit .env with your database credentials
```

3. **Start PostgreSQL** (using Docker)
```bash
docker-compose up postgres -d
```

4. **Set up database**
```bash
npm run db:push
npm run db:generate
```

5. **Start development server**
```bash
npm run dev
```

The API will be available at `http://localhost:3001`

### Using Docker (Recommended)

```bash
# Start all services (PostgreSQL + API)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

## API Endpoints

### Trip Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/trips` | Create new trip |
| GET | `/api/trips/:shareCode` | Get trip details |
| PUT | `/api/trips/:shareCode` | Update trip |
| DELETE | `/api/trips/:shareCode` | Delete trip |

### Stop Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/trips/:shareCode/stops` | Add stop to trip |
| GET | `/api/trips/:shareCode/stops` | Get all stops |
| PUT | `/api/trips/:shareCode/stops/:stopId` | Update stop |
| DELETE | `/api/trips/:shareCode/stops/:stopId` | Remove stop |
| PUT | `/api/trips/:shareCode/stops/reorder` | Reorder stops |

### Sharing

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/trips/:shareCode/share` | Get sharing info |
| POST | `/api/trips/join/:shareCode` | Join existing trip |

## Data Models

### Trip
```typescript
{
  id: string;
  shareCode: string;        // 6-character code (e.g., "ABC123")
  name?: string;           // Optional trip name
  destination: {           // Final destination
    name: string;
    latitude: number;
    longitude: number;
    address?: string;
  };
  stops: Stop[];           // Ordered list of stops
  createdAt: string;
  updatedAt: string;
}
```

### Stop
```typescript
{
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  address?: string;
  order: number;           // Position in trip (0-based)
  addedAt: string;
}
```

## Real-time Events

Connect to WebSocket at `/` and listen for these events:

- `trip:updated` - Trip details changed
- `stop:added` - New stop added
- `stop:removed` - Stop removed
- `stop:updated` - Stop details changed
- `stops:reordered` - Stops reordered
- `trip:joined` - Someone joined the trip

### Example Usage

```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3001');

// Join a trip room
socket.emit('join-trip', 'ABC123');

// Listen for updates
socket.on('stop:added', (data) => {
  console.log('New stop added:', data.stop);
});
```

## Environment Variables

```bash
# Database
DATABASE_URL="postgresql://username:password@localhost:5432/convooy_db"

# Server
PORT=3001
NODE_ENV=development

# CORS
CORS_ORIGIN="http://localhost:3000,http://localhost:5173"

# Trip Configuration
SHARE_CODE_LENGTH=6
TRIP_EXPIRY_DAYS=30
```

## Development

### Available Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run db:generate` - Generate Prisma client
- `npm run db:push` - Push schema to database
- `npm run db:migrate` - Run database migrations
- `npm run db:studio` - Open Prisma Studio
- `npm run lint` - Run ESLint
- `npm test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:setup` - Set up test database

### Database Management

```bash
# Reset database
npm run db:push --force-reset

# View data in browser
npm run db:studio

# Create migration
npm run db:migrate
```

### Testing

The backend includes comprehensive tests for all API endpoints with **104 tests** running in parallel for fast feedback.

#### Quick Start

Tests automatically start the database if it's not running:

```bash
# Run all tests (auto-starts database if needed)
yarn test

# Run tests in watch mode
yarn test:watch
```

**No manual setup required!** The test commands automatically:
1. Check if PostgreSQL is running and start it if needed
2. Create the test database if it doesn't exist
3. Run your tests in parallel

#### Test Architecture

Tests use the **Factory Pattern** for automatic resource management:

```typescript
describe('My Tests', () => {
  let factory: TestFactory;

  beforeEach(() => {
    factory = new TestFactory();
  });

  afterEach(async () => {
    await factory.cleanup(); // Auto-cleanup
  });

  it('should work', async () => {
    const trip = await factory.createTrip({ name: 'Test' });
    const stop = await factory.createStop(trip.body.data.shareCode);
    // Test code here - cleanup is automatic
  });
});
```

**Key Features:**
- ✅ **Parallel execution** - tests run simultaneously for speed
- ✅ **Automatic cleanup** - each test cleans up only its own resources
- ✅ **True isolation** - tests never interfere with each other
- ✅ **No manual tracking** - factory handles everything automatically

See `tests/factory.ts` for all available helper methods.

#### Test Suite

**104 tests** covering:

**Integration Tests (60+ tests):**
- Trip management (CRUD operations)
- Stop management (add, update, remove, reorder)
- Trip sharing and joining
- Complete lifecycle scenarios

**Unit Tests (44 tests):**
- Validation middleware
- Share code utilities
- Error handling

#### CI/CD

Tests run automatically on:
- **Pull Requests** to `main` that modify `backend/` files
- **Pushes** to `main` branch

The GitHub Actions workflow:
1. Starts PostgreSQL test database
2. Installs dependencies and generates Prisma client
3. Runs all tests in parallel
4. Reports pass/fail status

See `.github/workflows/backend-tests.yml` for details.

## iOS Integration

The backend provides REST APIs that can be easily integrated into the existing iOS app:

```swift
// Example iOS integration
class TripSyncService {
    func createTrip(destination: SearchResult) async -> String? {
        // POST /api/trips
    }
    
    func joinTrip(shareCode: String) async -> Trip? {
        // GET /api/trips/:shareCode
    }
    
    func addStop(stop: Stop, to shareCode: String) async {
        // POST /api/trips/:shareCode/stops
    }
}
```

## Production Deployment

1. **Build the application**
```bash
npm run build
```

2. **Set production environment variables**

3. **Deploy using Docker**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details
