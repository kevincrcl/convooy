import { useState, useEffect, useCallback } from 'react';

export function useAutocomplete({
  fetchSuggestions,
  minLength = 3,
}: {
  fetchSuggestions: (query: string) => Promise<any[]>;
  minLength?: number;
}) {
  const [value, setValue] = useState('');
  const [suggestions, setSuggestions] = useState<any[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);

  useEffect(() => {
    if (value.length < minLength) {
      setSuggestions([]);
      return;
    }
    let ignore = false;
    async function getSuggestions() {
      const results = await fetchSuggestions(value);
      if (!ignore) setSuggestions(results);
    }
    getSuggestions();
    return () => {
      ignore = true;
    };
  }, [value, fetchSuggestions, minLength]);

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