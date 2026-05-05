(function () {
  if (window.__allinoneNowPlayingInstalled) return;

  window.__allinoneNowPlayingInstalled = true;
  window.__allinoneNowPlayingConfig = null;
  window.__allinoneNowPlayingLastPayload = "";
  window.__allinoneNowPlayingTimer = null;

  const cleanText = (value) => {
    if (!value) return "";
    return String(value).replace(/\s+/g, " ").trim();
  };

  const firstText = (selectors) => {
    for (const selector of selectors || []) {
      const element = document.querySelector(selector);
      const text = cleanText(element && (element.innerText || element.textContent || element.getAttribute("title")));
      if (text) return text;
    }
    return "";
  };

  const firstImage = (selectors) => {
    for (const selector of selectors || []) {
      const element = document.querySelector(selector);
      const value = element && (element.currentSrc || element.src || element.getAttribute("src"));
      if (value) return value;
    }
    return "";
  };

  const hasElement = (selectors) => {
    for (const selector of selectors || []) {
      if (document.querySelector(selector)) return true;
    }
    return false;
  };

  const mediaSessionPayload = (platform) => {
    const metadata = navigator.mediaSession && navigator.mediaSession.metadata;
    if (!metadata) return null;
    const artwork = Array.isArray(metadata.artwork) && metadata.artwork.length ? metadata.artwork[metadata.artwork.length - 1].src : "";
    return {
      type: "__allinone_now_playing",
      platform,
      title: cleanText(metadata.title),
      artist: cleanText(metadata.artist),
      album: cleanText(metadata.album),
      artworkUrl: artwork || "",
      isPlaying: false
    };
  };

  const domPayload = (config) => ({
    type: "__allinone_now_playing",
    platform: config.platform,
    title: firstText(config.selectors.title),
    artist: firstText(config.selectors.artist),
    album: firstText(config.selectors.album),
    artworkUrl: firstImage(config.selectors.artwork),
    isPlaying: hasElement(config.selectors.isPlaying)
  });

  const post = (payload) => {
    if (!payload || (!payload.title && !payload.artist)) return;
    const serialized = JSON.stringify(payload);
    if (serialized === window.__allinoneNowPlayingLastPayload) return;
    window.__allinoneNowPlayingLastPayload = serialized;
    window.webkit.messageHandlers.allinone.postMessage(payload);
  };

  const poll = () => {
    const config = window.__allinoneNowPlayingConfig;
    if (!config) return;

    const media = mediaSessionPayload(config.platform);
    const dom = domPayload(config);
    post({
      type: "__allinone_now_playing",
      platform: config.platform,
      title: media && media.title ? media.title : dom.title,
      artist: media && media.artist ? media.artist : dom.artist,
      album: media && media.album ? media.album : dom.album,
      artworkUrl: media && media.artworkUrl ? media.artworkUrl : dom.artworkUrl,
      isPlaying: dom.isPlaying
    });
  };

  window.__allinoneNowPlayingStart = (config) => {
    window.__allinoneNowPlayingConfig = config;
    poll();
    if (!window.__allinoneNowPlayingTimer) {
      window.__allinoneNowPlayingTimer = window.setInterval(poll, 2000);
    }
  };
})();
