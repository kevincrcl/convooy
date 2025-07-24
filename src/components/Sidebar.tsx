import React, { useRef } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Drawer from '@mui/material/Drawer';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import type { Stop, Location } from '../types';

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
            <Box sx={{ display: 'flex', gap: 1 }}>
              <input
                ref={inputRef}
                placeholder="Start location"
                style={{ flex: 1, padding: 8, borderRadius: 4, border: '1px solid #ccc' }}
                value={startSearchInput}
                onChange={e => setStartSearchInput(e.target.value)}
                onFocus={handleStartInputFocus}
                onBlur={handleStartInputBlur}
                autoComplete="off"
              />
              <button
                type="button"
                style={{ padding: '8px 12px', borderRadius: 4, border: '1px solid #1976d2', background: '#fff', color: '#1976d2', fontWeight: 600, cursor: 'pointer' }}
                onClick={resetToCurrentLocation}
                title="Reset to current location"
              >
                ⟳
              </button>
            </Box>
            {showStartSuggestions && startSuggestions.length > 0 && (
              <Box sx={{ position: 'absolute', top: 40, left: 0, right: 0, zIndex: 10, bgcolor: '#fff', border: '1px solid #ccc', borderRadius: 1, boxShadow: 2 }}>
                {startSuggestions.map((feature) => (
                  <Box
                    key={feature.id}
                    sx={{ p: 1, cursor: 'pointer', '&:hover': { bgcolor: '#f5f5f5' } }}
                    onMouseDown={() => handleStartSuggestionClick(feature)}
                  >
                    {feature.place_name}
                  </Box>
                ))}
              </Box>
            )}
            <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
              <input
                ref={endInputRef}
                placeholder="End location"
                style={{ flex: 1, padding: 8, borderRadius: 4, border: '1px solid #ccc' }}
                value={endSearchInput}
                onChange={e => setEndSearchInput(e.target.value)}
                onFocus={handleEndInputFocus}
                onBlur={handleEndInputBlur}
                autoComplete="off"
              />
              {endLocation && (
                <button
                  type="button"
                  style={{ padding: '8px 12px', borderRadius: 4, border: '1px solid #d32f2f', background: '#fff', color: '#d32f2f', fontWeight: 600, cursor: 'pointer' }}
                  onClick={handleClearEndLocation}
                  title="Clear end location"
                >
                  ×
                </button>
              )}
            </Box>
            {showEndSuggestions && endSuggestions.length > 0 && (
              <Box sx={{ position: 'absolute', top: 82, left: 0, right: 0, zIndex: 10, bgcolor: '#fff', border: '1px solid #ccc', borderRadius: 1, boxShadow: 2 }}>
                {endSuggestions.map((feature) => (
                  <Box
                    key={feature.id}
                    sx={{ p: 1, cursor: 'pointer', '&:hover': { bgcolor: '#f5f5f5' } }}
                    onMouseDown={() => handleEndSuggestionClick(feature)}
                  >
                    {feature.place_name}
                  </Box>
                ))}
              </Box>
            )}
          </Box>
        </Box>
        {/* Trip Stops */}
        <Box sx={{ flexGrow: 1, overflowY: 'auto', mb: 2 }}>
          <Typography variant="subtitle1" gutterBottom>
            Trip Stops
          </Typography>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, position: 'relative' }}>
            <Box sx={{ display: 'flex', gap: 1 }}>
              <input
                ref={stopInputRef}
                placeholder="Add stop (search)"
                style={{ flex: 1, padding: 8, borderRadius: 4, border: '1px solid #ccc' }}
                value={stopSearchInput}
                onChange={e => setStopSearchInput(e.target.value)}
                onFocus={handleStopInputFocus}
                onBlur={handleStopInputBlur}
                autoComplete="off"
              />
            </Box>
            {showStopSuggestions && stopSuggestions.length > 0 && (
              <Box sx={{ position: 'absolute', top: 40, left: 0, right: 0, zIndex: 10, bgcolor: '#fff', border: '1px solid #ccc', borderRadius: 1, boxShadow: 2 }}>
                {stopSuggestions.map((feature) => (
                  <Box
                    key={feature.id}
                    sx={{ p: 1, cursor: 'pointer', '&:hover': { bgcolor: '#f5f5f5' } }}
                    onMouseDown={() => handleStopSuggestionClick(feature)}
                  >
                    {feature.place_name}
                  </Box>
                ))}
              </Box>
            )}
            {/* List of stops (draggable) */}
            <DragDropContext onDragEnd={handleDragEnd}>
              <Droppable droppableId="stops-droppable">
                {(provided) => (
                  <Box
                    sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 1 }}
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                  >
                    {stops.length === 0 && (
                      <Typography variant="body2" color="text.secondary">No stops added.</Typography>
                    )}
                    {stops.map((stop, idx) => (
                      <Draggable key={idx.toString()} draggableId={idx.toString()} index={idx}>
                        {(provided, snapshot) => (
                          <Box
                            ref={provided.innerRef}
                            {...provided.draggableProps}
                            {...provided.dragHandleProps}
                            sx={{
                              display: 'flex',
                              alignItems: 'center',
                              bgcolor: snapshot.isDragging ? '#ffe082' : '#f5f5f5',
                              borderRadius: 1,
                              p: 1,
                              boxShadow: snapshot.isDragging ? 3 : 0,
                            }}
                          >
                            <Typography variant="body2" sx={{ flex: 1, mr: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{stop.name}</Typography>
                            <button
                              type="button"
                              style={{ background: 'none', border: 'none', color: '#d32f2f', fontWeight: 700, cursor: 'pointer', fontSize: 18 }}
                              onClick={() => handleRemoveStop(idx)}
                              title="Remove stop"
                            >
                              ×
                            </button>
                          </Box>
                        )}
                      </Draggable>
                    ))}
                    {provided.placeholder}
                  </Box>
                )}
              </Droppable>
            </DragDropContext>
          </Box>
        </Box>
      </Box>
    </Drawer>
  );
}; 