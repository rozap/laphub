import { RangeLike, Widget, WidgetState, WidgetStateEvent } from './widget';

class DateRange extends Widget {

  init() {
    this.hook.handleEvent('set_range', ({ range }: { range: RangeLike }) => {
      console.log('set_Range', range);
      this.emit({
        type: 'range',
        range
      })
    });
    this.hook.handleEvent('set_widget_state', ({ state }: { state: WidgetState}) => {
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

}

export default DateRange;