import { strict as assert } from "node:assert";
import { parseChannelFeed, youtubeId } from "../../src/lib/youtube";

describe("youtubeId (006 R3)", () => {
  it("reads the id from every YouTube link form", () => {
    for (const link of [
      "https://www.youtube.com/watch?v=WjbDIjEH38U",
      "https://youtube.com/watch?feature=share&v=WjbDIjEH38U&t=3",
      "https://m.youtube.com/watch?v=WjbDIjEH38U",
      "https://youtu.be/WjbDIjEH38U?si=abc",
      "https://youtube.com/shorts/WjbDIjEH38U?feature=share",
      "https://www.youtube.com/embed/WjbDIjEH38U",
      "https://www.youtube-nocookie.com/embed/WjbDIjEH38U",
      "https://www.youtube.com/live/WjbDIjEH38U",
      "  https://youtube.com/shorts/WjbDIjEH38U  ",
    ]) assert.equal(youtubeId(link), "WjbDIjEH38U", link);
    assert.equal(youtubeId("https://youtu.be/-MGXzWjohFU"), "-MGXzWjohFU");
  });

  it("refuses other sites and broken ids", () => {
    for (const link of [
      "https://vimeo.com/123456",
      "https://example.com/watch?v=WjbDIjEH38U",
      "https://youtube.com.evil.com/watch?v=WjbDIjEH38U",
      "https://www.youtube.com/watch?v=short",
      "https://www.youtube.com/@doctor",
      "https://www.youtube.com/channel/UC47gpnTXG0ki52IwM85Oqdg",
      "WjbDIjEH38U",
      "javascript:alert(1)",
      "",
    ]) assert.equal(youtubeId(link), null, link);
  });
});

describe("parseChannelFeed (006 R7)", () => {
  it("lists entries with id, title and date", () => {
    const xml = `<feed><title>د.أحمد</title><entry><id>yt:video:skgdeAOm374</id><yt:videoId>skgdeAOm374</yt:videoId>
      <title>26 أكتوبر 2026 &amp; تطعيم</title><published>2026-10-26T10:00:00+00:00</published></entry>
      <entry><yt:videoId>bad</yt:videoId><title>x</title></entry>
      <entry><yt:videoId>eH9QRdN_Hgw</yt:videoId><title>20 أكتوبر</title><published>2026-10-20T10:00:00+00:00</published></entry></feed>`;
    assert.deepEqual(parseChannelFeed(xml), [
      { id: "skgdeAOm374", title: "26 أكتوبر 2026 & تطعيم", published: "2026-10-26T10:00:00+00:00" },
      { id: "eH9QRdN_Hgw", title: "20 أكتوبر", published: "2026-10-20T10:00:00+00:00" },
    ]);
  });
});
