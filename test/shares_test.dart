import 'package:test/test.dart';
import 'package:nextcloud_upload/nextcloud_upload.dart';

void main() {
  group('Share JSON parsing', () {
    test('parse real public link share response', () {
      const jsonResponse =
          '{"ocs":{"meta":{"status":"ok","statuscode":200,"message":"OK"},"data":{"id":"347","share_type":3,"uid_owner":"admin","displayname_owner":"admin","permissions":17,"can_edit":true,"can_delete":true,"stime":1755053653,"parent":null,"expiration":null,"token":"2y4PiHbztDFweFL","uid_file_owner":"admin","note":"","label":"","displayname_file_owner":"admin","path":"/Users/Fsq01ZeMcq/profile_pics/1755053644605_avatar.jpg","item_type":"file","item_permissions":27,"is-mount-root":false,"mount-type":"","mimetype":"image/jpeg","has_preview":true,"storage_id":"home::admin","storage":1,"item_source":19064,"file_source":19064,"file_parent":18987,"file_target":"/1755053644605_avatar.jpg","item_size":4325675,"item_mtime":1755053652,"share_with":null,"share_with_displayname":"(Shared link)","password":null,"send_password_by_talk":false,"url":"https://files.prayercircle.co.uk/s/2y4PiHbztDFweFL","mail_send":1,"hide_download":0,"attributes":null}}}';

      final share = shareFromResponse(jsonResponse);

      expect(share.id, equals(347));
      expect(share.shareType, equals(ShareTypes.publicLink));
      expect(share.uidOwner, equals('admin'));
      expect(share.token, equals('2y4PiHbztDFweFL'));
      expect(share.url, equals('https://files.prayercircle.co.uk/s/2y4PiHbztDFweFL'));
      expect(share.mimeType, equals('image/jpeg'));
      expect(share.expiration.year, equals(2099));
    });

    test('parse response with explicit expiration date', () {
      const json =
          '{"ocs":{"meta":{"status":"ok","statuscode":200,"message":"OK"},"data":{"id":"123","share_type":3,"uid_owner":"admin","displayname_owner":"admin","permissions":17,"stime":1755053653,"parent":"","expiration":"2024-12-31T23:59:59Z","token":"testtoken","uid_file_owner":"admin","note":"","label":"","displayname_file_owner":"admin","path":"/test.jpg","item_type":"file","mimetype":"image/jpeg","storage_id":"home::admin","storage":1,"item_source":123,"file_source":123,"file_parent":0,"file_target":"/test.jpg","share_with":"","share_with_displayname":"(Shared link)","password":"","url":"https://example.com/s/testtoken","mail_send":0,"hide_download":0}}}';

      final share = shareFromResponse(json);

      expect(share.expiration.year, equals(2024));
      expect(share.expiration.month, equals(12));
      expect(share.expiration.day, equals(31));
    });

    test('parse list of shares', () {
      const json =
          '{"ocs":{"meta":{"status":"ok","statuscode":200,"message":"OK"},"data":[{"id":"123","share_type":3,"uid_owner":"admin","displayname_owner":"admin","permissions":17,"stime":1755053653,"parent":"","expiration":null,"token":"token1","uid_file_owner":"admin","note":"","label":"","displayname_file_owner":"admin","path":"/test1.jpg","item_type":"file","mimetype":"image/jpeg","storage_id":"home::admin","storage":1,"item_source":123,"file_source":123,"file_parent":0,"file_target":"/test1.jpg","share_with":"","share_with_displayname":"(Shared link)","password":"","url":"https://example.com/s/token1","mail_send":0,"hide_download":0},{"id":"124","share_type":3,"uid_owner":"admin","displayname_owner":"admin","permissions":17,"stime":1755053654,"parent":"","expiration":null,"token":"token2","uid_file_owner":"admin","note":"","label":"","displayname_file_owner":"admin","path":"/test2.jpg","item_type":"file","mimetype":"image/jpeg","storage_id":"home::admin","storage":1,"item_source":124,"file_source":124,"file_parent":0,"file_target":"/test2.jpg","share_with":"","share_with_displayname":"(Shared link)","password":"","url":"https://example.com/s/token2","mail_send":0,"hide_download":0}]}}';

      final shares = sharesFromResponse(json);

      expect(shares.length, equals(2));
      expect(shares[0].id, equals(123));
      expect(shares[0].token, equals('token1'));
      expect(shares[1].id, equals(124));
      expect(shares[1].token, equals('token2'));
    });

    test('parse XML share response', () {
      const xmlResponse = '''<?xml version="1.0"?>
<ocs>
  <meta>
    <status>ok</status>
    <statuscode>200</statuscode>
    <message>OK</message>
  </meta>
  <data>
    <id>123</id>
    <share_type>3</share_type>
    <uid_owner>admin</uid_owner>
    <displayname_owner>admin</displayname_owner>
    <permissions>17</permissions>
    <stime>1755053653</stime>
    <parent></parent>
    <expiration>2024-12-31T23:59:59Z</expiration>
    <token>testtoken</token>
    <uid_file_owner>admin</uid_file_owner>
    <note></note>
    <label></label>
    <displayname_file_owner>admin</displayname_file_owner>
    <path>/test.jpg</path>
    <item_type>file</item_type>
    <mimetype>image/jpeg</mimetype>
    <storage_id>home::admin</storage_id>
    <storage>1</storage>
    <item_source>123</item_source>
    <file_source>123</file_source>
    <file_parent>0</file_parent>
    <file_target>/test.jpg</file_target>
    <share_with></share_with>
    <share_with_displayname>(Shared link)</share_with_displayname>
    <password></password>
    <url>https://example.com/s/testtoken</url>
    <mail_send>0</mail_send>
    <hide_download>0</hide_download>
  </data>
</ocs>''';

      final share = shareFromResponse(xmlResponse);

      expect(share.id, equals(123));
      expect(share.token, equals('testtoken'));
    });
  });

  group('Permissions', () {
    test('fromInt round-trips correctly', () {
      final perms = Permissions.fromInt(Permission.read | Permission.update);
      expect(perms.permissions, containsAll([Permission.read, Permission.update]));
    });

    test('toInt produces correct combined value', () {
      final perms = Permissions([Permission.read, Permission.update]);
      expect(perms.toInt(), equals(Permission.read + Permission.update));
    });
  });
}
