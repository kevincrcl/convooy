import { prisma } from '../services/database';

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgresql://convooy_user:convooy_password@localhost:5432/convooy_test';

// Mock nanoid to avoid ESM issues
jest.mock('nanoid', () => {
  let counter = 0;
  return {
    customAlphabet: () => () => {
      counter++;
      // Generate a deterministic share code for testing
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      const code = counter.toString().padStart(6, '0').split('').map((digit) => {
        return alphabet[parseInt(digit) % alphabet.length];
      }).join('');
      return code;
    },
  };
});

// Clean up database before each test suite
beforeAll(async () => {
  // Connect to database
  await prisma.$connect();
});

// Clean up database after all tests
afterAll(async () => {
  // Clean up all test data
  await prisma.stop.deleteMany({});
  await prisma.trip.deleteMany({});
  
  // Disconnect from database
  await prisma.$disconnect();
});

// Clean up between tests to ensure isolation
afterEach(async () => {
  await prisma.stop.deleteMany({});
  await prisma.trip.deleteMany({});
});

