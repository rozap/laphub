import { Row } from "./models";
import Sortable from 'sortablejs';

const Dnd = {
  mounted() {
    let sorter = new Sortable(this.el, {
      animation: 150,
      delay: 100,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      forceFallback: true,
      onEnd: e => {
        let params = { 
          old: e.oldIndex, 
          new: e.newIndex, 
          ...e.item.dataset 
        }
        this.pushEventTo(this.el, "dnd", params)
      }
    })

  },
}

export default Dnd;