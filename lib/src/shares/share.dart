import 'dart:convert';
import 'package:xml/xml.dart' as xml;

import '../xml_utils.dart';

/// Share class
class Share {
  // ignore: public_member_api_docs
  Share({
    required this.id,
    required this.shareType,
    required this.uidOwner,
    required this.displaynameOwner,
    required this.permissions,
    required this.stime,
    required this.parent,
    required this.expiration,
    required this.token,
    required this.uidFileOwner,
    required this.note,
    required this.label,
    required this.displaynameFileOwner,
    required this.path,
    required this.itemType,
    required this.mimeType,
    required this.storageId,
    required this.storage,
    required this.itemSource,
    required this.fileSource,
    required this.fileParent,
    required this.fileTarget,
    required this.shareWith,
    required this.shareWithDisplayName,
    required this.mailSend,
    required this.hideDownload,
    required this.password,
    required this.url,
  });

  /// The share id
  final int id;

  /// Integer defined in [ShareTypes]
  final int shareType;

  // ignore: public_member_api_docs
  final String uidOwner;

  // ignore: public_member_api_docs
  final String displaynameOwner;

  // ignore: public_member_api_docs
  final Permissions permissions;

  // ignore: public_member_api_docs
  final int stime;

  // ignore: public_member_api_docs
  final String parent;

  // ignore: public_member_api_docs
  final DateTime expiration;

  // ignore: public_member_api_docs
  final String token;

  // ignore: public_member_api_docs
  final String uidFileOwner;

  // ignore: public_member_api_docs
  final String note;

  // ignore: public_member_api_docs
  final String label;

  // ignore: public_member_api_docs
  final String displaynameFileOwner;

  // ignore: public_member_api_docs
  final String path;

  // ignore: public_member_api_docs
  final String itemType;

  // ignore: public_member_api_docs
  final String mimeType;

  // ignore: public_member_api_docs
  final String storageId;

  // ignore: public_member_api_docs
  final int storage;

  // ignore: public_member_api_docs
  final int itemSource;

  // ignore: public_member_api_docs
  final int fileSource;

  // ignore: public_member_api_docs
  final int fileParent;

  // ignore: public_member_api_docs
  final String fileTarget;

  // ignore: public_member_api_docs
  final String shareWith;

  // ignore: public_member_api_docs
  final String shareWithDisplayName;

  // ignore: public_member_api_docs
  final int mailSend;

  // ignore: public_member_api_docs
  final int hideDownload;

  /// Password for public link share
  final String password;

  /// Public link URL
  final String url;

  /// Returns true if the shared item is a directory
  bool get isDirectory => itemType == 'folder';

  @override
  String toString() =>
      'Share{path: $path, id: $id, owner: $displaynameOwner, shareWith: $shareWith, permissions: $permissions, url: $url}';
}

/// Share type constants
class ShareTypes {
  /// Share with user
  static const user = 0;

  /// Share with group
  static const group = 1;

  /// Create a public link share
  static const publicLink = 3;

  /// All possible share types
  static const values = [user, group, publicLink];
}

/// Permission bit constants
class Permission {
  /// Read only
  static const read = 1;

  /// Update only
  static const update = 2;

  /// Create only
  static const create = 4;

  /// Delete only
  static const delete = 8;

  /// Share only
  static const share = 16;

  /// All permissions
  static const all = 31;

  /// All possible permission values
  static const values = [all, read, update, create, delete, share];
}

/// Combination of [Permission] values
class Permissions {
  /// Create permissions from a list of [Permission] constants.
  Permissions(List<int> permissions) {
    _permissions = permissions;
  }

  /// Create permissions from the combined permission integer.
  factory Permissions.fromInt(int number) {
    // ignore: omit_local_variable_types
    final List<int> permissions = [];
    // ignore: avoid_function_literals_in_foreach_calls
    Permission.values.reversed.forEach((value) {
      if (number >= value) {
        number -= value;
        permissions.add(value);
      }
    });
    return Permissions(permissions);
  }

  /// Add a permission if not already present.
  void addPermission(int permission) {
    if (!_permissions.contains(permission)) {
      _permissions.add(permission);
    }
  }

