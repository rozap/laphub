import { Hook } from 'phoenix_typed_hook';
import Emitter from './emitter';
import { RangeLike, Widget, WidgetEvent, WidgetInitEvent, WidgetState, WidgetStateEvent } from './widget';

class DateRange {
  hook: Hook;
  emitter: Emitter<WidgetEvent>;

  constructor(h: Hook, emitter: Emitter<WidgetEvent>) {
    this.hook = h;
    this.emitter = emitter;
    this.emitter.on('range', (value) => {
      if (value.type === 'range') {
        this.hook.pushEvent('set_range', value.range);
      }
    })
    this.hook.handleEvent('set_range', ({ range }: { range: RangeLike }) => {
      console.log('set_Range', range);
      this.emit({
        type: 'range',
        range
      })
    });
    this.hook.handleEvent('set_widget_state', ({ state }: { state: WidgetState }) => {
      this.emit({
        type: 'state',
        state
      })
    });
    this.emitter.on('state', (ws: WidgetStateEvent) => {
      this.hook.pushEvent('set_state', {
        state: ws.state
      })
    });
  }

  emit = (event: WidgetEvent) => {
    this.emitter.emit(event.type, event);
  }

}

export default DateRange;