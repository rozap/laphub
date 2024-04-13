import uPlot from 'uplot';
import { DashWidget, Widget, WidgetInitEvent } from './widget';


type ToValues = (u: uPlot, vals: number[], space: number) => string[];
interface LineChartOpts {
  title: string;
  scale: string;
  toValues: ToValues;
  series: {
    label: string;
    color: string;
    value: (u: uPlot, v: number) => number;
  }[];
}

type ChartBuilder = (el: HTMLElement) => uPlot.Options

const makeOptions = (plugins: uPlot.Plugin[], lineChart: LineChartOpts) => (el: HTMLElement): uPlot.Options => {
  return {
    title: lineChart.title,
    width: el.clientWidth,
    height: el.clientHeight,
    // legend: {
    //   show: false,
    //   markers: {
    //     stroke: '1px solid red'
    //   }
    // },
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




function getValueFormatter(units: string | null): ToValues {
  if (units === 'volts') {
    return (u, vals, space) => {
      return vals.map((v) => (+(v / 1000).toFixed(2)) + 'v');
    }
  }
  if (units === 'degrees_f') {
    return (u, vals, space) => {
      return vals.map((v) => (v / 10).toFixed(1) + '°');
    }
  }
  return (u, vals, space) => {
    return vals.map((v) => +v.toFixed(1) + '');
  }
}

function buildChart<T>(widgetDef: DashWidget, w: Widget): ChartBuilder {
  const plugins: uPlot.Plugin[] = [
    {
      hooks: {
        setSelect: (u: uPlot) => {
          const from = Math.round(u.posToVal(u.select.left, 'x'));
          const to = Math.round(u.posToVal(u.select.left + u.select.width, 'x'));
          // w.setRange();

          w.emit({
            type: 'range',
            range: { type: 'unix_second_range', from, to }
          })
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

  return makeOptions(plugins, {
    title: widgetDef.title,
    scale: widgetDef.units,
    toValues: getValueFormatter(widgetDef.units),
    series: widgetDef.columns.map(c => {
      return {
        label: c,
        color: (widgetDef.style.colors || {})[c] || 'black',
        value: (u, v) => v
      }
    })
  })
}

class Chart extends Widget<WidgetInitEvent> {
  uplot: uPlot | undefined;

  init(w: WidgetInitEvent) {
    const el: HTMLElement = this.el as HTMLElement;
    this.resetChart(w.widget);
  }

  resetChart(w: DashWidget) {
    const chartBuilder = buildChart(w, this);
    w.columns.forEach(this.addColumn, this.dimensions);
    this.uplot && this.uplot.destroy();
    this.uplot = new uPlot(chartBuilder(this.el), this.dimensions.dump(), this.el);
  }

  onSetRows(): void {
    this.uplot.setData(this.dimensions.dump());
    // this.resetChart();
  }

  onAppendRows(): void {
    this.uplot.setData(this.dimensions.dump());
    // this.uplot.redraw();
  }
};

export default Chart;