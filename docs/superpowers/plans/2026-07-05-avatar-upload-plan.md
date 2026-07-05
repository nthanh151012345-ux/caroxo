# Avatar Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add avatar upload/change support using `file_picker`, Supabase Storage, and a `profiles` table, with avatars shown in Profile and GameSetupScreen.

**Architecture:** Create Supabase resources with a migration: public `avatars` bucket, `profiles` table, and RLS/storage policies. Add a small `ProfileService` for profile fetch/upload/upsert logic, then update ProfileScreen and GameSetupScreen to consume it without touching the in-game UI. Keep storage usage low by overwriting one fixed avatar path per user.

**Tech Stack:** Flutter, Dart, `supabase_flutter`, `file_picker`, Supabase CLI migrations, Supabase Storage, Postgres RLS.

---

## File Structure

- Create: `supabase/migrations/20260705000000_create_profiles_and_avatars.sql`
  - Owns all Supabase database/storage setup for this feature.
- Modify: `pubspec.yaml`
  - Adds `file_picker`.
- Create: `lib/services/profile_service.dart`
  - Owns profile row loading, avatar path derivation, avatar upload, and profile upsert.
- Test: `test/profile_service_test.dart`
  - Covers deterministic avatar path/extension behavior.
- Modify: `lib/screens/profile_screen.dart`
  - Adds avatar header, upload interaction, avatar loading state, and readable Vietnamese copy.
- Modify: `lib/screens/game_setup_screen.dart`
  - Loads profile avatar and displays it in the account header.
- Modify: `test/widget_test.dart`
  - Fixes existing mojibake expectation for login text if Profile/GameSetup copy cleanup changes shared visible strings.
- Test: `test/profile_screen_test.dart`
  - Covers fallback avatar rendering when no URL is present.

---

### Task 1: Supabase Migration For Profiles And Avatars

**Files:**
- Create: `supabase/migrations/20260705000000_create_profiles_and_avatars.sql`

- [ ] **Step 1: Create the migration file**

Add this exact SQL:

```sql
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update
set public = excluded.public;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  avatar_url text,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Avatar images are publicly readable" on storage.objects;
create policy "Avatar images are publicly readable"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can update own avatar" on storage.objects;
create policy "Users can update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete own avatar" on storage.objects;
create policy "Users can delete own avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
```

- [ ] **Step 2: Validate migration syntax locally**

Run:

```powershell
d:\caro1\tools\supabase\supabase.exe db reset
```

Expected: command exits `0`, migrations apply successfully, and the output does not contain SQL errors.

- [ ] **Step 3: Commit migration**

Run:

```powershell
git add supabase\migrations\20260705000000_create_profiles_and_avatars.sql
git commit -m "feat: add avatar storage schema"
```

Expected: one commit containing only the migration.

---

### Task 2: Add File Picker And Profile Service

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/profile_service.dart`
- Test: `test/profile_service_test.dart`

- [ ] **Step 1: Add dependency**

Run:

```powershell
flutter pub add file_picker
```

Expected: command exits `0`, `pubspec.yaml` contains `file_picker` under `dependencies`, and `pubspec.lock` updates with `file_picker`.

- [ ] **Step 2: Write failing service tests**

Create `test/profile_service_test.dart`:

```dart
import 'package:caroxo/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarUploadTarget', () {
    test('uses lower-case supported extension in fixed user path', () {
      final target = AvatarUploadTarget.fromFileName(
        userId: 'user-123',
        fileName: 'My Photo.PNG',
      );

      expect(target.storagePath, 'user-123/avatar.png');
      expect(target.contentType, 'image/png');
    });

    test('defaults unknown extension to jpg', () {
      final target = AvatarUploadTarget.fromFileName(
        userId: 'user-123',
        fileName: 'avatar.bmp',
      );

      expect(target.storagePath, 'user-123/avatar.jpg');
      expect(target.contentType, 'image/jpeg');
    });

    test('defaults missing extension to jpg', () {
      final target = AvatarUploadTarget.fromFileName(
        userId: 'user-123',
        fileName: 'avatar',
      );

      expect(target.storagePath, 'user-123/avatar.jpg');
      expect(target.contentType, 'image/jpeg');
    });
  });
}
```

- [ ] **Step 3: Run tests and verify they fail**

Run:

```powershell
flutter test test\profile_service_test.dart
```

Expected: FAIL because `lib/services/profile_service.dart` does not exist.

- [ ] **Step 4: Implement profile service**

Create `lib/services/profile_service.dart`:

```dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class AvatarUploadTarget {
  final String storagePath;
  final String contentType;

  const AvatarUploadTarget({
    required this.storagePath,
    required this.contentType,
  });

  factory AvatarUploadTarget.fromFileName({
    required String userId,
    required String fileName,
  }) {
    final extension = _normalizedExtension(fileName);
    return AvatarUploadTarget(
      storagePath: '$userId/avatar.$extension',
      contentType: _contentTypeForExtension(extension),
    );
  }

  static String _normalizedExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final raw = dotIndex == -1 ? '' : fileName.substring(dotIndex + 1);
    final extension = raw.toLowerCase().trim();
    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp' ||
        extension == 'gif') {
      return extension == 'jpeg' ? 'jpg' : extension;
    }
    return 'jpg';
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}

