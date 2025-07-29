import mapboxgl from 'mapbox-gl';

// Get access token from environment variable
const accessToken = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;

if (!accessToken) {
  throw new Error('VITE_MAPBOX_ACCESS_TOKEN environment variable is required');
}

// Set the access token for mapbox-gl
mapboxgl.accessToken = accessToken;

export const mapboxService = {
  // Get the access token
  getToken: () => accessToken,

  // Geocoding (forward geocoding - search to coordinates)
  async searchPlaces(query: string, options: { autocomplete?: boolean; limit?: number } = {}) {
    console.log(`🔍 API: Searching places for: "${query}"`);
    try {
      const params = new URLSearchParams({
        access_token: accessToken,
        autocomplete: (options.autocomplete ?? true).toString(),
        limit: (options.limit ?? 5).toString(),
      });
      
      const response = await fetch(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?${params}`
      );
      const data = await response.json();
      
      console.log(`✅ API: Found ${data.features?.length || 0} places for "${query}"`);
      return data.features || [];
    } catch (error) {
      console.log(`❌ API: Error searching places for "${query}":`, error);
      return [];
    }
  },

  // Reverse geocoding (coordinates to address)
  async reverseGeocode(longitude: number, latitude: number) {
    console.log(`📍 API: Reverse geocoding: ${longitude}, ${latitude}`);
    try {
      const response = await fetch(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${longitude},${latitude}.json?access_token=${accessToken}`
      );
      const data = await response.json();
      
      if (data.features && data.features.length > 0) {
        console.log(`🏠 API: Address found: ${data.features[0].place_name}`);
        return data.features[0];
      } else {
        console.log(`❌ API: No address found for coordinates`);
        return null;
      }
    } catch (error) {
      console.log(`❌ API: Error reverse geocoding:`, error);
      return null;
    }
  },

  // Directions API
  async getDirections(waypoints: Array<[number, number]>, profile: 'driving' | 'walking' | 'cycling' = 'driving') {
    console.log(`🗺️ API: Getting directions for ${waypoints.length} waypoints`);
    try {
      const waypointsString = waypoints.map(([lng, lat]) => `${lng},${lat}`).join(';');
      const response = await fetch(
        `https://api.mapbox.com/directions/v5/mapbox/${profile}/${waypointsString}?geometries=geojson&access_token=${accessToken}`
      );
      const data = await response.json();
      
      if (data.routes && data.routes.length > 0) {
        const route = data.routes[0];
        console.log(`✅ API: Route received: ${route.distance?.toFixed(0)}m, ${route.duration?.toFixed(0)}s`);
        return route;
      } else {
        console.log(`❌ API: No route found`);
        return null;
      }
    } catch (error) {
      console.log(`❌ API: Error getting directions:`, error);
      return null;
    }
  },

  // POI search using Mapbox Search Box API
  async searchPOIs(category: string, bounds: [number, number, number, number], limit: number = 10) {
    console.log(`🏪 API: Searching ${category} POIs using Search Box API category endpoint`);
    try {
      // Map our categories to Search Box API category names
      const categoryMapping = {
        food: 'food_and_drink',
        fuel: 'fuel',
        tourism: 'accommodation'
      };
      
      const searchBoxCategory = categoryMapping[category as keyof typeof categoryMapping] || category;
      
      const params = new URLSearchParams({
        access_token: accessToken,
        limit: limit.toString(),
        bbox: bounds.join(','),
      });
      
      const response = await fetch(
        `https://api.mapbox.com/search/searchbox/v1/category/${searchBoxCategory}?${params}`
      );
      const data = await response.json();
      
      console.log(`🔍 Debug: Search Box API category response for "${searchBoxCategory}":`, data);
      
      if (data.features) {
        const pois = data.features
          .map((poi: any) => ({
            id: poi.properties.mapbox_id,
            type: 'Feature',
            place_type: ['poi'],
            text: poi.properties.name,
            place_name: poi.properties.full_address || poi.properties.name,
            center: [poi.properties.coordinates.longitude, poi.properties.coordinates.latitude],
            geometry: {
              type: 'Point',
              coordinates: [poi.properties.coordinates.longitude, poi.properties.coordinates.latitude]
            },
            properties: {
              category: poi.properties.poi_category?.[0] || category,
              poi_category: poi.properties.poi_category,
              maki: poi.properties.maki
            },
            category,
            displayName: `${poi.properties.name} (${poi.properties.poi_category?.[0] || category})`
          }));
        
        // Filter out duplicates after mapping
        const uniquePois = pois.filter((poi: any, index: number, self: any[]) => 
          index === self.findIndex((p: any) => p.id === poi.id)
        );
        
        console.log(`✅ API: Found ${uniquePois.length} ${category} POIs using Search Box API`);
        return uniquePois;
      }
      
      console.log(`✅ API: Found 0 ${category} POIs using Search Box API`);
      return [];
    } catch (error) {
      console.log(`❌ API: Error searching ${category} POIs:`, error);
      return [];
    }
  },
}; 