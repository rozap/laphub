
type CB<E> = (ev: E) => void;

class Emitter<E> {
  handlers: Record<string, CB<E>[]> = {};

  on = (event: string, cb: CB<E>) => {
    this.handlers[event] = [...(this.handlers[event] || []), cb]
  }

  off = (event: string, toRemove: CB<E>) => {
    const without = (this.handlers[event] || []).filter(cb => cb != toRemove);
    this.handlers[event] = without;
  }

  emit = (event: string, value: E) => {
    (this.handlers[event] || []).forEach(cb => cb(value))
  }
}

export default Emitter;