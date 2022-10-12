import uPlot, { AlignedData } from 'uplot';
import { Track } from './models';
import _ from 'underscore';

const pressureOpts = (plugins: uPlot.Plugin[]) => (element: HTMLDivElement): uPlot.Options => {
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


const temperatureOpts = (plugins: uPlot.Plugin[]) => (element: HTMLDivElement): uPlot.Options => {
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
    plugins,
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


const voltOps = (plugins: uPlot.Plugin[]) => (element: HTMLDivElement): uPlot.Options => {
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
    plugins,
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


const rpmOps = (plugins: uPlot.Plugin[]) => (element: HTMLDivElement): uPlot.Options => {
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
    plugins,
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


const rsiOps = (plugins: uPlot.Plugin[]) => (element: HTMLDivElement): uPlot.Options => {
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
    plugins,
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

const speedOps = (plugins: uPlot.Plugin[]) => (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'Speed',
    width: element.clientWidth,
    height: element.clientHeight,
    series: [
      {},
      {
        label: 'Speed (MPH)',
        scale: 'mph',
        value: (u, v) => v,
        stroke: 'cyan',
        width: 1
      }
    ],
    plugins,
    axes: [
      {},
      {
        scale: 'mph',
        values: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        grid: { show: true }
      }
    ]
  };
};





class Dimensions<T> {
  windows: Record<string, [number, T][]> = {};

  constructor(labels: string[]) {
    labels.forEach(label => {
      this.windows[label] = [];
    });
  }

  append(t: number, column: string, value: T) {
    this.windows[column].push([t, value]);
  }

  clear(column: string) {
    this.windows[column] = [];
  }

  dump(): AlignedData {
    // return [
    //   this.time,
    //   ...
    // ] as any as AlignedData;


    // this is really slow and can be optimized
    const lookup = Object.keys(this.windows).reduce((acc, column) => {
      const innerLookup = {};
      this.windows[column].forEach(([ts, value]) => {
        innerLookup[ts] = value;
      });
      return { ...acc, [column]: innerLookup }
    }, {});

    const time = Object.keys(this.windows).flatMap((column) => {
      return this.windows[column].map(([ts, _value]) => ts)
    });
    time.sort();

    return [
      time,
      ...Object.keys(this.windows).map((column) => {
        return time.map(ts => lookup[column][ts])
      })
    ] as any as AlignedData
  }
}

interface RangeLike {
  type: 'unix_millis_range',
  from: number,
  to: number
}

class Chart<T> {
  dimensions: Dimensions<T>;
  uplot: uPlot;
  labels: string[];
  name: string;

  // this should not be necessary, but it seems like there's a bug in uplot
  // where setData just causes the whole chart to disappear, with no exception
  // thrown. argh...why.
  reinit: () => void;

  constructor(name: string, opts: () => uPlot.Options, labels: string[], target: HTMLDivElement) {
    this.name = name;
    this.labels = labels;
    this.dimensions = new Dimensions(labels);

    this.reinit = () => {
      this.uplot && this.uplot.destroy();
      this.uplot = new uPlot(opts(), this.dimensions.dump(), target);
      this.uplot.setScale
    }

    this.reinit();
    // to reset the selection
    // u.setScale('x', {min: 500, max: 1000})
  }

  private putRows(column: string, rows: Row<T>[]) {
    rows.forEach(row => {
      const t = parseInt(row.t) / 1000;
      this.dimensions.append(t, column, row.value);
    });
  }

  append(column: string, rows: Row<T>[]) {
    this.putRows(column, rows);
    this.uplot.setData(this.dimensions.dump())
  }

  setRows = (column: string, rows: Row<T>[]) => {
    this.dimensions.clear(column);
    this.putRows(column, rows);
    this.reinit();
    console.log(`${this.name} got rows for ${column}`, this.dimensions.dump());
  }
}


type SetRange = (range: RangeLike) => void;
interface ChartDefinition {
  series: string[],
  opts: (el: HTMLDivElement) => uPlot.Options
}
const buildChart = (name: string, setRange: SetRange): ChartDefinition => {
  const plugins: uPlot.Plugin[] = [
    {
      hooks: {
        setSelect: (u: uPlot) => {
          const from = Math.round(u.posToVal(u.select.left, 'x'));
          const to = Math.round(u.posToVal(u.select.left + u.select.width, 'x'));
          setRange({ type: 'unix_millis_range', from, to });
        }
      }
    }
  ];

  const ChartDefinitions = [
    { name: 'pressures', series: ['oil_pres', 'coolant_pres'], opts: pressureOpts(plugins) },
    { name: 'temperatures', series: ['oil_temp', 'coolant_temp'], opts: temperatureOpts(plugins)},
    { name: 'volts', series: ['voltage'], opts: voltOps(plugins) },
    { name: 'rpm', series: ['rpm'], opts: rpmOps(plugins)},
    { name: 'rsi', series: ['rsi'], opts: rsiOps(plugins)},
    { name: 'speed', series: ['Speed (MPH)'], opts: speedOps(plugins)},
  ]

  return ChartDefinitions.find(d => d.name === name)!;
}

const Wut = {
  mounted() {
    const setRange = (range: RangeLike) => {
      this.pushEvent('set_range', range);
    }
    const el: HTMLDivElement = this.el;

    const name = el.id;
    console.log("init", this.el);

    const { series, opts } = buildChart(name, setRange);
    const chart = new Chart(name, () => opts(this.el), series, this.el);
    this.subscribe(name, series, chart);
  },

  subscribe<T>(name: string, columns: string[], c: Chart<T>) {
    columns.forEach(column => {
      this.handleEvent(`append_rows:${column}`, ({ rows }: { rows: Row<T>[] }) => {
        c.append(column, rows);
      });
      this.handleEvent(`set_rows:${column}`, ({ column, rows }: { column: string, rows: Row<T>[] }) => {
        c.setRows(column, rows);
      });
    });
  },
};




export default Wut;