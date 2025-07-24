import React, { RefObject } from 'react';
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
}) => (
  <Map
    ref={mapRef}
    longitude={mapView.longitude}
    latitude={mapView.latitude}
    zoom={mapView.zoom}
    onMove={evt => setMapView(evt.viewState)}
    style={{ width: '100%', height: '100%' }}
    mapStyle="mapbox://styles/mapbox/streets-v11"
    mapboxAccessToken={mapboxToken}
  >
    <NavigationControl position="top-left" />
    {/* Start marker */}
    <Marker longitude={startLocation.longitude} latitude={startLocation.latitude} anchor="bottom">
      <div style={{ background: '#1976d2', borderRadius: '50%', width: 24, height: 24, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, border: '2px solid #fff', boxShadow: '0 0 4px #0003' }}>
        S
      </div>
    </Marker>
    {/* End marker */}
    {endLocation && (() => {
      const { longitude, latitude } = endLocation;
      return (
        <Marker longitude={longitude} latitude={latitude} anchor="bottom">
          <div style={{ background: '#d32f2f', borderRadius: '50%', width: 24, height: 24, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, border: '2px solid #fff', boxShadow: '0 0 4px #0003' }}>
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
    {/* Route line */}
    {routeGeoJSON && (
      <>
        <Source id="route" type="geojson" data={{ type: 'Feature', geometry: routeGeoJSON, properties: {} }} />
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