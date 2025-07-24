import React, { useEffect, useState, useRef, useCallback } from 'react';
import Map, { NavigationControl, Marker, Source, Layer } from 'react-map-gl/mapbox';
import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import Typography from '@mui/material/Typography';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import type { DropResult } from '@hello-pangea/dnd';
import { Sidebar } from './components/Sidebar';
import { TripMap } from './components/TripMap';
import type { Stop, Location } from './types';
import { useAutocomplete } from './hooks/useAutocomplete';

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
          `https://api.mapbox.com/geocoding/v5/mapbox.places/${startLocation.longitude},${startLocation.latitude}.json?access_token=${MAPBOX_TOKEN}`
        );
        const data = await res.json();
        if (data.features && data.features.length > 0) {
          setStartLocationName(data.features[0].place_name);
          startAutocomplete.setValue(data.features[0].place_name); // <-- keep input in sync
        } else {
          setStartLocationName('Unknown location');
          startAutocomplete.setValue('');
        }
      } catch {
        setStartLocationName('Unknown location');
        startAutocomplete.setValue('');
      }
    }
    fetchAddress();
  }, [startLocation]);

  // Fetch suggestions from Mapbox
  const fetchMapboxSuggestions = useCallback(async (query: string) => {
    const res = await fetch(
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?access_token=${MAPBOX_TOKEN}&autocomplete=true&limit=5`
    );
    const data = await res.json();
    return data.features || [];
  }, []);

  // Start location autocomplete
  const startAutocomplete = useAutocomplete({ fetchSuggestions: fetchMapboxSuggestions });
  // End location autocomplete
  const endAutocomplete = useAutocomplete({ fetchSuggestions: fetchMapboxSuggestions });
  // Stop location autocomplete
  const stopAutocomplete = useAutocomplete({ fetchSuggestions: fetchMapboxSuggestions });

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
    endAutocomplete.setValue('');
    setEndLocationName('');
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
    stopAutocomplete.setValue('');
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
      <Sidebar
        drawerWidth={drawerWidth}
        // Start location autocomplete
        startSearchInput={startAutocomplete.value}
        setStartSearchInput={startAutocomplete.setValue}
        startSuggestions={startAutocomplete.suggestions}
        showStartSuggestions={startAutocomplete.showSuggestions}
        handleStartInputFocus={startAutocomplete.onFocus}
        handleStartInputBlur={startAutocomplete.onBlur}
        handleStartSuggestionClick={feature => {
          startAutocomplete.setValue(feature.place_name);
          startAutocomplete.onSuggestionClick(feature);
          handleSuggestionClick(feature);
        }}
        resetToCurrentLocation={resetToCurrentLocation}
        // End location autocomplete
        endSearchInput={endAutocomplete.value}
        setEndSearchInput={endAutocomplete.setValue}
        endSuggestions={endAutocomplete.suggestions}
        showEndSuggestions={endAutocomplete.showSuggestions}
        handleEndInputFocus={endAutocomplete.onFocus}
        handleEndInputBlur={endAutocomplete.onBlur}
        handleEndSuggestionClick={feature => {
          endAutocomplete.setValue(feature.place_name);
          endAutocomplete.onSuggestionClick(feature);
          handleEndSuggestionClick(feature);
        }}
        endLocation={endLocation}
        handleClearEndLocation={handleClearEndLocation}
        // Stop location autocomplete
        stopSearchInput={stopAutocomplete.value}
        setStopSearchInput={stopAutocomplete.setValue}
        stopSuggestions={stopAutocomplete.suggestions}
        showStopSuggestions={stopAutocomplete.showSuggestions}
        handleStopInputFocus={stopAutocomplete.onFocus}
        handleStopInputBlur={stopAutocomplete.onBlur}
        handleStopSuggestionClick={feature => {
          stopAutocomplete.setValue(feature.place_name);
          stopAutocomplete.onSuggestionClick(feature);
          handleStopSuggestionClick(feature);
        }}
        stops={stops}
        handleRemoveStop={handleRemoveStop}
        handleDragEnd={handleDragEnd}
      />
      <Box sx={{ flexGrow: 1, minWidth: 0 }}>
        <TripMap
          mapRef={mapRef}
          mapView={mapView}
          setMapView={setMapView}
          startLocation={startLocation}
          endLocation={endLocation}
          stops={stops}
          routeGeoJSON={routeGeoJSON}
          mapboxToken={MAPBOX_TOKEN}
        />
      </Box>
    </Box>
  );
};

export default App;
