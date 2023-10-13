import Leaflet, { ImageOverlay } from 'leaflet';
import { Row, Track } from './models';
import { KV, Widget } from './widget';
import _ from 'underscore';


class SortedSet {
  underlying: KV[] = [];

  constructor(kv: KV[]) {
    kv.forEach(this.append);
  }

  append = ([k, v]: KV) => {
    const last = this.last();
    if (last && k <= last[0]) return;
    this.underlying.push([k, v]);
  }

  closest = (k: number): KV | undefined => {
    if (this.empty()) return undefined;
    const best = undefined;
    let lo = 0;
    let hi = this.underlying.length - 1;
    while (lo < hi) {
      const mid = lo + Math.floor((hi - lo) / 2);
      const [mk, mv] = this.underlying[mid];
      if (mk < k) {
        lo = mid + 1;
      } else if (mk > k) {
        hi = mid - 1;
      } else {
        return [mk, mv]
      }
    }
    return this.underlying[lo];
  }

  empty = () => {
    return this.underlying.length === 0;
  }

  last = () => {
    if (this.empty()) return undefined;
    return this.underlying[this.underlying.length - 1];
  }
}


interface Position {
  lat: number, lng: number
}

class Map extends Widget {
  _map: Leaflet.Map;
  marker: Leaflet.Marker | undefined;
  line: Leaflet.Polyline | undefined;
  sortedSpeeds: SortedSet;
  sortedCoords: SortedSet;

  init() {
    if (this._map) {
      this._map.remove();
    }
    this.hook.handleEvent('map:init', ({ track }: { track: Track }) => {
      this._map = Leaflet.map('map').setView([track.coords[0].lat, track.coords[0].lon], 14);
      Leaflet.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap'
      }).addTo(this.map());
      this.addMarker(track);
    });

    this.sortedSpeeds = new SortedSet([]);
    this.sortedCoords = new SortedSet([]);

    this.addColumn('gps');
    this.addColumn('speed');

    this.emitter.on('hover', (hover) => {
      const kv = this.sortedCoords.closest(hover.k);
      if (kv) {
        const coord = kv[1] as Position;
        this.drawMarker(coord);
      }

    })

    // this.handleEvent('init', this.init.bind(this));
    // this.subscribe(this.addMarker(track));
  }

  map(): Leaflet.Map {
    return this._map as Leaflet.Map;
  }

  addMarker(track: Track) {

  }

  drawMarker({ lat, lng }: { lat: number, lng: number }) {
    if (this.marker) {
      this.marker.remove();
    }

    var icon = Leaflet.icon({
      iconUrl: '/images/map-tracker-icon.png',
      iconSize: [16, 16],
    });
    const marker = Leaflet.marker([lat, lng], { icon });
    marker.addTo(this.map());
    this.marker = marker;
  }

  onAppendRows(column: string, rows: KV[]): void {
    if (column === 'speed') {
      rows.forEach(this.sortedSpeeds.append);
    }
    if (column === 'gps') {
      rows.forEach(this.sortedCoords.append);
      this.drawMarker(_.last(rows)[1] as Position);

    }
  }

  onSetRows(column: string, rows: KV[]): void {
    if (column === 'speed') {
      this.sortedSpeeds = new SortedSet(rows);
    }

    if (column === 'gps') {
      this.sortedCoords = new SortedSet(rows);

      if (this.line) {
        // this.line.remove();
        this.line.removeFrom(this.map());
      }

      this.line = Leaflet.polyline(rows.map((row) => {
        const { lat, lng } = row[1] as { lat: number, lng: number };
        return [lat, lng]
      }));
      this.line.setStyle({
        color: '#b103fc'
      });

      this.line.addTo(this.map());


    }
  }
}

export default Map;