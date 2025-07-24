export type Location = {
  latitude: number;
  longitude: number;
};

export type Stop = Location & {
  name: string;
}; 