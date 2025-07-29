import React, { useRef } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Drawer from '@mui/material/Drawer';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import type { Stop, Location } from '../types';
import { LocationSearchInput } from './LocationSearchInput';
import { DraggableStopList } from './DraggableStopList';

interface SidebarProps {
  drawerWidth: number;
  startSearchInput: string;
  setStartSearchInput: (v: string) => void;
  startSuggestions: any[];
  showStartSuggestions: boolean;
  handleStartInputFocus: () => void;
  handleStartInputBlur: () => void;
  handleStartSuggestionClick: (feature: any) => void;
  resetToCurrentLocation: () => void;
  endSearchInput: string;
  setEndSearchInput: (v: string) => void;
  endSuggestions: any[];
  showEndSuggestions: boolean;
  handleEndInputFocus: () => void;
  handleEndInputBlur: () => void;
  handleEndSuggestionClick: (feature: any) => void;
  endLocation: Location | null;
  handleClearEndLocation: () => void;
  stops: Stop[];
  stopSearchInput: string;
  setStopSearchInput: (v: string) => void;
  stopSuggestions: any[];
  showStopSuggestions: boolean;
  handleStopInputFocus: () => void;
  handleStopInputBlur: () => void;
  handleStopSuggestionClick: (feature: any) => void;
  handleRemoveStop: (idx: number) => void;
  handleDragEnd: (result: any) => void;
  activePOICategories: Set<string>;
  togglePOICategory: (category: string) => void;
  hasRoute: boolean;
}

export const Sidebar: React.FC<SidebarProps> = ({
  drawerWidth,
  startSearchInput,
  setStartSearchInput,
  startSuggestions,
  showStartSuggestions,
  handleStartInputFocus,
  handleStartInputBlur,
  handleStartSuggestionClick,
  resetToCurrentLocation,
  endSearchInput,
  setEndSearchInput,
  endSuggestions,
  showEndSuggestions,
  handleEndInputFocus,
  handleEndInputBlur,
  handleEndSuggestionClick,
  endLocation,
  handleClearEndLocation,
  stops,
  stopSearchInput,
  setStopSearchInput,
  stopSuggestions,
  showStopSuggestions,
  handleStopInputFocus,
  handleStopInputBlur,
  handleStopSuggestionClick,
  handleRemoveStop,
  handleDragEnd,
  activePOICategories,
  togglePOICategory,
  hasRoute,
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const endInputRef = useRef<HTMLInputElement>(null);
  const stopInputRef = useRef<HTMLInputElement>(null);

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        [`& .MuiDrawer-paper`]: {
          width: drawerWidth,
          boxSizing: 'border-box',
        },
      }}
    >
      <Box sx={{ p: 2, display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Typography variant="h5" gutterBottom>
          Trip Planner
        </Typography>
        {/* Trip Controls */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="subtitle1" gutterBottom>
            Trip Controls
          </Typography>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, position: 'relative' }}>
            <LocationSearchInput
              value={startSearchInput}
              onChange={setStartSearchInput}
              onFocus={handleStartInputFocus}
              onBlur={handleStartInputBlur}
              suggestions={startSuggestions}
              showSuggestions={showStartSuggestions}
              onSuggestionClick={handleStartSuggestionClick}
              placeholder="Start location"
              button={
                <button
                  type="button"
                  style={{ padding: '8px 12px', borderRadius: 4, border: '1px solid #1976d2', background: '#fff', color: '#1976d2', fontWeight: 600, cursor: 'pointer' }}
                  onClick={resetToCurrentLocation}
                  title="Reset to current location"
                >
                  ⟳
                </button>
              }
            />
            <LocationSearchInput
              value={endSearchInput}
              onChange={setEndSearchInput}
              onFocus={handleEndInputFocus}
              onBlur={handleEndInputBlur}
              suggestions={endSuggestions}
              showSuggestions={showEndSuggestions}
              onSuggestionClick={handleEndSuggestionClick}
              placeholder="End location"
              button={endLocation && (
                <button
                  type="button"
                  style={{ padding: '8px 12px', borderRadius: 4, border: '1px solid #d32f2f', background: '#fff', color: '#d32f2f', fontWeight: 600, cursor: 'pointer' }}
                  onClick={handleClearEndLocation}
                  title="Clear end location"
                >
                  ×
                </button>
              )}
            />
          </Box>
        </Box>
        {/* Trip Stops */}
        <Box sx={{ flexGrow: 1, overflowY: 'auto', mb: 2 }}>
          <Typography variant="subtitle1" gutterBottom>
            Trip Stops
          </Typography>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, position: 'relative' }}>
            <LocationSearchInput
              value={stopSearchInput}
              onChange={setStopSearchInput}
              onFocus={handleStopInputFocus}
              onBlur={handleStopInputBlur}
              suggestions={stopSuggestions}
              showSuggestions={showStopSuggestions}
              onSuggestionClick={handleStopSuggestionClick}
              placeholder="Add stop (search)"
            />
            <DraggableStopList
              stops={stops}
              handleRemoveStop={handleRemoveStop}
              handleDragEnd={handleDragEnd}
            />
          </Box>
        </Box>
        {/* POI Categories */}
        {hasRoute && (
          <Box sx={{ mb: 2 }}>
            <Typography variant="subtitle1" gutterBottom>
              Points of Interest
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
              {[
                { key: 'food', label: '🍽️ Food & Drink', color: '#4caf50' },
                { key: 'fuel', label: '⛽ Fuel', color: '#ff9800' },
                { key: 'tourism', label: '🏨 Accommodation', color: '#9c27b0' }
              ].map(({ key, label, color }) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => togglePOICategory(key)}
                  style={{
                    padding: '8px 12px',
                    borderRadius: 4,
                    border: `2px solid ${color}`,
                    background: activePOICategories.has(key) ? color : '#fff',
                    color: activePOICategories.has(key) ? '#fff' : color,
                    fontWeight: 600,
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                    textAlign: 'left'
                  }}
                  title={`${activePOICategories.has(key) ? 'Hide' : 'Show'} ${label}`}
                >
                  {label}
                </button>
              ))}
            </Box>
          </Box>
        )}
      </Box>
    </Drawer>
  );
}; 