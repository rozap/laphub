import uPlot from 'uplot';

const opts = (element: HTMLDivElement): uPlot.Options => {
  element.offsetWidth
  return {
    title: 'Server Events',
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
        label: 'CPU',
        scale: '%',
        value: (u, v) => v,
        stroke: 'red',
        width: 1
      },
      {
        label: 'Cos',
        scale: 'whatever',
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
          // setScale: (a) => {
          //   console.log("set scale", a)
          // }
        }
      }
    ],
    axes: [
      {},
      {
        scale: 'whatever',
        values: (u, vals, space) => {
          return vals.map((v) => +v.toFixed(1) + '%');
        }
      },
      {
        side: 1,
        scale: 'mb',
        size: 60,
        values: (u, vals, space) => vals.map((v) => +v.toFixed(2) + ' MB'),
        grid: { show: false }
      }
    ]
  };
};

const x: number[] = [];
const data = [x, [], []];

interface Row {
  t: number,
  series: Record<string, number>
}

interface Append {
  append: Row[]
}

export default {
  mounted() {
    console.log('mounted the lap view');
    let uplot = new uPlot(opts(this.el), data, this.el);

    // to reset the selection
    // u.setScale('x', {min: 500, max: 1000})
    window.u = uplot;

    this.handleEvent('foo', ({ append }: Append) => {
      append.forEach(row => {
        x.push(row.t);

        // lol sort this
        Object.keys(row.series).map((k, i) => {
          data[i + 1].push(row.series[k])
        });
      })
      // append.forEach(([]) => {
      //   console.log()
      //   x.push(newX);
      //   rest.forEach((value, index) => {
      //     data[index + 1].push(value);
      //   });
      // });

      if (uplot.select.width === 0) {
        uplot.setData(data);
      }
      console.log(uplot.select)
      // uplot.hooks.setScale = (u) => {
      //   console.log('scale', u);
      // }
    })
  },
};