  /// Remove a permission if present.
  void removePermission(int permission) {
    if (_permissions.contains(permission)) {
      _permissions.remove(permission);
    }
  }

  /// Returns the combined permissions integer.
  int toInt() {
    var number = 0;
    for (final value in permissions) {
      number += value;
    }
    return number;
  }

  late List<int> _permissions;

  /// Returns the separated permissions as a list.
  List<int> get permissions => _permissions;

  @override
  String toString() => '${toInt()}: $_permissions';
}

/// Converts the shares response (XML or JSON) to a list of share objects
List<Share> sharesFromResponse(String responseStr) {
  final shares = <Share>[];

  responseStr = responseStr.trim();

  if (responseStr.startsWith('{')) {
    final jsonResponse = jsonDecode(responseStr) as Map<String, dynamic>;

    if (!jsonResponse.containsKey('ocs') ||
        !jsonResponse['ocs'].containsKey('data')) {
      throw Exception('Invalid OCS JSON response structure');
    }

    final data = jsonResponse['ocs']['data'];

    if (data is List) {
      for (final shareData in data) {
        shares.add(shareFromJsonData(shareData as Map<String, dynamic>));
      }
    } else if (data is Map<String, dynamic>) {
      shares.add(shareFromJsonData(data));
    }

    return shares;
  }

  final xmlDocument = XmlUtils.safeParseXml(responseStr, context: 'sharesFromResponse');
  for (final response in xmlDocument.findAllElements('element')) {
    shares.add(shareFromShareXml(response));
  }
  return shares;
}

/// Converts the shares response (XML or JSON) to a single share object
Share shareFromResponse(String responseStr) {
  responseStr = responseStr.trim();

  if (responseStr.startsWith('{')) {
    final jsonResponse = jsonDecode(responseStr) as Map<String, dynamic>;

    if (!jsonResponse.containsKey('ocs') ||
        !jsonResponse['ocs'].containsKey('data')) {
      throw Exception('Invalid OCS JSON response structure');
    }

    final data = jsonResponse['ocs']['data'] as Map<String, dynamic>;
    return shareFromJsonData(data);
  }

  final xmlDocument = XmlUtils.safeParseXml(responseStr, context: 'shareFromResponse');
  final response = XmlUtils.findSingleElement(xmlDocument, 'data', context: 'shareFromResponse');
  return shareFromShareXml(response);
}

/// Converts a share XML element to a share object
Share shareFromShareXml(xml.XmlElement element) {
  final id = int.parse(element.findAllElements('id').single.innerText);
  final shareType = int.parse(element.findAllElements('share_type').single.innerText);
  final stime = int.parse(element.findAllElements('stime').single.innerText);
  final uidOwner = element.findAllElements('uid_owner').single.innerText;
  final displaynameOwner = element.findAllElements('displayname_owner').single.innerText;
  final parent = element.findAllElements('parent').single.innerText;
  final expiration = DateTime.parse(element.findAllElements('expiration').single.innerText);
  final token = element.findAllElements('token').single.innerText;
  final uidFileOwner = element.findAllElements('uid_file_owner').single.innerText;
  final note = element.findAllElements('note').single.innerText;
  final label = element.findAllElements('label').single.innerText;
  final displaynameFileOwner = element.findAllElements('displayname_file_owner').single.innerText;
  final path = element.findAllElements('path').single.innerText;
  final itemType = element.findAllElements('item_type').single.innerText;
  final mimeType = element.findAllElements('mimetype').single.innerText;
  final storageId = element.findAllElements('storage_id').single.innerText;
  final storage = int.parse(element.findAllElements('storage').single.innerText);
  final itemSource = int.parse(element.findAllElements('item_source').single.innerText);
  final fileSource = int.parse(element.findAllElements('file_source').single.innerText);
  final fileParent = int.parse(element.findAllElements('file_parent').single.innerText);
  final fileTarget = element.findAllElements('file_target').single.innerText;
  final shareWith = element.findAllElements('share_with').single.innerText;
  final shareWithDisplayName = element.findAllElements('share_with_displayname').single.innerText;
  final mailSend = int.parse(element.findAllElements('mail_send').single.innerText);
  final hideDownload = int.parse(element.findAllElements('hide_download').single.innerText);
  final password = element.findAllElements('password').toList()[0].innerText;
  final url = element.findAllElements('url').toList()[0].innerText;
  final permissionsNumber = int.parse(element.findAllElements('permissions').single.innerText);
  final permissions = Permissions.fromInt(permissionsNumber);

  return Share(
    id: id,
    shareType: shareType,
    uidOwner: uidOwner,
    displaynameOwner: displaynameOwner,
    permissions: permissions,
    stime: stime,
    parent: parent,
    expiration: expiration,
    token: token,
    uidFileOwner: uidFileOwner,
    note: note,
    label: label,
    displaynameFileOwner: displaynameFileOwner,
    path: path,
    itemType: itemType,
    mimeType: mimeType,
    storageId: storageId,
    storage: storage,
    itemSource: itemSource,
    fileSource: fileSource,
    fileParent: fileParent,
    fileTarget: fileTarget,
    shareWith: shareWith,
    shareWithDisplayName: shareWithDisplayName,
    mailSend: mailSend,
    hideDownload: hideDownload,
    password: password,
    url: url,
  );
}

