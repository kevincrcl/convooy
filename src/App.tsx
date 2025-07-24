import React, { useEffect, useState } from "react";
import Map, { NavigationControl } from 'react-map-gl/mapbox';
import Box from "@mui/material/Box";
import Drawer from "@mui/material/Drawer";
import Typography from "@mui/material/Typography";

const MAPBOX_TOKEN = "pk.eyJ1Ijoia2V2aW5jcmNsIiwiYSI6ImNtZGh1cjVpdjA1eHcybHNmMXZ0anlhYWsifQ.sIVlX-RHn6sTzqPf-w1VPg"; // TODO: Replace with your token

const drawerWidth = 320;

const DEFAULT_LOCATION = {
    longitude: -98.5795, // Center of USA
    latitude: 39.8283,
};

const App: React.FC = () => {
    const [startLocation, setStartLocation] = useState(DEFAULT_LOCATION);
    const [startLocationName, setStartLocationName] = useState('');
    const [mapView, setMapView] = useState({ ...DEFAULT_LOCATION, zoom: 4 });

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
                }
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
                } else {
                    setStartLocationName('Unknown location');
                }
            } catch {
                setStartLocationName('Unknown location');
            }
        }
        fetchAddress();
    }, [startLocation]);

    return (
        <Box sx={{ display: "flex", height: "100vh", width: "100vw" }}>
            {/* Sidebar */}
            <Drawer
                variant="permanent"
                sx={{
                    width: drawerWidth,
                    flexShrink: 0,
                    [`& .MuiDrawer-paper`]: {
                        width: drawerWidth,
                        boxSizing: "border-box",
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
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                            <input
                                placeholder="Start location"
                                style={{ padding: 8, borderRadius: 4, border: '1px solid #ccc' }}
                                value={startLocationName || 'Loading...'}
                                readOnly
                            />
                            <input placeholder="End location" style={{ padding: 8, borderRadius: 4, border: '1px solid #ccc' }} />
                        </Box>
                    </Box>
                    {/* Trip Stops */}
                    <Box sx={{ flexGrow: 1, overflowY: 'auto', mb: 2 }}>
                        <Typography variant="subtitle1" gutterBottom>
                            Trip Stops
                        </Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                            {/* Placeholder stops */}
                            <Box sx={{ p: 1, bgcolor: '#f5f5f5', borderRadius: 1, mb: 1 }}>
                                <Typography variant="body2">Stop 1: Fuel</Typography>
                            </Box>
                            <Box sx={{ p: 1, bgcolor: '#f5f5f5', borderRadius: 1, mb: 1 }}>
                                <Typography variant="body2">Stop 2: Food</Typography>
                            </Box>
                        </Box>
                    </Box>
                    {/* Add Stop Button */}
                    <Box>
                        <button style={{ width: '100%', padding: 10, borderRadius: 4, background: '#1976d2', color: '#fff', border: 'none', fontWeight: 600 }}>
                            + Add Stop
                        </button>
                    </Box>
                </Box>
            </Drawer>
            {/* Map View */}
            <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                <Map
                    longitude={mapView.longitude}
                    latitude={mapView.latitude}
                    zoom={mapView.zoom}
                    onMove={evt => setMapView(evt.viewState)}
                    style={{ width: "100%", height: "100%" }}
                    mapStyle="mapbox://styles/mapbox/streets-v11"
                    mapboxAccessToken={MAPBOX_TOKEN}
                >
                    <NavigationControl position="top-left" />
                </Map>
            </Box>
        </Box>
    );
};

export default App;
