import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:nest/l10n/app_localizations.dart';

class DateUtilsFormatter {
  static String formatDynamicDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return DateFormat.Hm(l10n.localeName).format(date);
    } else if (dateToCompare == yesterday) {
      return l10n.yesterday;
    } else if (now.difference(dateToCompare).inDays < 7 && now.isAfter(dateToCompare)) {
      return DateFormat.E(l10n.localeName).format(date);
    } else if (date.year == now.year) {
      return DateFormat.MMMd(l10n.localeName).format(date);
    } else {
      return DateFormat.yMd(l10n.localeName).format(date);
    }
  }
}
