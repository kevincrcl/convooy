import React, { useRef } from 'react';
import Box from '@mui/material/Box';

interface LocationSearchInputProps {
  value: string;
  onChange: (v: string) => void;
  onFocus: () => void;
  onBlur: () => void;
  suggestions: any[];
  showSuggestions: boolean;
  onSuggestionClick: (feature: any) => void;
  placeholder: string;
  button?: React.ReactNode;
}

export const LocationSearchInput: React.FC<LocationSearchInputProps> = ({
  value,
  onChange,
  onFocus,
  onBlur,
  suggestions,
  showSuggestions,
  onSuggestionClick,
  placeholder,
  button,
}) => {
  const inputRef = useRef<HTMLInputElement>(null);

  return (
    <Box sx={{ display: 'flex', gap: 1, position: 'relative' }}>
      <input
        ref={inputRef}
        placeholder={placeholder}
        style={{ flex: 1, padding: 8, borderRadius: 4, border: '1px solid #ccc' }}
        value={value}
        onChange={e => onChange(e.target.value)}
        onFocus={onFocus}
        onBlur={onBlur}
        autoComplete="off"
      />
      {button}
      {showSuggestions && suggestions.length > 0 && (
        <Box sx={{ position: 'absolute', top: 40, left: 0, right: 0, zIndex: 10, bgcolor: '#fff', border: '1px solid #ccc', borderRadius: 1, boxShadow: 2 }}>
          {suggestions.map((feature) => (
            <Box
              key={feature.id}
              sx={{ p: 1, cursor: 'pointer', '&:hover': { bgcolor: '#f5f5f5' } }}
              onMouseDown={() => onSuggestionClick(feature)}
            >
              {feature.place_name}
            </Box>
          ))}
        </Box>
      )}
    </Box>
  );
}; 