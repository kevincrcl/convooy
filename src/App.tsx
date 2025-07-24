import React from "react";
import Map, { NavigationControl } from 'react-map-gl/mapbox';
import Box from "@mui/material/Box";
import Drawer from "@mui/material/Drawer";
import Typography from "@mui/material/Typography";

const MAPBOX_TOKEN = "pk.eyJ1Ijoia2V2aW5jcmNsIiwiYSI6ImNtZGh1cjVpdjA1eHcybHNmMXZ0anlhYWsifQ.sIVlX-RHn6sTzqPf-w1VPg"; // TODO: Replace with your token

const drawerWidth = 320;

const App: React.FC = () => {
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
                <Box sx={{ p: 2 }}>
                    <Typography variant="h5" gutterBottom>
                        Trip Planner
                    </Typography>
                    <Typography variant="body1">
                        Stops and controls will go here.
                    </Typography>
                </Box>
            </Drawer>
            {/* Map View */}
            <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                <Map
                    initialViewState={{
                        longitude: -98.5795, // Center of USA
                        latitude: 39.8283,
                        zoom: 4,
                    }}
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
