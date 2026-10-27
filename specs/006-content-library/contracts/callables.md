# Callables: Content Library (me-central1 since D-53)

| Callable | Who | Input | Output | Errors (`details.reason` / `field`) |
|---|---|---|---|---|
| `saveContent` | staff; existing non-draft items: doctor | `{id?, type, title, category, body?, url?, ageFromMonths?, ageToMonths?, order?}` | `{id}` | `doctor_only`, `invalid_youtube`, `duplicate` (+`existingId`), field errors |
| `setContentStatus` | doctor | `{id, status}` | `{}` | `doctor_only`, `not-found`, `invalid_transition` |
| `saveContentCategories` | doctor | `{categories:[{id,name}]}` | `{}` | `doctor_only`, `in_use` (+`category`), field errors |
| `channelVideos` | staff | `{}` | `{videos:[{id,title,published,alreadyAdded}]}` | `unavailable` when the feed can't be read |

`saveContent` never changes `status` (new items are drafts). 005's `status` input is ignored.
