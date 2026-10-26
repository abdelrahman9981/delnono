# Data Model: Content Library

## content/{id}
| Field | Type | Rules |
|---|---|---|
| type | `video` \| `tip` | required |
| title | string | 1–120 chars |
| category | string | an id in `settings/content.categories` |
| body | string? | ≤ 4000; required for a tip |
| youtubeId | string? | 11 chars `[A-Za-z0-9_-]`; required for a video; unique across items |
| url | string? | the original pasted link (video only) |
| ageFromMonths, ageToMonths | int? | both or neither; 0 ≤ from ≤ to ≤ 216 |
| order | int | default 100; lower first |
| status | `draft` \| `published` \| `archived` | changed only by `setContentStatus` (doctor) except new items (draft) |
| createdBy/At, updatedBy/At, publishedBy/At | | server |

Transitions: draft → published (publish), published → draft (unpublish), draft/published → archived (archive), archived → draft (restore). Doctor only.

Legacy 005 items without `type` read as `video` when they have a url/youtubeId, else `tip`; missing order reads 100.

## settings/content
| Field | Type |
|---|---|
| categories | list of `{id: string, name: string}` in display order |

## Audit actions
`content.published`, `content.unpublished`, `content.archived`, `content.restored`, `content.categories_updated`.
