# nextcloud_upload

A minimal Dart package for uploading files to Nextcloud and creating shares. Stripped of all unrelated sub-systems — just upload and share.

## Features

- Upload files via WebDAV
- Upload progress callback
- Create public link shares, user shares, and group shares
- Retrieve and delete shares
- Download files
- Create and delete directories
- Automatic retry with exponential backoff on rate-limited requests (HTTP 429)
- Basic auth and app password auth

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nextcloud_upload:
    git:
      url: https://github.com/pastordee/nextcloud_upload.git
```

Then run:

```bash
dart pub get
```

## Usage

### Setup

```dart
import 'package:nextcloud_upload/nextcloud_upload.dart';

// Using username and password
final client = NextcloudUploadClient.withCredentials(
  Uri.parse('https://your.nextcloud.com'),
  'username',
  'password',
);

// Using an app password
final client = NextcloudUploadClient.withAppPassword(
  Uri.parse('https://your.nextcloud.com'),
  'username',
  'your-app-password',
);
```

### Upload a file

```dart
final bytes = await File('photo.jpg').readAsBytes();

await client.webDav.upload(
  bytes,
  '/Photos/photo.jpg',
  onUploadProgress: (sent, total) {
    print('${(sent / total * 100).toStringAsFixed(1)}%');
  },
);
```

### Create a public share link

```dart
final share = await client.shares.shareWithPublicLink('/Photos/photo.jpg');

print(share.url);   // https://your.nextcloud.com/s/xxxxxxxxxxxx
print(share.id);    // 347
print(share.token); // xxxxxxxxxxxx
```

### Create a public share with a password

```dart
final share = await client.shares.shareWithPublicLink(
  '/Photos/photo.jpg',
  password: 'secret123',
);
```

### Share with a specific user or group

```dart
final share = await client.shares.shareWithUser(
  '/Photos/photo.jpg',
  'john',
  permissions: Permissions([Permission.read]),
);

final share = await client.shares.shareWithGroup(
  '/Photos/photo.jpg',
  'team',
);
```

### Get and delete shares

```dart
final share = await client.shares.getShare(347);

final shares = await client.shares.getShares(path: '/Photos/photo.jpg');

await client.shares.deleteShare(347);
```

### Directory operations

```dart
// Create a single directory
await client.webDav.mkdir('Photos');

// Create nested directories (like mkdir -p)
await client.webDav.mkdirs('Photos/2024/July');
```

### Download and delete files

```dart
final bytes = await client.webDav.download('/Photos/photo.jpg');

await client.webDav.delete('/Photos/photo.jpg');
```

### Check server capabilities

```dart
final status = await client.webDav.status();
print(status.capabilities); // {1, 2, 3, extended-mkcol, ...}
```

## Permissions

Use the `Permission` constants and `Permissions` class to set share permissions:

```dart
// Read only (default for public links)
Permissions([Permission.read])

// Read and update
Permissions([Permission.read, Permission.update])

// All permissions
Permissions([Permission.all])
```

## Error handling

```dart
try {
  await client.webDav.upload(bytes, '/Photos/photo.jpg');
} on RequestException catch (e) {
  print(e.statusCode); // e.g. 401, 403, 404
  print(e.isRateLimited); // true if HTTP 429
}
```

Rate-limited requests (HTTP 429) are automatically retried up to 3 times with exponential backoff. Server errors (5xx) are also retried.
