import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Chart from './chart'
import Map from './map';
import DateRange from './date-range';

import Fault from './fault';
import Emitter from './emitter';
import Dnd from './dnd';

// c = new Chart();
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")


const emitter = new Emitter();
const hooks = {
  Chart: {
    mounted() {
      new Chart(this, emitter);
    }
  },
  Map: {
    mounted() {
      new Map(this, emitter);
    }
  },
  DateRange: {
    mounted() {
      new DateRange(this, emitter);
    }
  },
  Fault,
  Dnd
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks, params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()
liveSocket.disableDebug();
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