class ProfileService {
  static const String avatarBucket = 'avatars';

  SupabaseClient get _client {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Supabase chưa được cấu hình.');
    }
    return client;
  }

  Future<String?> fetchAvatarUrl() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final row = await _client
        .from('profiles')
        .select('avatar_url')
        .eq('user_id', user.id)
        .maybeSingle();

    return row?['avatar_url'] as String?;
  }

  Future<String> uploadAvatar(PlatformFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập để cập nhật ảnh đại diện.');
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Không thể đọc tệp ảnh đã chọn.');
    }

    final target = AvatarUploadTarget.fromFileName(
      userId: user.id,
      fileName: file.name,
    );

    await _client.storage.from(avatarBucket).uploadBinary(
          target.storagePath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: target.contentType,
            upsert: true,
          ),
        );

    final avatarUrl = _client.storage
        .from(avatarBucket)
        .getPublicUrl(target.storagePath);

    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': user.email,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    return avatarUrl;
  }
}
```

- [ ] **Step 5: Run service tests**

Run:

```powershell
flutter test test\profile_service_test.dart
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit service work**

Run:

```powershell
git add pubspec.yaml pubspec.lock lib\services\profile_service.dart test\profile_service_test.dart
git commit -m "feat: add profile avatar service"
```

Expected: one commit with dependency, service, and tests.

---

### Task 3: Add Avatar Upload UI To ProfileScreen

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Test: `test/profile_screen_test.dart`

- [ ] **Step 1: Write fallback avatar widget test**

Create `test/profile_screen_test.dart`:

```dart
import 'package:caroxo/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Profile screen shows avatar fallback initial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          userEmail: 'avatar@example.com',
          onSignOut: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('profile_avatar_button')), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Đổi ảnh đại diện'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```powershell
flutter test test\profile_screen_test.dart
```

Expected: FAIL because `profile_avatar_button` and avatar copy do not exist yet.

- [ ] **Step 3: Update ProfileScreen imports and state**

In `lib/screens/profile_screen.dart`, add imports:

```dart
import 'package:file_picker/file_picker.dart';
import '../services/profile_service.dart';
```

Add fields inside `_ProfileScreenState`:

```dart
final _profileService = ProfileService();
String? _avatarUrl;
bool _isAvatarLoading = false;
String? _avatarMessage;
```

Add `initState`:

```dart
@override
void initState() {
  super.initState();
  _loadAvatar();
}
```

- [ ] **Step 4: Add avatar loading and upload methods**

Add these methods inside `_ProfileScreenState`:

```dart
String get _avatarInitial {
  final email = widget.userEmail.trim();
  return email.isEmpty ? 'P' : email[0].toUpperCase();
}

Future<void> _loadAvatar() async {
  try {
    final avatarUrl = await _profileService.fetchAvatarUrl();
    if (!mounted) return;
    setState(() {
      _avatarUrl = avatarUrl;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _avatarUrl = null;
    });
  }
}

