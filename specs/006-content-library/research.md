# Research: Content Library

## R1 In-app player
- **Decision**: `youtube_player_iframe` 6.x (official IFrame API in a WebView; also works on Flutter Web for the dashboard preview). Full-screen route with a black background and the player in `AspectRatio(9/16)`; Shorts are vertical (owner).
- **Rationale**: D-50 asks for in-app playback; the IFrame API is YouTube's supported embed; Unlisted videos embed by id.
- **Alternatives**: `youtube_player_flutter` (Android/iOS only, no web), opening YouTube for every video (not in-app).

## R2 Fallback when embedding fails
- **Decision**: Listen for the player's error (codes 2, 5, 100, 101, 105, 150, 152); show «الفيديو ده مش متاح هنا.» with «شوفي الفيديو على يوتيوب» (`url_launcher`, external app, `https://www.youtube.com/shorts/<id>`). The button is always visible under the player, so no load timeout is needed (a timeout would also fire when iOS simply waits for a tap to play).
- **Rationale**: Owner asked for the fallback when a video blocks embedding; a private or deleted video gives the same errors.

## R3 Link validation
- **Decision**: One parser per language (Dart for the dashboard, TS for the server): accepts `youtube.com/watch?v=`, `youtu.be/`, `youtube.com/shorts/`, `/embed/`, `/live/`, `m.` and `www.` hosts, `youtube-nocookie.com/embed`, extra parameters; id = 11 chars `[A-Za-z0-9_-]`. Anything else → `invalid_youtube`. Thumbnail `https://i.ytimg.com/vi/<id>/hqdefault.jpg`.
- **Rationale**: Same rule on both sides; server is the authority (staff can't bypass the dashboard).

## R4 Offline
- **Decision**: Firestore's offline cache (on by default on mobile) keeps loaded published items and categories; the video route checks `connectivity_plus` and shows «الفيديو محتاج إنترنت» when offline.
- **Alternatives**: Own cache in shared_preferences (duplicate of Firestore's cache).

## R5 Categories
- **Decision**: `settings/content.categories = [{id, name}]`, readable by all (existing `settings` rule), written by doctor-only callable `saveContentCategories` (rename and reorder; ids fixed; removing a category in use refused `in_use`). Seed: fever, feeding, sleep, allergy (BRD) + vaccines, newborn (Assumption — needs owner review).

## R6 Status changes
- **Decision**: `saveContent` saves fields (drafts by anyone on staff; a published item's fields by the doctor only, as in 005). New `setContentStatus {id, status}` doctor only: draft→published (publish), published→draft (unpublish), any→archived (archive), archived→draft (restore). Audit `content.published` / `content.unpublished` / `content.archived` / `content.restored`.
- **Rationale**: Clear one-action-one-audit; rules stay `write: false`.

## R7 Channel import
- **Decision**: Callable `channelVideos` (staff) fetches `https://www.youtube.com/feeds/videos.xml?channel_id=UC47gpnTXG0ki52IwM85Oqdg` (latest 15), returns `{id, title, published, alreadyAdded}`. Feed titles are dates for Shorts, so the draft title must be typed. Works in the emulator; on the real project it needs deployed Functions → "blocked: Blaze". Feed URL overridable by env for tests.

## R8 Seed titles
- **Decision**: Titles read from the text on each Short's frame (owner); categories guessed; all marked "Assumption — needs owner review" in the report table. Published for the demo: WjbDIjEH38U, TGzE9d9m44A, KDOV-4nbWqU (clear, non-medication titles).

## R9 Search
- **Decision**: Normalise Arabic (أ إ آ → ا, ة → ه, ى → ي, strip tashkeel and tatweel) on both title and query; contains match.
