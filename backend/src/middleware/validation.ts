import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { sendErrorResponse } from '../utils/errors';

/**
 * Middleware to validate request body against a Zod schema
 */
export function validateBody<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        sendErrorResponse(res, error);
      } else {
        sendErrorResponse(res, new Error('Validation failed'));
      }
    }
  };
}

/**
 * Middleware to validate request params against a Zod schema
 */
export function validateParams<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.params = schema.parse(req.params);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        sendErrorResponse(res, error);
      } else {
        sendErrorResponse(res, new Error('Parameter validation failed'));
      }
    }
  };
}

/**
 * Middleware to validate request query against a Zod schema
 */
export function validateQuery<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.query = schema.parse(req.query);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        sendErrorResponse(res, error);
      } else {
        sendErrorResponse(res, new Error('Query validation failed'));
      }
    }
  };
}