Future<void> _pickAndUploadAvatar() async {
  if (_isAvatarLoading) {
    return;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    allowMultiple: false,
    withData: true,
  );

  final file = result?.files.single;
  if (file == null) {
    return;
  }

  setState(() {
    _isAvatarLoading = true;
    _avatarMessage = 'Đang tải ảnh lên...';
    _errorMessage = null;
  });

  try {
    final avatarUrl = await _profileService.uploadAvatar(file);
    if (!mounted) return;
    setState(() {
      _avatarUrl = avatarUrl;
      _avatarMessage = 'Đã cập nhật ảnh đại diện.';
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _avatarMessage = 'Không thể cập nhật ảnh đại diện. Vui lòng thử lại.';
      _errorMessage = '$e';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isAvatarLoading = false;
      });
    }
  }
}
```

- [ ] **Step 5: Add avatar header widget**

Add this method inside `_ProfileScreenState`:

```dart
Widget _buildAvatarHeader(ColorScheme colorScheme) {
  return Column(
    children: [
      InkWell(
        key: const ValueKey('profile_avatar_button'),
        onTap: _isAvatarLoading ? null : _pickAndUploadAvatar,
        borderRadius: BorderRadius.circular(56),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              backgroundImage: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? null
                  : NetworkImage(_avatarUrl!),
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Text(
                      _avatarInitial,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isAvatarLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: _isAvatarLoading ? null : _pickAndUploadAvatar,
        icon: const Icon(Icons.upload_rounded),
        label: const Text('Đổi ảnh đại diện'),
      ),
      if (_avatarMessage != null) ...[
        const SizedBox(height: 4),
        Text(
          _avatarMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _avatarMessage == 'Đã cập nhật ảnh đại diện.'
                ? Colors.green
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      const SizedBox(height: 18),
    ],
  );
}
```

- [ ] **Step 6: Insert avatar header above password card and fix visible mojibake**

In the `Column` inside `Form`, insert before the password card:

```dart
_buildAvatarHeader(colorScheme),
```

Replace corrupted Vietnamese strings in `ProfileScreen` with readable copy:

```dart
'Mật khẩu mới phải khác mật khẩu hiện tại.'
'Mật khẩu hiện tại không chính xác.'
'Mật khẩu mới không đáp ứng yêu cầu độ mạnh mật khẩu của hệ thống.'
'Đã xảy ra lỗi: $e'
'HỒ SƠ CÁ NHÂN'
'THAY ĐỔI MẬT KHẨU'
'Mật khẩu hiện tại'
'Hiện mật khẩu'
'Ẩn mật khẩu'
'Vui lòng nhập mật khẩu hiện tại.'
'Mật khẩu mới'
'Vui lòng nhập mật khẩu mới.'
'Mật khẩu mới phải có tối thiểu 6 ký tự.'
'Xác nhận mật khẩu mới'
'Vui lòng xác nhận mật khẩu mới.'
'Mật khẩu xác nhận không khớp.'
'XÁC NHẬN ĐỔI MẬT KHẨU'
'Thành công'
'Mật khẩu của bạn đã được cập nhật thành công. Ứng dụng sẽ đăng xuất để bạn đăng nhập lại bằng mật khẩu mới.'
'Đồng ý'
```

- [ ] **Step 7: Run profile test**

Run:

```powershell
flutter test test\profile_screen_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit ProfileScreen work**

Run:

```powershell
git add lib\screens\profile_screen.dart test\profile_screen_test.dart
git commit -m "feat: add avatar upload to profile"
```

Expected: one commit with ProfileScreen avatar UI and test.

---

### Task 4: Show Avatar In GameSetupScreen

**Files:**
- Modify: `lib/screens/game_setup_screen.dart`

- [ ] **Step 1: Add imports and state**

Add import:

```dart
import '../services/profile_service.dart';
```

Add fields in `_GameSetupScreenState`:

```dart
final _profileService = ProfileService();
String? _avatarUrl;
```

Add `initState`:

```dart
@override
void initState() {
  super.initState();
  _loadAvatar();
}
```

- [ ] **Step 2: Add profile avatar loading**

Add method:

```dart
Future<void> _loadAvatar() async {
  if (widget.userEmail == null) {
    return;
  }

  try {
    final avatarUrl = await _profileService.fetchAvatarUrl();
    if (!mounted) return;
    setState(() {
      _avatarUrl = avatarUrl;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _avatarUrl = null;
    });
  }
}
```

- [ ] **Step 3: Refresh avatar after returning from ProfileScreen**

Replace the current `Navigator.push` inside the email/profile `GestureDetector` with:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileScreen(
      userEmail: widget.userEmail!,
      onSignOut: widget.onSignOut!,
    ),
  ),
).then((_) => _loadAvatar());
```

- [ ] **Step 4: Add a small account avatar widget**

Add method:

```dart
Widget _buildAccountAvatar() {
  final email = widget.userEmail ?? '';
  final initial = email.isEmpty ? 'P' : email[0].toUpperCase();

  return CircleAvatar(
    radius: 16,
    backgroundColor: Colors.white.withValues(alpha: 0.2),
    backgroundImage:
        _avatarUrl == null || _avatarUrl!.isEmpty ? null : NetworkImage(_avatarUrl!),
    child: _avatarUrl == null || _avatarUrl!.isEmpty
        ? Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          )
        : null,
  );
}
```

- [ ] **Step 5: Display avatar in the header**

Inside the `Row` that currently starts with `Icons.manage_accounts_rounded`, replace that icon with:

```dart
_buildAccountAvatar(),
```

Keep the email text and sign-out button unchanged.

- [ ] **Step 6: Fix nearby visible mojibake in GameSetupScreen header only**

Replace corrupted header/account strings touched in this task:

```dart
'CỜ CARO XO'
'Thiết lập trận đấu mới'
'Đăng xuất'
```

Do not refactor the entire setup screen in this task.

- [ ] **Step 7: Run existing layout tests**

Run:

```powershell
flutter test test\widget_test.dart test\in_game_layout_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit GameSetupScreen work**

