import { Request, Response, NextFunction } from 'express';
import { validateBody, validateParams, validateQuery } from '../validation';
import { z } from 'zod';

describe('Validation Middleware', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let mockNext: NextFunction;
  let statusMock: jest.Mock;
  let jsonMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    
    mockReq = {
      body: {},
      params: {},
      query: {},
    };
    
    mockRes = {
      status: statusMock,
    };
    
    mockNext = jest.fn();
  });

  describe('validateBody', () => {
    const TestSchema = z.object({
      name: z.string().min(1, 'Name is required'),
      age: z.number().min(0).max(120),
      email: z.string().email().optional(),
    });

    it('should pass validation with valid data', () => {
      mockReq.body = {
        name: 'John Doe',
        age: 30,
        email: 'john@example.com',
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(statusMock).not.toHaveBeenCalled();
    });

    it('should pass validation without optional fields', () => {
      mockReq.body = {
        name: 'Jane',
        age: 25,
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(statusMock).not.toHaveBeenCalled();
    });

    it('should reject validation with missing required fields', () => {
      mockReq.body = {
        age: 30,
        // Missing name
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
      expect(jsonMock).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: 'ValidationError',
          message: 'Invalid request data',
        })
      );
    });

    it('should reject validation with invalid data types', () => {
      mockReq.body = {
        name: 'John',
        age: 'thirty', // Should be number
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
    });

    it('should reject validation with out of range values', () => {
      mockReq.body = {
        name: 'John',
        age: 150, // Exceeds max
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
    });

    it('should reject validation with invalid email format', () => {
      mockReq.body = {
        name: 'John',
        age: 30,
        email: 'not-an-email',
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
    });

    it('should transform and use validated data', () => {
      mockReq.body = {
        name: 'John',
        age: 30,
        extraField: 'ignored', // Should be stripped
      };

      const middleware = validateBody(TestSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockReq.body).toEqual({
        name: 'John',
        age: 30,
      });
    });
  });

  describe('validateParams', () => {
    const ParamsSchema = z.object({
      id: z.string().min(1),
      category: z.enum(['trip', 'stop']).optional(),
    });

    it('should validate valid params', () => {
      mockReq.params = {
        id: 'abc123',
        category: 'trip',
      };

      const middleware = validateParams(ParamsSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(statusMock).not.toHaveBeenCalled();
    });

    it('should reject empty required params', () => {
      mockReq.params = {
        id: '',
      };

      const middleware = validateParams(ParamsSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
    });

    it('should reject invalid enum values', () => {
      mockReq.params = {
        id: 'abc123',
        category: 'invalid',
      };

      const middleware = validateParams(ParamsSchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
    });
  });

  describe('validateQuery', () => {
    const QuerySchema = z.object({
      page: z.string().regex(/^\d+$/).transform(Number).optional(),
      limit: z.string().regex(/^\d+$/).transform(Number).optional(),
      search: z.string().optional(),
    });

    it('should validate valid query params', () => {
      mockReq.query = {
        page: '1',
        limit: '10',
        search: 'test',
      };

      const middleware = validateQuery(QuerySchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(statusMock).not.toHaveBeenCalled();
    });

    it('should handle empty query params', () => {
      mockReq.query = {};

      const middleware = validateQuery(QuerySchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });

    it('should reject invalid query param format', () => {
      mockReq.query = {
        page: 'abc', // Not a number
      };

      const middleware = validateQuery(QuerySchema);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(400);
    });
  });
});

