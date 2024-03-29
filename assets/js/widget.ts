import { Hook } from "phoenix_typed_hook";
import { AlignedData } from 'uplot';
import Emitter from "./emitter";
import { Row } from './models';
import _ from 'underscore';

export type Seconds = number;
export type KV = [Seconds, unknown];


const rowKey = (row: Row) => {
  return parseInt(row.t) / 1000;
}
class Dimensions {
  time: number[] = []
  columns: Record<string, unknown[]> = {};

  constructor() { }

  addColumn(column: string) {
    this.columns[column] = this.columns[column] || [];
  }

  removeColumn(column: string) {
    delete this.columns[column];
  }

  getColumns() {
    return Object.keys(this.columns);
  }

  clearAll() {
    this.time = [];
    const columns = this.getColumns();
    this.columns = {};
    columns.forEach((c) => this.addColumn(c));
  }



  setRows(column: string, rows: Row[]): KV[] {
    console.log("setRows", column);
    const result: KV[] = rows.map(r => {
      return [rowKey(r), r.value];
    });

    const newDimensionLookup = {};
    result.forEach(([t, value]) => {
      newDimensionLookup[t] = value
    });


    const lookups = Object.keys(this.columns).filter(c => c !== column).map((column) => {
      const zipped = _.zip(this.time, this.columns[column]);
      const lookup = {}
      zipped.forEach(([t, v]) => {
        lookup[t] = v;
      });
      return { column, lookup };
    }).reduce((acc, { column, lookup }) => {
      acc[column] = lookup;
      return acc;
    }, {
      [column]: newDimensionLookup
    });

    // add the new timestamps using an merge sort
    // style thing
    const toAdd = rows.map(rowKey);
    let newTime = [];

    if (this.time.length == 0) {
      // nothing to merge
      newTime = toAdd;
    } else {
      let nt = 0;
      let ot = 0;
      while (ot < this.time.length && nt < toAdd.length) {
        if (this.time[ot] < toAdd[nt]) {
          newTime.push(this.time[ot]);
          ot++;
        } else if (this.time[ot] > toAdd[nt]) {
          newTime.push(toAdd[nt]);
          nt++
        } else if (this.time[ot] == toAdd[nt]) {
          newTime.push(this.time[ot]);
          ot++;
          nt++;
        }
      }

    }

    const newWindows = {};
    Object.keys(lookups).forEach((column) => {
      const lookup = lookups[column];
      const series = newTime.map(t => lookup[t]);
      newWindows[column] = series;
    });

    this.columns = newWindows;
    this.time = newTime;

    return result;
  }

  appendRows(column: string, rows: Row[]): KV[] {
    return rows.map(r => {
      const t = rowKey(r);
      this._append(t, column, r.value);
      return [t, r.value]
    });
  }


  _append(t: number, column: string, value: unknown) {
    if (!this.columns[column]) {
      console.warn("unknown value", column, "in", Object.keys(this.columns));
      return;
    }
    const frontier = _.last(this.time);

    if (frontier && t < frontier) {
      // console.warn("Appended value < frontier, skipping", frontier, t)
      return;
    }

    if (t !== frontier) {
      this.time.push(t);

      Object.keys(this.columns).map((key: string) => {
        this.columns[key][this.time.length - 1] = undefined
      });
    }

    this.columns[column][this.time.length - 1] = value;
  }


  dump(): AlignedData {
    return [
      this.time,
      ...Object.keys(this.columns).map((column) => {
        return this.columns[column]
      })
    ] as any as AlignedData
  }
}

export interface RangeLike {
  type: 'unix_millis_range' | 'unix_second_range',
  from: number,
  to: number
}
type SetRange = (range: RangeLike) => void;
interface RowResp { column: string, rows: Row[] };


export interface WidgetHoverEvent {
  type: 'hover',
  k: number;
  values: {
    column: string;
    value: unknown;
  }[],
  idx: number
};

export interface WidgetRangeEvent {
  type: 'range',
  range: RangeLike
}
export type WidgetState =
  'realtime' |
  'paused';

export interface WidgetStateEvent {
  type: 'state',
  state: WidgetState
}

type WidgetEvent =
  WidgetHoverEvent |
  WidgetRangeEvent |
  WidgetStateEvent


export class Widget {
  columns: string[] = [];
  dimensions: Dimensions;
  hook: Hook;
  rows: Record<string, Row[]>;
  emitter: Emitter<WidgetEvent>;
  state: WidgetState;

  constructor(h: Hook, emitter: Emitter<WidgetEvent>) {
    this.hook = h;
    this.emitter = emitter;
    this.dimensions = new Dimensions();
    this.state = 'realtime';
    this.init();
    this.getColumns().forEach(this.subscribeTo);

    emitter.on('range', (re: WidgetRangeEvent) => {
      this.setRange(re.range);
    });
    emitter.on('state', (ws: WidgetStateEvent) => {
      this.state = ws.state;
      console.log("state is now", ws.state)
    });
  }

  emit = (event: WidgetEvent) => {
    this.emitter.emit(event.type, event);
  }


  public get el(): HTMLElement {
    return this.hook.el;
  }


  getColumns = () => { return this.dimensions.getColumns() };
  addColumn = (c: string) => {
    this.dimensions.addColumn(c);
    this.subscribeTo(c);
  }

  removeColumn = (c: string) => {
    this.dimensions.removeColumn(c);
    this.unSubscribeFrom(c);
  }

  subscribeTo = (column: string) => {
    // this.
    this.hook.handleEvent(`append_rows:${column}`, ({ rows }: RowResp) => {
      this.appendRows(column, rows);
    });
    this.hook.handleEvent(`set_rows:${column}`, ({ column, rows }: RowResp) => {
      this.setRows(column, rows);
    });
  }

  unSubscribeFrom = (column: string) => {
    this.hook.handleEvent(`append_rows:${column}`, () => { });
    this.hook.handleEvent(`set_rows:${column}`, () => { });
  }



  appendRows = (column: string, rows: Row[]) => {
    const kvs = this.dimensions.appendRows(column, rows);
    if (this.state === 'realtime') {
      this.onAppendRows(column, kvs);
    }
    // this.uplot.setData(this.dimensions.dump())
  }

  setRows = (column: string, rows: Row[]) => {
    this.dimensions.clearAll();
    const kvs = this.dimensions.setRows(column, rows);
    // const kvs = this.putRows(column, rows);
    this.onSetRows(column, kvs);
    // this.reinit();
  }

  setRange = (range: RangeLike) => {
    this.hook.pushEvent('set_range', range);
    this.emit({
      type: 'state',
      state: 'paused'
    });
    this.state = 'paused';
  }

  init() {
    // pls override
  }

  onAppendRows(column: string, rows: KV[]) {
    // pls override
  }

  onSetRows(column: string, rows: KV[]) {
    // pls override
  }
}

