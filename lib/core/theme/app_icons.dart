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
  static IconData get pdf => _ios ? CupertinoIcons.doc_richtext : Icons.picture_as_pdf_outlined;
  static IconData get chevronRight => _ios ? CupertinoIcons.chevron_right : Icons.chevron_right;
  static IconData get chevronDown => _ios ? CupertinoIcons.chevron_down : Icons.expand_more;
  static IconData get location => _ios ? CupertinoIcons.location : Icons.location_on_outlined;
  static IconData get summary => _ios ? CupertinoIcons.text_alignleft : Icons.notes;
  static IconData get warning =>
      _ios ? CupertinoIcons.exclamationmark_triangle : Icons.warning_amber_rounded;
  static IconData get money => _ios ? CupertinoIcons.money_dollar_circle : Icons.payments_outlined;
  static IconData get checklist => _ios ? CupertinoIcons.checkmark_seal : Icons.fact_check_outlined;
  static IconData get obligations => _ios ? CupertinoIcons.list_bullet : Icons.assignment_outlined;
  static IconData get question => _ios ? CupertinoIcons.lightbulb : Icons.lightbulb_outline;
  static IconData get checkCircle =>
      _ios ? CupertinoIcons.checkmark_circle_fill : Icons.check_circle;
  static IconData get cancelCircle => _ios ? CupertinoIcons.xmark_circle_fill : Icons.cancel;
  static IconData get helpCircle =>
      _ios ? CupertinoIcons.question_circle_fill : Icons.help;
  static IconData get clock => _ios ? CupertinoIcons.clock : Icons.schedule;
  static IconData get handshake => _ios ? CupertinoIcons.person_2 : Icons.handshake_outlined;
  static IconData get logout => _ios ? CupertinoIcons.square_arrow_right : Icons.logout;
}
