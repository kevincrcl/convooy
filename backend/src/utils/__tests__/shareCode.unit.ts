import { 
  formatShareCode, 
  cleanShareCode, 
  isValidShareCode 
} from '../shareCode';

describe('Share Code Utils', () => {
  describe('formatShareCode', () => {
    it('should format 6-character code with hyphen', () => {
      expect(formatShareCode('ABC123')).toBe('ABC-123');
    });

    it('should format 8-character code with hyphen', () => {
      expect(formatShareCode('ABCD1234')).toBe('ABCD-1234');
    });

    it('should not format short codes', () => {
      expect(formatShareCode('ABC')).toBe('ABC');
      expect(formatShareCode('AB12')).toBe('AB12');
    });

    it('should handle odd-length codes', () => {
      expect(formatShareCode('ABC12')).toBe('ABC-12');
      expect(formatShareCode('ABCDE12')).toBe('ABCD-E12');
    });
  });

  describe('cleanShareCode', () => {
    it('should remove hyphens', () => {
      expect(cleanShareCode('ABC-123')).toBe('ABC123');
    });

    it('should remove spaces', () => {
      expect(cleanShareCode('ABC 123')).toBe('ABC123');
    });

    it('should convert to uppercase', () => {
      expect(cleanShareCode('abc123')).toBe('ABC123');
    });

    it('should handle mixed separators', () => {
      expect(cleanShareCode('abc-123 xyz')).toBe('ABC123XYZ');
    });

    it('should handle already clean codes', () => {
      expect(cleanShareCode('ABC123')).toBe('ABC123');
    });
  });

  describe('isValidShareCode', () => {
    beforeEach(() => {
      // Set default length
      process.env.SHARE_CODE_LENGTH = '6';
    });

    it('should validate correct share codes', () => {
      expect(isValidShareCode('ABC234')).toBe(true); // No confusing chars
      expect(isValidShareCode('ABCDEF')).toBe(true);
      expect(isValidShareCode('234567')).toBe(true);
    });

    it('should reject codes with wrong length', () => {
      expect(isValidShareCode('ABC')).toBe(false);
      expect(isValidShareCode('ABC12345')).toBe(false);
    });

    it('should reject codes with zeros', () => {
      expect(isValidShareCode('ABC023')).toBe(false);
    });

    it('should reject codes with capital O', () => {
      expect(isValidShareCode('ABCO23')).toBe(false);
    });

    it('should reject codes with ones', () => {
      expect(isValidShareCode('ABC234')).toBe(true); // No 1
      expect(isValidShareCode('ABC123')).toBe(false); // Has 1
    });

    it('should reject codes with capital I', () => {
      expect(isValidShareCode('ABCI23')).toBe(false);
    });

    it('should reject lowercase codes', () => {
      expect(isValidShareCode('abc123')).toBe(false);
    });

    it('should reject codes with special characters', () => {
      expect(isValidShareCode('ABC-23')).toBe(false);
      expect(isValidShareCode('ABC_23')).toBe(false);
    });

    it('should reject non-string values', () => {
      expect(isValidShareCode(null as any)).toBe(false);
      expect(isValidShareCode(undefined as any)).toBe(false);
      expect(isValidShareCode(123 as any)).toBe(false);
    });
  });
});

