import { Response } from 'express';
import { ZodError } from 'zod';
import { ApiError } from '../models/types';

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number = 500, isOperational: boolean = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string = 'Resource') {
    super(`${resource} not found`, 404);
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed') {
    super(message, 400);
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Resource already exists') {
    super(message, 409);
  }
}

export class BadRequestError extends AppError {
  constructor(message: string = 'Bad request') {
    super(message, 400);
  }
}

/**
 * Format error response for API
 */
export function formatErrorResponse(error: unknown): ApiError {
  if (error instanceof AppError) {
    return {
      error: error.constructor.name,
      message: error.message,
      statusCode: error.statusCode,
    };
  }

  if (error instanceof ZodError) {
    return {
      error: 'ValidationError',
      message: 'Invalid request data',
      statusCode: 400,
      details: error.errors,
    };
  }

  if (error instanceof Error) {
    return {
      error: 'InternalServerError',
      message: process.env.NODE_ENV === 'production' 
        ? 'An unexpected error occurred' 
        : error.message,
      statusCode: 500,
    };
  }

  return {
    error: 'UnknownError',
    message: 'An unexpected error occurred',
    statusCode: 500,
  };
}

/**
 * Send error response
 */
export function sendErrorResponse(res: Response, error: unknown): void {
  const errorResponse = formatErrorResponse(error);
  
  // Log error for debugging (in production, use proper logging service)
  if (errorResponse.statusCode >= 500) {
    console.error('Server Error:', error);
  } else if (errorResponse.statusCode >= 400 && process.env.NODE_ENV === 'development') {
    // Log client errors in development for debugging
    console.warn('Client Error:', {
      error: errorResponse.error,
      message: errorResponse.message,
      statusCode: errorResponse.statusCode
    });
  }

  res.status(errorResponse.statusCode).json({
    success: false,
    ...errorResponse
  });
}
