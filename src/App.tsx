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
import { mapboxService } from './services/mapbox';

const DEFAULT_LOCATION = { latitude: 40.7128, longitude: -74.0060 }; // New York City

const drawerWidth = 320;

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

  // Fetch suggestions from Mapbox using SDK
  const fetchMapboxSuggestions = useCallback(async (query: string) => {
    return await mapboxService.searchPlaces(query, { autocomplete: true, limit: 5 });
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
        }
      );
    }
  };

  // Reverse geocode when startLocation changes using SDK
  useEffect(() => {
    async function fetchAddress() {
      const result = await mapboxService.reverseGeocode(startLocation.longitude, startLocation.latitude);
      if (result) {
        setStartLocationName(result.place_name);
        startAutocomplete.setValue(result.place_name);
      } else {
        setStartLocationName('Unknown location');
        startAutocomplete.setValue('');
      }
    }
    fetchAddress();
  }, [startLocation]);

  // Reverse geocode when endLocation changes using SDK
  useEffect(() => {
    if (!endLocation) return;
    async function fetchAddress() {
      const result = await mapboxService.reverseGeocode(endLocation!.longitude, endLocation!.latitude);
      if (result) {
        setEndLocationName(result.place_name);
        setEndSearchInput(result.place_name);
      } else {
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
      const results = await mapboxService.searchPlaces(stopSearchInput, { autocomplete: true, limit: 5 });
      if (!ignore) {
        setStopSuggestions(results);
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

  // Plan route when start, stops, and end locations are set using SDK
  useEffect(() => {
    if (!endLocation || !startLocation) {
      setRouteGeoJSON(null);
      return;
    }
    
    // Build waypoints array with proper typing
    const waypoints: Array<[number, number]> = [
      [startLocation.longitude, startLocation.latitude],
      ...stops.map((stop): [number, number] => [stop.longitude, stop.latitude]),
      [endLocation.longitude, endLocation.latitude],
    ];
    
    async function fetchRoute() {
      const route = await mapboxService.getDirections(waypoints, 'driving');
      if (route) {
        setRouteGeoJSON(route.geometry);
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

  // Fetch POIs along the route using SDK
  useEffect(() => {
    if (!routeGeoJSON || !mapRef.current) return;
    
    async function fetchPOIs() {
      // Get route bounds for POI search
      const coords = routeGeoJSON.coordinates;
      if (!coords || coords.length === 0) return;
      
      // Calculate route bounds
      let minLng = coords[0][0], minLat = coords[0][1], maxLng = coords[0][0], maxLat = coords[0][1];
      coords.forEach(([lng, lat]: [number, number]) => {
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
      });
      
      // Search for POIs in route bounds
      const poiCategories = ['food', 'fuel', 'tourism'];
      const allPois: any[] = [];
      
      for (const category of poiCategories) {
        const categoryPois = await mapboxService.searchPOIs(category, [minLng, minLat, maxLng, maxLat], 10);
        allPois.push(...categoryPois);
      }
      
      // Note: We need to add pois state if we want to display POIs on the map
      console.log(`Found ${allPois.length} POIs along route`);
    }
    
    fetchPOIs();
  }, [routeGeoJSON]);

  // Add POI as stop
  const handlePOIClick = (poi: any) => {
    console.log(`➕ Adding POI as stop: ${poi.displayName}`);
    setStops((prev) => [
      ...prev,
      {
        latitude: poi.center[1],
        longitude: poi.center[0],
        name: poi.displayName,
      },
    ]);
  };

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
          mapboxToken={mapboxService.getToken()}
        />
      </Box>
    </Box>
  );
};

export default App;