/// Converts a share JSON data map to a share object
Share shareFromJsonData(Map<String, dynamic> data) {
  final id = int.parse(data['id'].toString());
  final shareType = int.parse(data['share_type'].toString());
  final stime = int.parse(data['stime'].toString());
  final uidOwner = data['uid_owner']?.toString() ?? '';
  final displaynameOwner = data['displayname_owner']?.toString() ?? '';
  final parent = data['parent']?.toString() ?? '';

  DateTime expiration;
  if (data['expiration'] != null && data['expiration'].toString().isNotEmpty) {
    try {
      expiration = DateTime.parse(data['expiration'].toString());
    } catch (e) {
      expiration = DateTime(2099, 12, 31);
    }
  } else {
    expiration = DateTime(2099, 12, 31);
  }

  final token = data['token']?.toString() ?? '';
  final uidFileOwner = data['uid_file_owner']?.toString() ?? '';
  final note = data['note']?.toString() ?? '';
  final label = data['label']?.toString() ?? '';
  final displaynameFileOwner = data['displayname_file_owner']?.toString() ?? '';
  final path = data['path']?.toString() ?? '';
  final itemType = data['item_type']?.toString() ?? '';
  final mimeType = data['mimetype']?.toString() ?? '';
  final storageId = data['storage_id']?.toString() ?? '';
  final storage = int.parse(data['storage']?.toString() ?? '0');
  final itemSource = int.parse(data['item_source']?.toString() ?? '0');
  final fileSource = int.parse(data['file_source']?.toString() ?? '0');
  final fileParent = int.parse(data['file_parent']?.toString() ?? '0');
  final fileTarget = data['file_target']?.toString() ?? '';
  final shareWith = data['share_with']?.toString() ?? '';
  final shareWithDisplayName = data['share_with_displayname']?.toString() ?? '';
  final mailSend = int.parse(data['mail_send']?.toString() ?? '0');
  final hideDownload = int.parse(data['hide_download']?.toString() ?? '0');
  final password = data['password']?.toString() ?? '';
  final url = data['url']?.toString() ?? '';
  final permissionsNumber = int.parse(data['permissions']?.toString() ?? '0');
  final permissions = Permissions.fromInt(permissionsNumber);

  return Share(
    id: id,
    shareType: shareType,
    uidOwner: uidOwner,
    displaynameOwner: displaynameOwner,
    permissions: permissions,
    stime: stime,
    parent: parent,
    expiration: expiration,
    token: token,
    uidFileOwner: uidFileOwner,
    note: note,
    label: label,
    displaynameFileOwner: displaynameFileOwner,
    path: path,
    itemType: itemType,
    mimeType: mimeType,
    storageId: storageId,
    storage: storage,
    itemSource: itemSource,
    fileSource: fileSource,
    fileParent: fileParent,
    fileTarget: fileTarget,
    shareWith: shareWith,
    shareWithDisplayName: shareWithDisplayName,
    mailSend: mailSend,
    hideDownload: hideDownload,
    password: password,
    url: url,
  );
}
