(function () {
  const scriptVersion = 4;
  if (window.__allinoneNowPlayingInstalledVersion >= scriptVersion) return;

  if (window.__allinoneNowPlayingTimer) {
    window.clearInterval(window.__allinoneNowPlayingTimer);
  }
  if (window.__allinoneNowPlayingPollTimeout) {
    window.clearTimeout(window.__allinoneNowPlayingPollTimeout);
  }
  if (window.__allinoneNowPlayingObserver) {
    window.__allinoneNowPlayingObserver.disconnect();
  }

  window.__allinoneNowPlayingInstalled = true;
  window.__allinoneNowPlayingInstalledVersion = scriptVersion;
  window.__allinoneNowPlayingConfig = null;
  window.__allinoneNowPlayingLastPayload = "";
  window.__allinoneNowPlayingTimer = null;
  window.__allinoneNowPlayingObserver = null;
  window.__allinoneNowPlayingPollTimeout = null;
  window.__allinoneNowPlayingMediaSessionHooked = false;

  const cleanText = (value) => {
    if (!value) return "";
    return String(value).replace(/\s+/g, " ").trim();
  };

  const isVisible = (element) => {
    if (!element) return false;
    const rect = element.getBoundingClientRect();
    const style = window.getComputedStyle(element);
    return rect.width > 0
      && rect.height > 0
      && style.visibility !== "hidden"
      && style.display !== "none"
      && style.opacity !== "0";
  };

  const firstText = (selectors) => {
    for (const selector of selectors || []) {
      const elements = Array.from(document.querySelectorAll(selector));
      const visibleElements = elements.filter(isVisible);
      const candidates = visibleElements.length ? visibleElements : elements;

      for (const element of candidates) {
        const text = cleanText(element && (element.getAttribute("title") || element.innerText || element.textContent));
        if (text) return text;
      }
    }
    return "";
  };

  const firstImage = (selectors) => {
    for (const selector of selectors || []) {
      const elements = Array.from(document.querySelectorAll(selector));
      const visibleElements = elements.filter(isVisible);
      const candidates = visibleElements.length ? visibleElements : elements;

      for (const element of candidates) {
        const value = element && (element.currentSrc || element.src || element.getAttribute("src"));
        if (value) return value;
      }
    }
    return "";
  };

  const hasElement = (selectors) => {
    for (const selector of selectors || []) {
      const elements = Array.from(document.querySelectorAll(selector));
      if (elements.some(isVisible) || elements.length > 0) return true;
    }
    return false;
  };

  const mediaElementIsPlaying = () => {
    const mediaElements = Array.from(document.querySelectorAll("video, audio"));
    return mediaElements.some((element) => {
      try {
        return !element.paused && !element.ended && element.readyState > 1;
      } catch (_) {
        return false;
      }
    });
  };

  const mediaSessionIsPlaying = () => {
    try {
      return navigator.mediaSession && navigator.mediaSession.playbackState === "playing";
    } catch (_) {
      return false;
    }
  };

  const youtubeButtonLooksPaused = () => {
    const buttons = Array.from(document.querySelectorAll("#play-pause-button, tp-yt-paper-icon-button, button"));
    return buttons.some((button) => {
      const text = cleanText([
        button.getAttribute("aria-label"),
        button.getAttribute("title"),
        button.getAttribute("data-title-no-tooltip"),
        button.textContent
      ].filter(Boolean).join(" "));

      return /pause|暂停|一時停止|pausa|pausar/i.test(text);
    });
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
      isPlaying: mediaSessionIsPlaying() || mediaElementIsPlaying()
    };
  };

  const domPayload = (config) => {
    const selectorPlaying = hasElement(config.selectors.isPlaying);
    const platformPlaying = config.platform === "youtube"
      ? selectorPlaying || mediaSessionIsPlaying() || mediaElementIsPlaying() || youtubeButtonLooksPaused()
      : selectorPlaying;

    return {
      type: "__allinone_now_playing",
      platform: config.platform,
      title: firstText(config.selectors.title),
      artist: firstText(config.selectors.artist),
      album: firstText(config.selectors.album),
      artworkUrl: firstImage(config.selectors.artwork),
      isPlaying: platformPlaying
    };
  };

  const youtubeTitlePayload = () => {
    const rawTitle = cleanText(document.title)
      .replace(/\s+-\s+YouTube Music$/i, "")
      .replace(/\s+-\s+YouTube$/i, "");

    if (!rawTitle || rawTitle === document.title || rawTitle.toLowerCase() === "youtube music") return null;

    const parts = rawTitle.split(" - ").map(cleanText).filter(Boolean);
    return {
      type: "__allinone_now_playing",
      platform: "youtube",
      title: parts[0] || rawTitle,
      artist: parts.length > 1 ? parts.slice(1).join(" - ") : "",
      album: "",
      artworkUrl: "",
      isPlaying: false
    };
  };

  const post = (payload) => {
    if (!payload || (!payload.title && !payload.artist)) return;
    const serialized = JSON.stringify(payload);
    if (serialized === window.__allinoneNowPlayingLastPayload) return;
    window.__allinoneNowPlayingLastPayload = serialized;
    window.webkit.messageHandlers.allinone.postMessage(payload);
  };

  const postMediaSession = () => {
    const config = window.__allinoneNowPlayingConfig;
    if (!config) return;

    const payload = mediaSessionPayload(config.platform);
    if (!payload || (!payload.title && !payload.artist)) return;

    const dom = domPayload(config);
    payload.isPlaying = dom.isPlaying;
    post(payload);
  };

  const poll = () => {
    const config = window.__allinoneNowPlayingConfig;
    if (!config) return;

    const media = mediaSessionPayload(config.platform);
    const dom = domPayload(config);
    const title = config.platform === "youtube" ? youtubeTitlePayload() : null;
    const sources = config.prefersDOMMetadata ? [title, dom, media] : [media, dom, title];
    const firstValue = (key) => {
      for (const source of sources) {
        if (source && source[key]) return source[key];
      }
      return "";
    };

    post({
      type: "__allinone_now_playing",
      platform: config.platform,
      title: firstValue("title"),
      artist: firstValue("artist"),
      album: firstValue("album"),
      artworkUrl: firstValue("artworkUrl"),
      isPlaying: dom.isPlaying || (media && media.isPlaying) || (title && title.isPlaying)
    });
  };

  const schedulePoll = () => {
    window.clearTimeout(window.__allinoneNowPlayingPollTimeout);
    window.__allinoneNowPlayingPollTimeout = window.setTimeout(poll, 80);
  };

  const configureObserver = () => {
    if (window.__allinoneNowPlayingObserver) return;

    window.__allinoneNowPlayingObserver = new MutationObserver(schedulePoll);
    window.__allinoneNowPlayingObserver.observe(document.documentElement, {
      subtree: true,
      childList: true,
      characterData: true,
      attributes: true,
      attributeFilter: ["title", "aria-label", "src", "player-ui-state_", "play-button-state"]
    });
  };

  const hookMediaSession = () => {
    if (window.__allinoneNowPlayingMediaSessionHooked) return;
    window.__allinoneNowPlayingMediaSessionHooked = true;

    try {
      const prototype = Object.getPrototypeOf(navigator.mediaSession);
      const descriptor = Object.getOwnPropertyDescriptor(prototype, "metadata");
      if (!descriptor || !descriptor.set || !descriptor.get) return;

      Object.defineProperty(prototype, "metadata", {
        configurable: true,
        enumerable: descriptor.enumerable,
        get() {
          return descriptor.get.call(this);
        },
        set(value) {
          descriptor.set.call(this, value);
          window.setTimeout(postMediaSession, 0);
          window.setTimeout(poll, 120);
          window.setTimeout(poll, 500);
        }
      });
    } catch (_) {}
  };

  window.__allinoneNowPlayingStart = (config) => {
    window.__allinoneNowPlayingConfig = config;
    configureObserver();
    hookMediaSession();
    poll();
    if (!window.__allinoneNowPlayingTimer) {
      window.__allinoneNowPlayingTimer = window.setInterval(poll, 1000);
    }
  };
})();
