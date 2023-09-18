import { Hook } from "phoenix_typed_hook";
import { AlignedData } from 'uplot';
import { Row } from './models';

class Dimensions {
  windows: Record<string, [number, T][]> = {};

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



export class Widget {
  columns: string[] = [];
  dimensions: Dimensions;
  hook: Hook;
  rows: Record<string, Row[]>;

  constructor(h: Hook) {
    this.hook = h;
    this.dimensions = new Dimensions();
    this.init();
    this.getColumns().forEach(this.subscribeTo);
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
    this.hook.handleEvent(`append_rows:${column}`, this.appendRows(column));
    this.hook.handleEvent(`set_rows:${column}`, ({ column, rows }: { column: string, rows: Row[] }) => {

      console.log("guhhhhh");
      this.setRows(column, rows);
    });
  }

  unSubscribeFrom = (column: string) => {
    this.hook.handleEvent(`append_rows:${column}`, () => { });
    this.hook.handleEvent(`set_rows:${column}`, () => { });
  }


  private putRows = (column: string, rows: Row[]) => {
    rows.forEach(row => {
      const t = parseInt(row.t) / 1000;
      this.dimensions.append(t, column, row.value);
    });
  }

  appendRows = (column: string) => (rows: Row[]) => {
    this.putRows(column, rows);
    this.onAppendRows();
    // this.uplot.setData(this.dimensions.dump())
  }

  setRows = (column: string, rows: Row[]) => {
    console.log("WTF? set rows", column, rows);
    this.dimensions.clear(column);
    this.putRows(column, rows);
    this.onSetRows();
    // this.reinit();
  }

  setRange = (range: RangeLike) => {
    this.hook.pushEvent('set_range', range);
  }

  init() {
    // pls override
  }

  onAppendRows() {
    // pls override
  }

  onSetRows() {
    // pls override
  }
}

