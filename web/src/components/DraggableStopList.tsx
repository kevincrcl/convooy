import React from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import type { Stop } from '../types';

interface DraggableStopListProps {
  stops: Stop[];
  handleRemoveStop: (idx: number) => void;
  handleDragEnd: (result: any) => void;
}

export const DraggableStopList: React.FC<DraggableStopListProps> = ({ stops, handleRemoveStop, handleDragEnd }) => (
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
); 