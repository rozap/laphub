import uPlot from 'uplot';
import { Widget } from './widget';


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



const makeOptions = (plugins: uPlot.Plugin[], lineChart: LineChartOpts) => (el: HTMLElement): uPlot.Options => {
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



interface ChartDefinition {
  series: string[],
  opts: (el: HTMLElement) => uPlot.Options
}
function buildChart<T>(name: string, w: Widget): ChartDefinition {
  const plugins: uPlot.Plugin[] = [
    {
      hooks: {
        setSelect: (u: uPlot) => {
          const from = Math.round(u.posToVal(u.select.left, 'x'));
          const to = Math.round(u.posToVal(u.select.left + u.select.width, 'x'));
          w.setRange({ type: 'unix_millis_range', from, to });
        },
        setCursor: (u: uPlot) => {
          if (!u.cursor.idx) return;
          const values = u.series.slice(1).map((s, seriesIdx) => {
            return {
              column: s.label,
              value: u.data[seriesIdx][u.cursor.idx]

            }
          })
          w.emit({
            type: 'hover',
            k: u.data[0][u.cursor.idx],
            idx: u.cursor.idx,
            values
          });
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
      name: 'speed', series: ['speed'], opts: makeOptions(plugins, {
        title: 'Speed',
        scale: 'speed',
        toValues: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '');
        },
        series: [
          { label: 'speed', color: 'pink', value: (u, v) => v }
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

class Chart extends Widget {
  uplot: uPlot | undefined;

  init() {
    const el: HTMLElement = this.el as HTMLElement;
    const name = el.id;
    this.resetChart();
  }

  getName() {
    return this.el.id;
  }

  resetChart() {
    const { series, opts } = buildChart(this.getName(), this);
    series.forEach(this.addColumn, this.dimensions);
    this.uplot && this.uplot.destroy();
    this.uplot = new uPlot(opts(this.el), this.dimensions.dump(), this.el);
  }

  onSetRows(): void {
    this.resetChart();
  }

  onAppendRows(): void {
    this.uplot.setData(this.dimensions.dump());
    // this.uplot.redraw();
  }
};

export default Chart;