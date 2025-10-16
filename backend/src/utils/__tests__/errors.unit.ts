import {
  AppError,
  NotFoundError,
  ValidationError,
  ConflictError,
  BadRequestError,
  formatErrorResponse,
} from '../errors';
import { ZodError } from 'zod';

describe('Error Utils', () => {
  describe('Error Classes', () => {
    it('should create AppError with defaults', () => {
      const error = new AppError('Test error');
      expect(error.message).toBe('Test error');
      expect(error.statusCode).toBe(500);
      expect(error.isOperational).toBe(true);
    });

    it('should create AppError with custom status code', () => {
      const error = new AppError('Custom error', 418);
      expect(error.statusCode).toBe(418);
    });

    it('should create NotFoundError', () => {
      const error = new NotFoundError('User');
      expect(error.message).toBe('User not found');
      expect(error.statusCode).toBe(404);
    });

    it('should create NotFoundError with default message', () => {
      const error = new NotFoundError();
      expect(error.message).toBe('Resource not found');
    });

    it('should create ValidationError', () => {
      const error = new ValidationError('Invalid input');
      expect(error.message).toBe('Invalid input');
      expect(error.statusCode).toBe(400);
    });

    it('should create ConflictError', () => {
      const error = new ConflictError('Duplicate entry');
      expect(error.message).toBe('Duplicate entry');
      expect(error.statusCode).toBe(409);
    });

    it('should create BadRequestError', () => {
      const error = new BadRequestError('Bad data');
      expect(error.message).toBe('Bad data');
      expect(error.statusCode).toBe(400);
    });
  });

  describe('formatErrorResponse', () => {
    it('should format AppError', () => {
      const error = new NotFoundError('Trip');
      const formatted = formatErrorResponse(error);

      expect(formatted).toEqual({
        error: 'NotFoundError',
        message: 'Trip not found',
        statusCode: 404,
      });
    });

    it('should format ZodError', () => {
      const zodError = new ZodError([
        {
          code: 'invalid_type',
          expected: 'string',
          received: 'number',
          path: ['name'],
          message: 'Expected string, received number',
        },
      ]);

      const formatted = formatErrorResponse(zodError);

      expect(formatted).toEqual({
        error: 'ValidationError',
        message: 'Invalid request data',
        statusCode: 400,
        details: expect.any(Array),
      });
    });

    it('should format generic Error in development', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const error = new Error('Something went wrong');
      const formatted = formatErrorResponse(error);

      expect(formatted).toEqual({
        error: 'InternalServerError',
        message: 'Something went wrong',
        statusCode: 500,
      });

      process.env.NODE_ENV = originalEnv;
    });

    it('should format generic Error in production', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const error = new Error('Internal error');
      const formatted = formatErrorResponse(error);

      expect(formatted).toEqual({
        error: 'InternalServerError',
        message: 'An unexpected error occurred',
        statusCode: 500,
      });

      process.env.NODE_ENV = originalEnv;
    });

    it('should format unknown error types', () => {
      const formatted = formatErrorResponse({ weird: 'object' });

      expect(formatted).toEqual({
        error: 'UnknownError',
        message: 'An unexpected error occurred',
        statusCode: 500,
      });
    });

    it('should format null/undefined errors', () => {
      expect(formatErrorResponse(null)).toEqual({
        error: 'UnknownError',
        message: 'An unexpected error occurred',
        statusCode: 500,
      });

      expect(formatErrorResponse(undefined)).toEqual({
        error: 'UnknownError',
        message: 'An unexpected error occurred',
        statusCode: 500,
      });
    });
  });
});

