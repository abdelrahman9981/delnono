/** YouTube links and the channel feed (006 R3, R7; D-50). */

const HOSTS = ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtube-nocookie.com", "www.youtube-nocookie.com"];
const ID = /^[A-Za-z0-9_-]{11}$/;

/** The 11-character video id of a YouTube link, or null for anything else. */
export function youtubeId(link: string): string | null {
  let url: URL;
  try {
    url = new URL(link.trim());
  } catch {
    return null;
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") return null;
  const host = url.hostname.toLowerCase();
  const parts = url.pathname.split("/").filter(Boolean);
  let id: string | null | undefined;
  if (host === "youtu.be") id = parts[0];
  else if (HOSTS.includes(host)) {
    if (parts[0] === "watch") id = url.searchParams.get("v");
    else if (["shorts", "embed", "live", "v"].includes(parts[0])) id = parts[1];
  }
  return id && ID.test(id) ? id : null;
}

export interface FeedVideo {
  id: string;
  title: string;
  published: string;
}

/** Entries of a channel's Atom feed (`/feeds/videos.xml?channel_id=`), newest first as given. */
export function parseChannelFeed(xml: string): FeedVideo[] {
  const videos: FeedVideo[] = [];
  for (const entry of xml.split("<entry>").slice(1)) {
    const id = /<yt:videoId>([^<]+)<\/yt:videoId>/.exec(entry)?.[1];
    if (!id || !ID.test(id)) continue;
    videos.push({
      id,
      title: decode(/<title>([^<]*)<\/title>/.exec(entry)?.[1] ?? ""),
      published: /<published>([^<]+)<\/published>/.exec(entry)?.[1] ?? "",
    });
  }
  return videos;
}

function decode(s: string): string {
  return s.replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
}
