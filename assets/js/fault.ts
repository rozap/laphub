import { Row } from "./models";

const Fault = {
  mounted(){
    this.getSample();
    this.handleEvent('append_rows:fault', ({ rows } : {rows: Row<any>[]}) => {
      console.log('fault', rows)
      const isOk = rows[0].value === "00000"
      if (!isOk) {
        this.playSound();
      }
    });
    this.handleEvent('fault:test', () => {
      this.playSound();
    });

  },


  async getSample() {
    this.playSound = () => {};
    const context = new AudioContext();

    const audioBuffer = await fetch(
      `${location.protocol}//${location.host}/sounds/error.mp3`
    )
    .then(res => res.arrayBuffer())
    .then(buf => context.decodeAudioData(buf));

    const el: HTMLDivElement = this.el;
    el.onclick = (e: MouseEvent) => {
      context.resume();
    }
    this.playSound = () => {
      console.log("PLAY SOUND")
      const source = context.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(context.destination);
      source.start();

    };
  }



}

export default Fault;