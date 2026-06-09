# Remove background compression and simplify video handling

## Goal Description
The user wants to abandon all video compression logic because it causes many problems. We need to:
- Remove the async compression dispatch from the upload endpoint.
- Delete the `compressVideoWithExec` helper method.
- Simplify the `getVideoUrlAttribute` accessor to return only the original uploaded video path (ignore `processed_path`).
- Update the controller methods (`upload`, `index`, `trending`, `show`, `myVideos`) to rely on the model's `$appends` (`video_url`, `thumbnail_url`) instead of manually adding those fields.
- Ensure pagination responses include the appended attributes automatically.

## Open Questions
> [!IMPORTANT]
> None – the changes are straightforward.

## Proposed Changes
---
### Video Model (`app/Models/Video.php`)
- Update `getVideoUrlAttribute` to return the original video path only.
- Keep `$appends = ['video_url', 'thumbnail_url'];`.

---
### Video Controller (`app/Http/Controllers/VideoController.php`)
- **Upload**: Remove `$this->dispatchBackgroundCompression($video->id);` and any related code.
- **Compress helper**: Delete the entire `compressVideoWithExec` method.
- **Index / Trending / Show / MyVideos**: Remove manual `$video->video_url = ...` assignments and `through`/`map` calls; rely on model appends.
- Return pagination objects directly (they already include appended attributes).

---
### Routes
- No route changes required.

## Verification Plan
- Run `php artisan test` (if tests exist) to ensure no syntax errors.
- Use a tool like Postman to call `/videos/upload` and verify the response includes `video_url` and `thumbnail_url`.
- Call `/videos`, `/videos/trending`, `/videos/my` and ensure each video object contains the URLs.
- Attempt to stream a video via `/videos/{id}/stream` to confirm the file is served correctly.
