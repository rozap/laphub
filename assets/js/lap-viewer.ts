import uPlot, { AlignedData } from 'uplot';
import Leaflet, { ImageOverlay } from 'leaflet';
import { Track } from './models';
import _ from 'underscore';

const pressureOpts = (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'Pressures',
    width: element.clientWidth,
    height: element.clientHeight,
    series: [
      {},
      {
        label: 'Oil Pressure',
        scale: 'psi',
        value: (u, v) => v,
        stroke: 'red',
        width: 1
      },
      {
        label: 'Coolant Pressure',
        scale: 'psi',
        value: (u, v) => v,
        stroke: 'blue',
        width: 1
      }
    ],
    plugins: [
      {
        hooks: {
          setSelect: (data) => {
          }
        }
      }
    ],
    axes: [
      {},
      {
        scale: 'psi',
        values: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        grid: { show: true }
      }
    ]
  };
};


const temperatureOpts = (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'Temperatures',
    width: element.clientWidth,
    height: element.clientHeight,
    //	ms:     1,
    //	cursor: {
    //		x: false,
    //		y: false,
    //	},
    series: [
      {},
      {
        label: 'Oil Temperature',
        scale: 'degrees',
        value: (u, v) => v,
        stroke: 'red',
        width: 1
      },
      {
        label: 'Coolant Temperature',
        scale: 'degrees',
        value: (u, v) => v,
        stroke: 'blue',
        width: 1
      }
    ],
    plugins: [
      {
        hooks: {
          setSelect: () => {

          }
        }
      }
    ],
    axes: [
      {},
      {
        scale: 'degrees',
        values: (u, vals, space) => {
          return vals.map((v) => (v / 10).toFixed(1) + '°');
        },
        grid: { show: true }
      }
    ]
  };
};


const voltOps = (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'Volts',
    width: element.clientWidth,
    height: element.clientHeight,
    series: [
      {},
      {
        label: 'Volts',
        scale: 'volts',
        value: (u, v) => v,
        stroke: 'green',
        width: 1
      }
    ],
    plugins: [],
    axes: [
      {},
      {
        scale: 'volts',
        values: (u, vals, space) => {
          return vals.map((v) => (+(v / 1000).toFixed(2)) + 'v');
        },
        grid: { show: true }
      }
    ]
  };
};


const rpmOps = (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'RPM',
    width: element.clientWidth,
    height: element.clientHeight,
    series: [
      {},
      {
        label: 'RPM',
        scale: 'rpm',
        value: (u, v) => v,
        stroke: 'pink',
        width: 1
      }
    ],
    plugins: [],
    axes: [
      {},
      {
        scale: 'rpm',
        values: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        grid: { show: true }
      }
    ]
  };
};


const rsiOps = (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'RSI',
    width: element.clientWidth,
    height: element.clientHeight,
    series: [
      {},
      {
        label: 'RSI',
        scale: 'rsi',
        value: (u, v) => v,
        stroke: 'cyan',
        width: 1
      }
    ],
    plugins: [],
    axes: [
      {},
      {
        scale: 'rsi',
        values: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        grid: { show: true }
      }
    ]
  };
};


interface Row<T> {
  t: string,
  series: Record<string, T>
}


class Window<T> {
  label: string;
  underlying: T[] = [];

  constructor(label: string) {
    this.label = label;
  }

  append(value: T) {
    this.underlying.push(value)
  }

  all() {
    return this.underlying;
  }

}

class Dimensions<T> {
  time: number[] = [];
  windows: Record<string, Window<T>> = {};

  constructor(labels: string[]) {
    labels.forEach(label => {
      this.windows[label] = new Window(label);
    });
  }

  append(t: number, value: Record<string, T>) {
    this.time.push(t);
    Object.keys(this.windows).forEach(k => {
      this.windows[k].append(value[k]);
    });
  }

  dump(): AlignedData {
    return [
      this.time,
      ...Object.keys(this.windows).map(k => this.windows[k].all())
    ] as any as AlignedData;
  }

  sort() {

  }
}

class Chart<T> {
  dimensions: Dimensions<T>;
  uplot: uPlot;
  labels: string[];

  constructor(opts: () => uPlot.Options, labels: string[], target: HTMLDivElement) {
    this.labels = labels;
    this.dimensions = new Dimensions(labels);
    this.uplot = new uPlot(opts(), this.dimensions.dump(), target);

    this.target = target;
    this.opts = opts;
    // to reset the selection
    // u.setScale('x', {min: 500, max: 1000})
  }

  append(rows: Row<T>[]) {
    rows.forEach(row => {
      const t = parseInt(row.t) / (1000 * 1000);
      this.dimensions.append(t, row.series);
    });

    this.uplot.setData(this.dimensions.dump())
  }

  update(rows: Row<T>[]) {
    this.dimensions = new Dimensions(this.labels);
    // this.uplot = new uPlot(this.opts(), this.dimensions.dump(), this.target);

    this.append(rows);
  }
}


export default {
  mounted() {
    this.handleEvent('init', this.init.bind(this));
  },

  init({ track }: { track: Track }) {
    this.initMap(track);

    [
      { name: 'pressures', series: ['oil_pres', 'coolant_pres'], opts: pressureOpts },
      { name: 'temperatures', series: ['oil_temp', 'coolant_temp'], opts: temperatureOpts},
      { name: 'volts', series: ['voltage'], opts: voltOps},
      { name: 'rpm', series: ['rpm'], opts: rpmOps},
      { name: 'rsi', series: ['rsi'], opts: rsiOps},
    ].forEach(({name, series, opts}) => {
      const el = this.el.querySelector('#' + name) as HTMLDivElement;
      const chart = new Chart(() => opts(el), series, el);
      this.subscribe(chart);
    });
  },

  initMap(track: Track) {
    // var map = Leaflet.map('map').setView([track.coords[0].lat, track.coords[0].lon], 14);
    // Leaflet.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    //   maxZoom: 19,
    //   attribution: '© OpenStreetMap'
    // }).addTo(map);
  },

  subscribe<T>(c: Chart<T>) {
    this.handleEvent('append', ({ rows }: { rows: Row<T>[] }) => {
      c.append(rows);
    });
    this.handleEvent('set_rows', ({ rows }: { rows: Row<T>[] }) => {
      console.log("rows?", rows);
      c.update(rows);
    });

  },

  // initChart(labels: string[]) {
  //   const el: HTMLDivElement = this.el;

  //   // if (uplot.select.width === 0) {
  //   //   console.log(data);
  //   //   uplot.setData(data);
  //   // }
  //   // uplot.hooks.setScale = (u) => {
  //   //   console.log('scale', u);
  //   // }
  // })
};
