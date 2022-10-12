import Leaflet, { ImageOverlay } from 'leaflet';
import { Track } from './models';

function TheMap() {

}

interface Position {
  lat: number, lng: number
}

const Map = {

  mounted() {
    this.handleEvent('init', this.init.bind(this));
  },

  init({ track }: { track: Track }) {
    this.handleEvent('init', this.init.bind(this));
    console.log('hello map', this.el)

    this._map = Leaflet.map('map').setView([track.coords[0].lat, track.coords[0].lon], 14);
    Leaflet.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap'
    }).addTo(this.map());

    this.subscribe(this.addMarker(track));
  },

  map(): Leaflet.Map {
    return this._map as Leaflet.Map;
  },

  addMarker(track: Track) {
    var icon = Leaflet.icon({
      iconUrl: '/images/map-tracker-icon.png',
      iconSize: [16, 16],
  });
    const marker = Leaflet.marker([track.coords[0].lat, track.coords[0].lon], { icon });
    marker.addTo(this.map());
    return marker;
  },

  subscribe(marker: Leaflet.Marker<unknown>) {
    this.handleEvent('position', (position: Position) => {
      console.log('position', position);
      marker.setLatLng(position);
    })
  }
}

export default Map;