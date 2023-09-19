import { Hook } from "phoenix_typed_hook";
import { AlignedData } from 'uplot';
import Emitter from "./emitter";
import { Row } from './models';

export type Seconds = number;
export type KV = [Seconds, unknown];

class Dimensions {
  windows: Record<string, KV[]> = {};

  constructor() { }

  addColumn(column: string) {
    this.windows[column] = this.windows[column] || [];
  }

  removeColumn(column: string) {
    delete this.windows[column];
  }

  getColumns() {
    return Object.keys(this.windows);
  }

  append(t: number, column: string, value: T) {
    if (!this.windows[column]) {
      console.warn("unknown value", column, "in", Object.keys(this.windows));
      return;
    }
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
type SetRange = (range: RangeLike) => void;
interface RowResp { column: string, rows: Row[] };


interface ChartHover {
  type: 'hover',
  k: number;
  values: {
    column: string;
    value: unknown;
  }[],
  idx: number
};

type WidgetEvent =
  ChartHover

export class Widget {
  columns: string[] = [];
  dimensions: Dimensions;
  hook: Hook;
  rows: Record<string, Row[]>;
  emitter: Emitter<WidgetEvent>;

  constructor(h: Hook, emitter: Emitter<WidgetEvent>) {
    this.hook = h;
    this.emitter = emitter;
    this.dimensions = new Dimensions();
    this.init();
    this.getColumns().forEach(this.subscribeTo);
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


  private putRows = (column: string, rows: Row[]): KV[] => {
    return rows.map(row => {
      const t = parseInt(row.t) / 1000;
      this.dimensions.append(t, column, row.value);
      return [t, row.value]
    });
  }

  appendRows = (column: string, rows: Row[]) => {
    const kvs = this.putRows(column, rows);
    this.onAppendRows(column, kvs);
    // this.uplot.setData(this.dimensions.dump())
  }

  setRows = (column: string, rows: Row[]) => {
    this.dimensions.clear(column);
    const kvs = this.putRows(column, rows);
    this.onSetRows(column, kvs);
    // this.reinit();
  }

  setRange = (range: RangeLike) => {
    this.hook.pushEvent('set_range', range);
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

