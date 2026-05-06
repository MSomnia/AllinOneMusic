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

  const links = Array.from(document.querySelectorAll("a[href*='/track/']"));
  const seen = new Set();
  const results = [];

  for (const link of links) {
    const playbackURL = absoluteURL(attr(link, "href").split("?")[0]);
    if (!playbackURL || seen.has(playbackURL)) continue;
    seen.add(playbackURL);

    const row =
      link.closest("[data-testid='tracklist-row']") ||
      link.closest("[role='row']") ||
      link.closest("div");
    const title = attr(link, "title") || text(link);
    const artists = Array.from(row ? row.querySelectorAll("a[href*='/artist/']") : [])
      .map(text)
      .filter(Boolean)
      .join(", ");
    const artwork = row ? row.querySelector("img") : null;

    if (title) {
      results.push({
        title,
        artist: artists,
        album: "",
        artworkURL: absoluteURL(attr(artwork, "src")),
        playbackURL,
      });
    }

    if (results.length >= 3) return results;
  }

  return results;
};
