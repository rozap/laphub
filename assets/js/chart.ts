import uPlot, { AlignedData } from 'uplot';
import { Row, Track } from './models';
import _ from 'underscore';


interface LineChartOpts {
  title: string;
  scale: string;
  toValues: (u: uPlot, vals: number[], space: number) => string[];
  series: {
    label: string;
    color: string;
    value: (u: uPlot, v: number) => number;
  }[];
}



const makeOptions = (plugins: uPlot.Plugin[], lineChart: LineChartOpts) => (el: HTMLDivElement): uPlot.Options => {
  return {
    title: lineChart.title,
    width: el.clientWidth,
    height: el.clientHeight,
    series: [{}].concat(
      lineChart.series.map(s => ({
        label: s.label,
        scale: lineChart.scale,
        value: s.value,
        stroke: s.color,
        width: 1
      }))
    ),
    plugins,
    axes: [
      {},
      {
        scale: lineChart.scale,
        values: lineChart.toValues,
        grid: { show: true }
      }
    ]
  };
}

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
  }
}


type SetRange = (range: RangeLike) => void;
interface ChartDefinition {
  series: string[],
  opts: (el: HTMLDivElement) => uPlot.Options
}
function buildChart(name: string, setRange: SetRange): ChartDefinition {
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
    {
      name: 'pressures', series: ['oil_pres', 'coolant_pres'], opts: makeOptions(plugins, {
        title: 'Pressures',
        scale: 'psi',
        toValues: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        series: [
          { label: 'Oil Pres', color: 'red', value: (u, v) => v },
          { label: 'Coolant Pres', color: 'blue', value: (u, v) => v }
        ]
      })
    },
    {
      name: 'temperatures', series: ['oil_temp', 'coolant_temp'], opts: makeOptions(plugins, {
        scale: 'degrees',
        title: 'Temperatures',
        toValues: (u, vals, space) => {
          return vals.map((v) => (v / 10).toFixed(1) + '°');
        },
        series: [
          { label: 'Oil Temp', color: 'red', value: (u, v) => v },
          { label: 'Coolant Temp', color: 'blue', value: (u, v) => v }
        ]
      })
    },
    {
      name: 'volts', series: ['voltage'], opts: makeOptions(plugins, {
        title: 'Volts',
        scale: 'volts',
        toValues: (u, vals, space) => {
          return vals.map((v) => (+(v / 1000).toFixed(2)) + 'v');
        },
        series: [
          { label: 'Volts', color: 'green', value: (u, v) => v }
        ]
      })
    },
    {
      name: 'rpm', series: ['rpm'], opts: makeOptions(plugins, {
        title: 'RPM',
        scale: 'rpm',
        toValues: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        series: [
          { label: 'RPM', color: 'pink', value: (u, v) => v }
        ]
      })
    },
    {
      name: 'rsi', series: ['rsi'], opts: makeOptions(plugins, {
        title: 'RSI',
        scale: 'rsi',
        toValues: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        series: [
          { label: 'RSI', color: 'cyan', value: (u, v) => v }
        ]
      })
    },
  ]

  return ChartDefinitions.find(d => d.name === name)!;
}

console.log("buildChart", buildChart)

const ChartHook = {
  mounted() {
    const setRange = (range: RangeLike) => {
      this.pushEvent('set_range', range);
    }
    const el: HTMLDivElement = this.el;

    const name = el.id;
    console.log("BUILDCHART", buildChart, name)
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




export default ChartHook;
