import { prisma } from '../src/services/database';

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgresql://convooy_user:convooy_password@localhost:5432/convooy_test';

// No need to mock nanoid - it works fine with Jest and provides truly unique IDs
// The real nanoid is cryptographically strong and guaranteed to be unique

// Clean up database before each test suite
beforeAll(async () => {
  // Connect to database
  await prisma.$connect();
});

// Clean up database after all tests
afterAll(async () => {
  // Clean up any leftover test data (shouldn't be any if tests use factory properly)
  await prisma.stop.deleteMany({});
  await prisma.trip.deleteMany({});

  // Disconnect from database
  await prisma.$disconnect();
});

// Note: Individual test cleanup is now handled by TestFactory in each test's afterEach
// No global afterEach cleanup needed - tests manage their own resources

