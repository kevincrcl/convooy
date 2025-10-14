import { customAlphabet } from 'nanoid';

// Create a custom alphabet for share codes (no confusing characters like 0/O, 1/I/l)
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const generateId = customAlphabet(alphabet, parseInt(process.env.SHARE_CODE_LENGTH || '6'));

/**
 * Generate a unique share code for trips
 * Uses a custom alphabet to avoid confusing characters
 */
export function generateShareCode(): string {
  return generateId();
}

/**
 * Validate share code format
 */
export function isValidShareCode(code: string): boolean {
  const length = parseInt(process.env.SHARE_CODE_LENGTH || '6');
  return (
    typeof code === 'string' &&
    code.length === length &&
    /^[A-Z0-9]+$/.test(code) &&
    !code.includes('0') && // No zeros
    !code.includes('O') && // No capital O
    !code.includes('1') && // No ones
    !code.includes('I')    // No capital I
  );
}

/**
 * Format share code for display (add hyphens for readability)
 */
export function formatShareCode(code: string): string {
  if (code.length <= 4) return code;
  
  // Insert hyphen in the middle for codes longer than 4 characters
  const mid = Math.ceil(code.length / 2);
  return `${code.slice(0, mid)}-${code.slice(mid)}`;
}

/**
 * Clean share code (remove hyphens and convert to uppercase)
 */
export function cleanShareCode(code: string): string {
  return code.replace(/[-\s]/g, '').toUpperCase();
}
