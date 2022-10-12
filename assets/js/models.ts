export interface Track {
  title: string,
  coords: {lat: number, lon: number}[]
}

export interface Row<T> {
  t: string,
  value: T
};
