import Hls from 'hls.js';

const Video = {
  mounted() {
    console.log('video mounted')
    const path = this.el.getAttribute('data-root');
    const video = this.el.querySelector('video')
    const videoSrc = window.location.origin + path;
    console.log('src', videoSrc)
    if (Hls.isSupported()) {
      const hls = new Hls();
      hls.loadSource(videoSrc);
      hls.attachMedia(video);
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = videoSrc;
    }
  }
}

export default Video;