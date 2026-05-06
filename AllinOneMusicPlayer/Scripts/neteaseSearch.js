window.__allinoneExtractSearchResults = function () {
  const text = (element) => (element && element.textContent ? element.textContent.trim() : "");
  const attr = (element, name) => (element ? element.getAttribute(name) || "" : "");
  const absoluteURL = (value) => {
    if (!value) return "";
    try {
      return new URL(value, window.location.origin).href;
    } catch {
      return "";
    }
  };

  const extractFromDocument = (doc) => {
    const rows = Array.from(doc.querySelectorAll(".m-table tbody tr, .srchsongst .item, tr"));
    const seen = new Set();
    const results = [];

    for (const row of rows) {
      const songLink =
        row.querySelector("a[href*='song?id=']") ||
        row.querySelector("a[href*='/song?id=']");
      const playbackURL = absoluteURL(attr(songLink, "href"));
      if (!playbackURL || seen.has(playbackURL)) continue;
      seen.add(playbackURL);

      const title =
        attr(songLink, "title") ||
        text(songLink.querySelector("b")) ||
        text(songLink);
      const artist = Array.from(row.querySelectorAll("a[href*='artist?id=']"))
        .map(text)
        .filter(Boolean)
        .join(", ");
      const album = text(row.querySelector("a[href*='album?id=']"));

      if (title) {
        results.push({
          title,
          artist,
          album,
          artworkURL: "",
          playbackURL,
        });
      }

      if (results.length >= 3) return results;
    }

    return results;
  };

  const iframe = document.querySelector("#g_iframe");
  let results = extractFromDocument(document);

  try {
    if (iframe && iframe.contentDocument) {
      results = extractFromDocument(iframe.contentDocument);
    }
  } catch {}

  return results.slice(0, 3);
};
