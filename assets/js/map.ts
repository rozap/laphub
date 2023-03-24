import Leaflet, { ImageOverlay } from 'leaflet';
import { Row, Track } from './models';

function TheMap() {

}

interface Position {
  lat: number, lng: number
}

interface RowAppend {
  rows: Row<number>;
};

const Map = {

  mounted() {
    this.handleEvent('init', this.init.bind(this));
  },

  init({ track }: { track: Track }) {
    this.handleEvent('init', this.init.bind(this));
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
    // This was for testing with the backfill
    // this.handleEvent('position', (position: Position) => {
    //   marker.setLatLng(position);
    // });

    let currentPosn: {
      lat?: number, lng?: number
    } = {};
    const updatePosn = () => {
      if (currentPosn.lat && currentPosn.lng) {
        marker.setLatLng({
          lat: currentPosn.lat,
          lng: currentPosn.lng
          // ok fine TS
        });
      }
    }
    this.handleEvent('append_rows:lat', ({ rows }: RowAppend) => {
      currentPosn = {...currentPosn, lat: rows[0].value};
      updatePosn();
    });
    this.handleEvent('append_rows:lon', ({ rows }: RowAppend) => {
      currentPosn = {...currentPosn, lng: rows[0].value};
      updatePosn();
    });
  }
}

export default Map;