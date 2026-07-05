# Avatar Upload Design

## Goal

Add a simple avatar upload/change feature to the existing Profile screen. Users can click their avatar, pick an image with `file_picker`, upload it to Supabase Storage, and see the updated avatar in Profile and the game setup screen.

The feature should stay small and friendly to Supabase free-tier usage:

- Use one public Storage bucket named `avatars`.
- Store one current avatar per user at a fixed path.
- Store profile data in a `profiles` table.
- Do not add file-size limits in the app.
- Do not add image transformation, paid Supabase features, or background cleanup jobs.

## Decisions

- Avatar visibility: show in Profile and GameSetupScreen only.
- File picker: use `file_picker`.
- Storage: public Supabase Storage bucket.
- File path strategy: overwrite a fixed path per user with `upsert: true`.
- Profile storage: use a `profiles` table, not only `auth.user_metadata`.
- In-game player bars are out of scope for this first version.

## Supabase Resources

Create a migration using Supabase CLI. The migration should create:

### Storage Bucket

- Bucket id: `avatars`
- Public: `true`
- Purpose: store user avatar images.

The app will upload files under a user-owned folder:

```text
{user_id}/avatar.{extension}
```

Examples:

```text
9a9b.../avatar.jpg
9a9b.../avatar.png
```

Keeping one path per user minimizes storage growth and keeps the feature within free-tier expectations.

### Profiles Table

Table: `public.profiles`

Columns:

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `email text`
- `avatar_url text`
- `updated_at timestamptz not null default now()`

RLS should be enabled.

Policies:

- A user can select their own profile row.
- A user can insert their own profile row.
- A user can update their own profile row.

The table is intentionally minimal. It leaves room for later fields such as display name, stats, or bio without expanding this feature now.

### Storage Policies

For the public `avatars` bucket:

- Anyone can read avatar files through public URLs.
- Authenticated users can insert/update files only inside their own folder.
- Authenticated users can delete files only inside their own folder.

The policy should validate the first folder segment against `auth.uid()`.

## Flutter Architecture

### Dependencies

Add `file_picker` to `pubspec.yaml`.

### ProfileScreen

Add an avatar header above the password-change card:

- Shows current avatar from `profiles.avatar_url` if available.
- Falls back to a circular initial using the user's email.
- Shows a small camera/edit affordance on the avatar.
- Clicking the avatar opens `FilePicker.platform.pickFiles`.
- The picker should allow image file extensions such as `jpg`, `jpeg`, `png`, `webp`, and `gif`.

Upload flow:

1. Read the current Supabase user from `SupabaseConfig.client!.auth.currentUser`.
2. Pick one image file with `file_picker`.
3. Determine an extension from the selected file name.
4. Upload bytes to `avatars/{userId}/avatar.{ext}` with `upsert: true`.
5. Build the public URL with Supabase Storage.
6. Upsert `public.profiles` with `user_id`, `email`, `avatar_url`, and `updated_at`.
7. Update local state so the avatar changes immediately.

Use a dedicated avatar loading state so uploading an avatar does not disable the password form unless necessary.

### GameSetupScreen

Load the current user's profile row when the screen opens:

- If `profiles.avatar_url` exists, display it in the header/profile area.
- If not, keep the existing icon/initial fallback.
- If loading fails, keep the fallback and avoid blocking game setup.

No real-time subscription is needed for this version.

### Shared Helper

Keep the first implementation simple. It is acceptable to place profile/avatar loading in `ProfileScreen` and `GameSetupScreen` directly if the code stays small.

If duplication becomes noticeable, create a small helper such as `ProfileService` with:

- `Future<String?> fetchAvatarUrl()`
- `Future<String> uploadAvatar(PlatformFile file)`

The helper should depend only on `SupabaseConfig.client` and not on Flutter widgets.

## Error Handling

Profile upload errors should be user-visible but non-fatal:

- No file selected: do nothing.
- User not signed in: show a friendly error.
- Unsupported extension or missing bytes: show a friendly error.
- Supabase upload/update failure: show a friendly error and keep the previous avatar.

Because the user requested no file-size limit, the app will not reject large files before upload. Supabase project limits can still reject very large uploads; if that happens, show the Supabase error message in friendly Vietnamese.

## UI Copy

Use Vietnamese copy in ProfileScreen and GameSetupScreen. While editing ProfileScreen, fix existing mojibake strings so the profile UI displays readable Vietnamese text.

Suggested avatar text:

- Tooltip/action: `Đổi ảnh đại diện`
- Uploading: `Đang tải ảnh lên...`
- Success: `Đã cập nhật ảnh đại diện.`
- Failure fallback: `Không thể cập nhật ảnh đại diện. Vui lòng thử lại.`

## Tests

Add focused tests where practical:

- Profile avatar fallback renders when no `avatar_url` exists.
- Game setup uses fallback when profile loading fails or no avatar exists.
- Avatar upload logic can be covered through a service-level test if a helper is introduced.

Manual verification should include:

- Supabase migration applies successfully.
- Logged-in user can upload/change their own avatar.
- Avatar appears on Profile after upload.
- Avatar appears on GameSetupScreen after returning/reopening.
- Another authenticated user cannot overwrite a different user's avatar folder.

## Out of Scope

- Cropping images.
- Compressing images.
- File-size limits.
- Deleting old timestamped avatars, because this design overwrites a fixed path.
- Showing avatars in the in-game bars.
- Admin moderation of public avatars.
- Signed URLs or private buckets.
