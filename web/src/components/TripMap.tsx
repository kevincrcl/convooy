import React from 'react';
import type { RefObject } from 'react';
import Map, { NavigationControl, Marker, Source, Layer } from 'react-map-gl/mapbox';
import type { Stop, Location } from '../types';

interface TripMapProps {
    mapRef: RefObject<any>;
    mapView: { longitude: number; latitude: number; zoom: number };
    setMapView: (v: { longitude: number; latitude: number; zoom: number }) => void;
    startLocation: Location;
    endLocation: Location | null;
    stops: Stop[];
    routeGeoJSON: any;
    mapboxToken: string;
    pois: any[];
    onPOIClick?: (poi: any) => void;
}

export const TripMap: React.FC<TripMapProps> = ({
    mapRef,
    mapView,
    setMapView,
    startLocation,
    endLocation,
    stops,
    routeGeoJSON,
    mapboxToken,
    pois,
    onPOIClick,
}) => {
    return (
        <Map
            ref={mapRef}
            longitude={mapView.longitude}
            latitude={mapView.latitude}
            zoom={mapView.zoom}
            onMove={(evt) => setMapView(evt.viewState)}
            style={{ width: '100%', height: '100%' }}
            mapStyle="mapbox://styles/mapbox/streets-v11"
            mapboxAccessToken={mapboxToken}
        >
            <NavigationControl position="top-left" />
            {/* Start marker */}
            <Marker longitude={startLocation.longitude} latitude={startLocation.latitude} anchor="bottom">
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
            {/* End marker */}
            {endLocation &&
                (() => {
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
                    <div
                        style={{
                            background: '#ffa000',
                            borderRadius: '50%',
                            width: 20,
                            height: 20,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#fff',
                            fontWeight: 700,
                            border: '2px solid #fff',
                            boxShadow: '0 0 4px #0003',
                            fontSize: 12,
                        }}
                    >
                        {idx + 1}
                    </div>
                </Marker>
            ))}
            {/* POI markers */}
            {pois.map((poi, idx) => {
                const categoryColors = {
                    food: '#4caf50',
                    fuel: '#ff9800',
                    tourism: '#9c27b0',
                };
                const color = categoryColors[poi.category as keyof typeof categoryColors] || '#666';

                console.log(`Rendering POI ${idx}:`, poi);
                console.log(`POI coordinates:`, poi.center);

                return (
                    <Marker
                        key={`poi-${idx}`}
                        longitude={poi.geometry?.coordinates?.[0] || poi.center?.[0]}
                        latitude={poi.geometry?.coordinates?.[1] || poi.center?.[1]}
                        anchor="bottom"
                        onClick={() => onPOIClick?.(poi)}
                    >
                        <div
                            style={{
                                background: color,
                                borderRadius: '50%',
                                width: 16,
                                height: 16,
                                border: '2px solid #fff',
                                boxShadow: '0 0 4px #0003',
                                cursor: 'pointer',
                                position: 'relative',
                            }}
                            title={poi.displayName}
                            onMouseEnter={(e) => {
                                // Create tooltip
                                const tooltip = document.createElement('div');
                                tooltip.id = 'poi-tooltip';
                                tooltip.style.cssText = `
                position: absolute;
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 8px 12px;
                border-radius: 4px;
                font-size: 12px;
                white-space: nowrap;
                z-index: 1000;
                pointer-events: none;
                transform: translate(-50%, -100%);
                margin-top: -8px;
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
              `;
                                tooltip.innerHTML = `
                <div style="font-weight: bold; margin-bottom: 4px;">${poi.text}</div>
                <div style="font-size: 11px; opacity: 0.9;">${poi.place_name}</div>
                <div style="font-size: 11px; opacity: 0.7; margin-top: 2px;">${poi.category}</div>
              `;
                                document.body.appendChild(tooltip);

                                // Position tooltip
                                const updateTooltipPosition = () => {
                                    const element = e.currentTarget;
                                    if (!element) return;

                                    const rect = element.getBoundingClientRect();
                                    if (rect) {
                                        tooltip.style.left = rect.left + rect.width / 2 + 'px';
                                        tooltip.style.top = rect.top + 'px';
                                    }
                                };
                                updateTooltipPosition();

                                // Update position on scroll/resize
                                const handleScroll = () => updateTooltipPosition();
                                const handleResize = () => updateTooltipPosition();
                                window.addEventListener('scroll', handleScroll);
                                window.addEventListener('resize', handleResize);

                                // Store references for cleanup
                                (e.currentTarget as any)._tooltipHandlers = { handleScroll, handleResize };
                            }}
                            onMouseLeave={(e) => {
                                // Remove tooltip
                                const tooltip = document.getElementById('poi-tooltip');
                                if (tooltip) {
                                    tooltip.remove();
                                }

                                // Remove event listeners
                                const element = e.currentTarget as any;
                                if (element && element._tooltipHandlers) {
                                    const { handleScroll, handleResize } = element._tooltipHandlers;
                                    window.removeEventListener('scroll', handleScroll);
                                    window.removeEventListener('resize', handleResize);
                                    delete element._tooltipHandlers;
                                }
                            }}
                        />
                    </Marker>
                );
            })}
            {/* Route line */}
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
    );
};
