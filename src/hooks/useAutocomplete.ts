import { useState, useEffect, useCallback, useRef } from 'react';

export function useAutocomplete({
  fetchSuggestions,
  minLength = 3,
  debounceMs = 300,
}: {
  fetchSuggestions: (query: string) => Promise<any[]>;
  minLength?: number;
  debounceMs?: number;
}) {
  const [value, setValue] = useState('');
  const [suggestions, setSuggestions] = useState<any[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const timeoutRef = useRef<number | undefined>(undefined);

  useEffect(() => {
    if (value.length < minLength) {
      setSuggestions([]);
      return;
    }

    // Clear previous timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    // Set new timeout for debounced API call
    timeoutRef.current = window.setTimeout(async () => {
      let ignore = false;
      const results = await fetchSuggestions(value);
      if (!ignore) setSuggestions(results);
    }, debounceMs);

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [value, fetchSuggestions, minLength, debounceMs]);

  const onFocus = useCallback(() => setShowSuggestions(true), []);
  const onBlur = useCallback(() => setTimeout(() => setShowSuggestions(false), 100), []);

  const onSuggestionClick = useCallback((feature: any) => {
    // Don't automatically set the value - let parent handle it
    setSuggestions([]);
    setShowSuggestions(false);
  }, []);

  return {
    value,
    setValue,
    suggestions,
    showSuggestions,
    onFocus,
    onBlur,
    onSuggestionClick,
  };
} 