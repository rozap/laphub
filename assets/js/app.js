import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Chart from './chart'
import Map from './map';
import Fault from './fault';

// c = new Chart();
console.log("WTF???", Chart)

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const hooks = {
  Chart: {
    mounted() {
      new Chart(this);
    }
  },
  Map,
  Fault
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

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

