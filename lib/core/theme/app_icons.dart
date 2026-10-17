import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/app_platform.dart';

/// Ícones adaptativos: Material Icons na web/Android, CupertinoIcons no iOS.
abstract final class AppIcons {
  static bool get _ios => AppPlatform.instance.useCupertino;

  static IconData get business => _ios ? CupertinoIcons.building_2_fill : Icons.business;
  static IconData get email => _ios ? CupertinoIcons.mail : Icons.email_outlined;
  static IconData get idCard =>
      _ios ? CupertinoIcons.person_crop_rectangle : Icons.badge_outlined;
  static IconData get lock => _ios ? CupertinoIcons.lock : Icons.lock_outline;
  static IconData get visible => _ios ? CupertinoIcons.eye : Icons.visibility_outlined;
  static IconData get hidden => _ios ? CupertinoIcons.eye_slash : Icons.visibility_off_outlined;
  static IconData get upload => _ios ? CupertinoIcons.cloud_upload : Icons.upload_file;
  static IconData get document => _ios ? CupertinoIcons.doc_text : Icons.description_outlined;
  static IconData get back => _ios ? CupertinoIcons.back : Icons.arrow_back_ios_new;
  static IconData get at => _ios ? CupertinoIcons.at : Icons.alternate_email;
  static IconData get calendar => _ios ? CupertinoIcons.calendar : Icons.calendar_today_outlined;
  static IconData get chevronDown => _ios ? CupertinoIcons.chevron_down : Icons.expand_more;
  static IconData get location => _ios ? CupertinoIcons.location : Icons.location_on_outlined;
  static IconData get logout => _ios ? CupertinoIcons.square_arrow_right : Icons.logout;
}
