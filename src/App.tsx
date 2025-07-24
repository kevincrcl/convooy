import React, { useEffect, useState, useRef } from 'react';
import Map, { NavigationControl, Marker, Source, Layer } from 'react-map-gl/mapbox';
import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import Typography from '@mui/material/Typography';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import type { DropResult } from '@hello-pangea/dnd';

const MAPBOX_TOKEN =
  'pk.eyJ1Ijoia2V2aW5jcmNsIiwiYSI6ImNtZGh1cjVpdjA1eHcybHNmMXZ0anlhYWsifQ.sIVlX-RHn6sTzqPf-w1VPg'; // TODO: Replace with your token

const drawerWidth = 320;

const DEFAULT_LOCATION = {
  longitude: -98.5795, // Center of USA
  latitude: 39.8283,
};

const App: React.FC = () => {
  const [startLocation, setStartLocation] = useState(DEFAULT_LOCATION);
  const [startLocationName, setStartLocationName] = useState('');
  const [mapView, setMapView] = useState({ ...DEFAULT_LOCATION, zoom: 4 });
  const [searchInput, setSearchInput] = useState('');
  const [suggestions, setSuggestions] = useState<any[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const [endLocation, setEndLocation] = useState<{ latitude: number; longitude: number } | null>(
    null,
  );
  const [endLocationName, setEndLocationName] = useState('');
  const [endSearchInput, setEndSearchInput] = useState('');
  const [endSuggestions, setEndSuggestions] = useState<any[]>([]);
  const [showEndSuggestions, setShowEndSuggestions] = useState(false);
  const [routeGeoJSON, setRouteGeoJSON] = useState<any>(null);
  const endInputRef = useRef<HTMLInputElement>(null);

  // Stops state
  const [stops, setStops] = useState<{ latitude: number; longitude: number; name: string }[]>([]);
  const [stopSearchInput, setStopSearchInput] = useState("");
  const [stopSuggestions, setStopSuggestions] = useState<any[]>([]);
  const [showStopSuggestions, setShowStopSuggestions] = useState(false);
  const stopInputRef = useRef<HTMLInputElement>(null);

  const mapRef = useRef<any>(null);

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          setStartLocation({ latitude, longitude });
          setMapView({ latitude, longitude, zoom: 12 });
        },
        () => {
          // If user denies or error, keep default
        },
      );
    }
  }, []);

  // Reverse geocode when startLocation changes
  useEffect(() => {
    async function fetchAddress() {
      try {
        const res = await fetch(
          `https://api.mapbox.com/geocoding/v5/mapbox.places/${startLocation.longitude},${startLocation.latitude}.json?access_token=${MAPBOX_TOKEN}`,
        );
        const data = await res.json();
        if (data.features && data.features.length > 0) {
          setStartLocationName(data.features[0].place_name);
          setSearchInput(data.features[0].place_name);
        } else {
          setStartLocationName('Unknown location');
          setSearchInput('');
        }
      } catch {
        setStartLocationName('Unknown location');
        setSearchInput('');
      }
    }
    fetchAddress();
  }, [startLocation]);

  // Fetch suggestions as user types
  useEffect(() => {
    if (searchInput.length < 3) {
      setSuggestions([]);
      return;
    }
    let ignore = false;
    async function fetchSuggestions() {
      const res = await fetch(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(
          searchInput,
        )}.json?access_token=${MAPBOX_TOKEN}&autocomplete=true&limit=5`,
      );
      const data = await res.json();
      if (!ignore) {
        setSuggestions(data.features || []);
      }
    }
    fetchSuggestions();
    return () => {
      ignore = true;
    };
  }, [searchInput]);

  // Handle suggestion selection
  const handleSuggestionClick = (feature: any) => {
    setStartLocation({
      latitude: feature.center[1],
      longitude: feature.center[0],
    });
    setMapView({
      latitude: feature.center[1],
      longitude: feature.center[0],
      zoom: 12,
    });
    setStartLocationName(feature.place_name);
    setSearchInput(feature.place_name);
    setSuggestions([]);
    setShowSuggestions(false);
  };

  // Handle input focus/blur
  const handleInputFocus = () => setShowSuggestions(true);
  const handleInputBlur = () => setTimeout(() => setShowSuggestions(false), 100);

  // Add this function to get current location and update state
  const resetToCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          setStartLocation({ latitude, longitude });
          setMapView({ latitude, longitude, zoom: 12 });
        },
        () => {
          // If user denies or error, do nothing
        },
      );
    }
  };

  // Reverse geocode when endLocation changes
  useEffect(() => {
    if (!endLocation) return;
    async function fetchAddress() {
      try {
        const res = await fetch(
          `https://api.mapbox.com/geocoding/v5/mapbox.places/${endLocation.longitude},${endLocation.latitude}.json?access_token=${MAPBOX_TOKEN}`,
        );
        const data = await res.json();
        if (data.features && data.features.length > 0) {
          setEndLocationName(data.features[0].place_name);
          setEndSearchInput(data.features[0].place_name);
        } else {
          setEndLocationName('Unknown location');
          setEndSearchInput('');
        }
      } catch {
        setEndLocationName('Unknown location');
        setEndSearchInput('');
      }
    }
    fetchAddress();
  }, [endLocation]);

  // Fetch end suggestions as user types
  useEffect(() => {
    if (endSearchInput.length < 3) {
      setEndSuggestions([]);
      return;
    }
    let ignore = false;
    async function fetchSuggestions() {
      const res = await fetch(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(
          endSearchInput,
        )}.json?access_token=${MAPBOX_TOKEN}&autocomplete=true&limit=5`,
      );
      const data = await res.json();
      if (!ignore) {
        setEndSuggestions(data.features || []);
      }
    }
    fetchSuggestions();
    return () => {
      ignore = true;
    };
  }, [endSearchInput]);

  // Handle end suggestion selection
  const handleEndSuggestionClick = (feature: any) => {
    const lat = feature.center[1];
    const lng = feature.center[0];
    setEndLocation({ latitude: lat, longitude: lng });
    setEndLocationName(feature.place_name);
    setEndSearchInput(feature.place_name);
    setEndSuggestions([]);
    setShowEndSuggestions(false);
    setMapView({ latitude: lat, longitude: lng, zoom: 12 });
  };

  // Handle end input focus/blur
  const handleEndInputFocus = () => setShowEndSuggestions(true);
  const handleEndInputBlur = () => setTimeout(() => setShowEndSuggestions(false), 100);

  // Clear end location
  const handleClearEndLocation = () => {
    setEndLocation(null);
    setEndSearchInput("");
    setEndLocationName("");
    setRouteGeoJSON(null);
  };

  // Fetch stop suggestions as user types
  useEffect(() => {
    if (stopSearchInput.length < 3) {
      setStopSuggestions([]);
      return;
    }
    let ignore = false;
    async function fetchSuggestions() {
      const res = await fetch(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(
          stopSearchInput
        )}.json?access_token=${MAPBOX_TOKEN}&autocomplete=true&limit=5`
      );
      const data = await res.json();
      if (!ignore) {
        setStopSuggestions(data.features || []);
      }
    }
    fetchSuggestions();
    return () => {
      ignore = true;
    };
  }, [stopSearchInput]);

  // Handle stop suggestion selection
  const handleStopSuggestionClick = (feature: any) => {
    setStops((prev) => [
      ...prev,
      {
        latitude: feature.center[1],
        longitude: feature.center[0],
        name: feature.place_name,
      },
    ]);
    setStopSearchInput("");
    setStopSuggestions([]);
    setShowStopSuggestions(false);
  };

  // Remove stop
  const handleRemoveStop = (idx: number) => {
    setStops((prev) => prev.filter((_, i) => i !== idx));
  };

  // Handle stop input focus/blur
  const handleStopInputFocus = () => setShowStopSuggestions(true);
  const handleStopInputBlur = () => setTimeout(() => setShowStopSuggestions(false), 100);

  // Plan route when start, stops, and end locations are set
  useEffect(() => {
    if (!endLocation || !startLocation) {
      setRouteGeoJSON(null);
      return;
    }
    // Build the waypoints string: start;stop1;stop2;...;end
    const waypoints = [
      `${startLocation.longitude},${startLocation.latitude}`,
      ...stops.map((stop) => `${stop.longitude},${stop.latitude}`),
      `${endLocation.longitude},${endLocation.latitude}`,
    ].join(';');
    async function fetchRoute() {
      const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${waypoints}?geometries=geojson&access_token=${MAPBOX_TOKEN}`;
      const res = await fetch(url);
      const data = await res.json();
      if (data.routes && data.routes.length > 0) {
        setRouteGeoJSON(data.routes[0].geometry);
      } else {
        setRouteGeoJSON(null);
      }
    }
    fetchRoute();
  }, [startLocation, endLocation, stops]);

  // After routeGeoJSON updates, fit map to route bounds
  useEffect(() => {
    if (!routeGeoJSON || !mapRef.current) return;
    // Calculate bounds from route coordinates
    const coords = routeGeoJSON.coordinates;
    if (!coords || coords.length === 0) return;
    let minLng = coords[0][0], minLat = coords[0][1], maxLng = coords[0][0], maxLat = coords[0][1];
    coords.forEach(([lng, lat]: [number, number]) => {
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
    });
    mapRef.current.fitBounds([
      [minLng, minLat],
      [maxLng, maxLat],
    ], { padding: 60, duration: 1000 });
  }, [routeGeoJSON]);

  // Handle drag end for stops
  const handleDragEnd = (result: DropResult) => {
    if (!result.destination) return;
    const reordered = Array.from(stops);
    const [removed] = reordered.splice(result.source.index, 1);
    reordered.splice(result.destination.index, 0, removed);
    setStops(reordered);
  };

  return (
    <Box sx={{ display: 'flex', height: '100vh', width: '100vw' }}>
      {/* Sidebar */}
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
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  onFocus={handleInputFocus}
                  onBlur={handleInputBlur}
                  autoComplete="off"
                />
                <button
                  type="button"
                  style={{
                    padding: '8px 12px',
                    borderRadius: 4,
                    border: '1px solid #1976d2',
                    background: '#fff',
                    color: '#1976d2',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                  onClick={resetToCurrentLocation}
                  title="Reset to current location"
                >
                  ⟳
                </button>
              </Box>
              {showSuggestions && suggestions.length > 0 && (
                <Box
                  sx={{
                    position: 'absolute',
                    top: 40,
                    left: 0,
                    right: 0,
                    zIndex: 10,
                    bgcolor: '#fff',
                    border: '1px solid #ccc',
                    borderRadius: 1,
                    boxShadow: 2,
                  }}
                >
                  {suggestions.map((feature) => (
                    <Box
                      key={feature.id}
                      sx={{ p: 1, cursor: 'pointer', '&:hover': { bgcolor: '#f5f5f5' } }}
                      onMouseDown={() => handleSuggestionClick(feature)}
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
                  onChange={(e) => setEndSearchInput(e.target.value)}
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
                <Box
                  sx={{
                    position: 'absolute',
                    top: 82,
                    left: 0,
                    right: 0,
                    zIndex: 10,
                    bgcolor: '#fff',
                    border: '1px solid #ccc',
                    borderRadius: 1,
                    boxShadow: 2,
                  }}
                >
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
          {/* Add Stop Button */}
          <Box>
            <button
              style={{
                width: '100%',
                padding: 10,
                borderRadius: 4,
                background: '#1976d2',
                color: '#fff',
                border: 'none',
                fontWeight: 600,
              }}
            >
              + Add Stop
            </button>
          </Box>
        </Box>
      </Drawer>
      {/* Map View */}
      <Box sx={{ flexGrow: 1, minWidth: 0 }}>
        <Map
          ref={mapRef}
          longitude={mapView.longitude}
          latitude={mapView.latitude}
          zoom={mapView.zoom}
          onMove={(evt) => setMapView(evt.viewState)}
          style={{ width: '100%', height: '100%' }}
          mapStyle="mapbox://styles/mapbox/streets-v11"
          mapboxAccessToken={MAPBOX_TOKEN}
        >
          <NavigationControl position="top-left" />
          <Marker
            longitude={startLocation.longitude}
            latitude={startLocation.latitude}
            anchor="bottom"
          >
            <div
              style={{
                background: '#1976d2',
                borderRadius: '50%',
                width: 24,
                height: 24,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fff',
                fontWeight: 700,
                border: '2px solid #fff',
                boxShadow: '0 0 4px #0003',
              }}
            >
              S
            </div>
          </Marker>
          {/* Only render end marker if endLocation is not null */}
          {(() => {
            if (endLocation === null) return null;
            const { longitude, latitude } = endLocation;
            return (
              <Marker longitude={longitude} latitude={latitude} anchor="bottom">
                <div
                  style={{
                    background: '#d32f2f',
                    borderRadius: '50%',
                    width: 24,
                    height: 24,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#fff',
                    fontWeight: 700,
                    border: '2px solid #fff',
                    boxShadow: '0 0 4px #0003',
                  }}
                >
                  E
                </div>
              </Marker>
            );
          })()}
          {/* Stop markers */}
          {stops.map((stop, idx) => (
            <Marker
              key={`stop-${idx}`}
              longitude={stop.longitude}
              latitude={stop.latitude}
              anchor="bottom"
            >
              <div style={{ background: '#ffa000', borderRadius: '50%', width: 20, height: 20, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, border: '2px solid #fff', boxShadow: '0 0 4px #0003', fontSize: 12 }}>
                {idx + 1}
              </div>
            </Marker>
          ))}
          {routeGeoJSON && (
            <>
              <Source
                id="route"
                type="geojson"
                data={{ type: 'Feature', geometry: routeGeoJSON, properties: {} }}
              />
              <Layer
                id="route-line"
                type="line"
                source="route"
                layout={{ 'line-cap': 'round', 'line-join': 'round' }}
                paint={{ 'line-color': '#1976d2', 'line-width': 4 }}
              />
            </>
          )}
        </Map>
      </Box>
    </Box>
  );
};

export default App;