Run:

```powershell
git add lib\screens\game_setup_screen.dart test\widget_test.dart
git commit -m "feat: show avatar on game setup"
```

Expected: one commit with GameSetupScreen avatar display.

---

### Task 5: Apply Remote Supabase Resources And Verify

**Files:**
- No source files unless verification reveals a fix is needed.

- [ ] **Step 1: Check Supabase project link**

Run:

```powershell
d:\caro1\tools\supabase\supabase.exe status
```

Expected: command exits `0` for local status, or reports local services are stopped without authentication errors.

- [ ] **Step 2: Push migration to linked remote project**

Run:

```powershell
d:\caro1\tools\supabase\supabase.exe db push
```

Expected: command exits `0` and applies `20260705000000_create_profiles_and_avatars.sql` to the linked project.

- [ ] **Step 3: Run full Flutter verification**

Run:

```powershell
flutter analyze
flutter test
```

Expected:

- `flutter analyze`: `No issues found!`
- `flutter test`: all tests pass.

- [ ] **Step 4: Manual app verification**

Run the app using the existing project workflow. For Flutter web:

```powershell
flutter run -d chrome
```

Expected manual checks:

- Login with a Supabase user.
- Open Profile from GameSetupScreen.
- Avatar fallback initial appears.
- Click avatar or `Đổi ảnh đại diện`.
- Pick a `jpg`, `png`, `webp`, or `gif`.
- Upload completes and Profile avatar changes.
- Return to GameSetupScreen.
- Header avatar shows the uploaded image.
- Password-change form still validates and works as before.

- [ ] **Step 5: Stop on verification failure**

If Step 3 or Step 4 fails, stop execution and debug the failure before pushing. Do not push code with failing analyzer, failing tests, failed Supabase migration, or failed manual avatar upload.

Expected: no extra commit is needed when verification passes without fixes.

- [ ] **Step 6: Push branch**

Run:

```powershell
git status --short --branch
git push origin master
```

Expected: `master` pushes successfully to GitHub.

---

## Self-Review Notes

- Spec coverage: migration covers bucket/table/RLS/storage policies; service covers fixed path, upload, public URL, profile upsert; ProfileScreen covers click-to-upload; GameSetupScreen covers avatar display; verification covers Supabase CLI and Flutter tests.
- Scope check: in-game avatars, image cropping/compression, private buckets, and file-size validation are intentionally excluded.
- Type consistency: `AvatarUploadTarget`, `ProfileService.fetchAvatarUrl`, and `ProfileService.uploadAvatar` are defined before UI tasks use them.
