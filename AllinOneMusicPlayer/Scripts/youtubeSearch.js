window.__allinoneExtractSearchResults = function () {
  const text = (element) => (element && element.textContent ? element.textContent.trim() : "");
  const attr = (element, name) => (element ? element.getAttribute(name) || "" : "");
  const absoluteURL = (value) => {
    if (!value) return "";
    if (value.startsWith("//")) return `https:${value}`;
    try {
      return new URL(value, window.location.origin).href;
    } catch {
      return "";
    }
  };
  const sectionTitle = (row) => {
    const shelf = row.closest("ytmusic-shelf-renderer");
    if (!shelf) return "";

    const candidates = [
      shelf.querySelector("h2"),
      shelf.querySelector("#title"),
      shelf.querySelector("yt-formatted-string.title.style-scope.ytmusic-shelf-renderer"),
      shelf.querySelector(".title.ytmusic-shelf-renderer"),
    ];
    return candidates.map(text).find(Boolean)?.toLowerCase() || "";
  };
  const cleanArtist = (value) =>
    value
      .replace(/\s*•\s*/g, " - ")
      .replace(/\b(song|songs|video|videos|views|播放|观看|歌曲|视频)\b/gi, "")
      .replace(/\s+-\s+-\s+/g, " - ")
      .replace(/^\s+-\s+|\s+-\s+$/g, "")
      .trim();
  const score = (row, result) => {
    const section = sectionTitle(row);
    const combined = `${section} ${text(row)}`.toLowerCase();
    let value = 0;

    if (/songs?|top result|最佳结果|单曲|歌曲/.test(section)) value += 100;
    if (/albums?|artists?|专辑|艺人|歌手/.test(section)) value += 20;
    if (/videos?|视频/.test(section)) value -= 100;
    if (/official audio|lyrics?|audio|主题曲|专辑/.test(combined)) value += 10;
    if (/views|观看|播放/.test(combined)) value -= 20;
    if (result.playbackURL.includes("music.youtube.com/watch")) value += 10;

    return value;
  };
  const kind = (row) => {
    const section = sectionTitle(row);
    const combined = `${section} ${text(row)}`.toLowerCase();

    if (/videos?|视频|mv/.test(section)) return "video";
    if (/songs?|单曲|歌曲/.test(section)) return "song";
    if (/top result|最佳结果/.test(section) && /song|歌曲|single|单曲/.test(combined)) return "song";
    if (/\bvideo\b|videos?|views|观看|播放/.test(combined)) return "video";
    if (/\bsong\b|songs?|lyrics?|official audio|audio|歌曲|单曲/.test(combined)) return "song";
    return "unknown";
  };

  const shelves = Array.from(document.querySelectorAll("ytmusic-responsive-list-item-renderer"));
  return shelves
    .map((row) => {
      const titleLink =
        row.querySelector("a.yt-simple-endpoint[href^='watch']") ||
        row.querySelector("yt-formatted-string.title a") ||
        row.querySelector(".title a");
      const title =
        text(row.querySelector("yt-formatted-string.title")) ||
        text(titleLink) ||
        attr(titleLink, "title");
      const subtitle = text(row.querySelector(".secondary-flex-columns")) || text(row.querySelector(".flex-column:nth-of-type(2)"));
      const artwork = row.querySelector("img");
      const result = {
        title,
        artist: cleanArtist(subtitle),
        album: "",
        artworkURL: absoluteURL(attr(artwork, "src")),
        playbackURL: absoluteURL(attr(titleLink, "href")),
      };
      return { row, result, kind: kind(row), score: score(row, result) };
    })
    .filter((item) => item.result.title && item.result.playbackURL)
    .filter((item, _, allItems) => {
      const hasSongResults = allItems.some((candidate) => candidate.kind === "song");
      return hasSongResults ? item.kind === "song" : item.kind !== "video";
    })
    .sort((left, right) => right.score - left.score)
    .map((item) => item.result)
    .slice(0, 3);
};
