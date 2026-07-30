import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AppIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;

  const AppIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox.shrink();

    final hugeIcon = _mapToHugeIcon(icon!);
    if (hugeIcon != null) {
      return HugeIcon(icon: hugeIcon, size: size ?? 24.0, color: color);
    }

    return Icon(icon, size: size, color: color);
  }

  static List<List<dynamic>>? _mapToHugeIcon(IconData icon) {
    if (icon == Icons.medical_services_rounded) return HugeIcons.strokeRoundedAmbulance;
    if (icon == Icons.person_outline_rounded) return HugeIcons.strokeRoundedUser;
    if (icon == Icons.history_rounded) return HugeIcons.strokeRoundedClock01;
    if (icon == Icons.camera_alt) return HugeIcons.strokeRoundedCamera01;
    if (icon == Icons.mic_rounded) return HugeIcons.strokeRoundedMic01;
    if (icon == Icons.stop_rounded) return HugeIcons.strokeRoundedStop;
    if (icon == Icons.arrow_forward_rounded) return HugeIcons.strokeRoundedArrowRight01;
    if (icon == Icons.arrow_back_ios_new_rounded) return HugeIcons.strokeRoundedArrowLeft01;
    if (icon == Icons.close_rounded) return HugeIcons.strokeRoundedCancel01;
    if (icon == Icons.check_rounded) return HugeIcons.strokeRoundedCheckmarkCircle01;
    if (icon == Icons.check_circle_outline) return HugeIcons.strokeRoundedCheckmarkCircle01;
    if (icon == Icons.share_outlined) return HugeIcons.strokeRoundedShare01;
    if (icon == Icons.psychology_outlined) return HugeIcons.strokeRoundedBrain;
    if (icon == Icons.warning_amber_rounded) return HugeIcons.strokeRoundedAlertCircle;
    if (icon == Icons.local_hospital_rounded) return HugeIcons.strokeRoundedHospital01;
    if (icon == Icons.info_outline_rounded || icon == Icons.info_outline) return HugeIcons.strokeRoundedInformationCircle;
    if (icon == Icons.article_outlined) return HugeIcons.strokeRoundedDocumentCode;
    if (icon == Icons.description_outlined) return HugeIcons.strokeRoundedDocumentCode;
    if (icon == Icons.bloodtype_rounded || icon == Icons.bloodtype_outlined) return HugeIcons.strokeRoundedBloodType;
    if (icon == Icons.cake_outlined) return HugeIcons.strokeRoundedBirthdayCake;
    if (icon == Icons.medication_rounded) return HugeIcons.strokeRoundedPill;
    if (icon == Icons.contact_phone_outlined || icon == Icons.phone_outlined || icon == Icons.call_rounded) return HugeIcons.strokeRoundedCall;
    if (icon == Icons.location_on_outlined) return HugeIcons.strokeRoundedLocation01;
    if (icon == Icons.notes_rounded) return HugeIcons.strokeRoundedNote01;
    if (icon == Icons.edit_outlined) return HugeIcons.strokeRoundedNote02;
    if (icon == Icons.add_rounded) return HugeIcons.strokeRoundedAdd01;
    if (icon == Icons.home_rounded) return HugeIcons.strokeRoundedHome01;
    if (icon == Icons.map_outlined) return HugeIcons.strokeRoundedMapPin;
    if (icon == Icons.sick_rounded) return HugeIcons.strokeRoundedHospital01;
    if (icon == Icons.local_fire_department_rounded) return HugeIcons.strokeRoundedFire;
    if (icon == Icons.wifi_off_rounded) return HugeIcons.strokeRoundedWifiOff01;
    if (icon == Icons.lock_outline_rounded) return HugeIcons.strokeRoundedLock;
    if (icon == Icons.check_circle_outline_rounded) return HugeIcons.strokeRoundedCheckmarkCircle01;
    if (icon == Icons.do_not_disturb_rounded) return HugeIcons.strokeRoundedCancel01;
    if (icon == Icons.visibility_rounded) return HugeIcons.strokeRoundedEye;
    if (icon == Icons.checklist_rounded) return HugeIcons.strokeRoundedCheckList;
    if (icon == Icons.question_answer_rounded) return HugeIcons.strokeRoundedQuestion;
    if (icon == Icons.report_outlined) return HugeIcons.strokeRoundedDocumentCode;
    if (icon == Icons.photo_library_outlined) return HugeIcons.strokeRoundedCamera01;
    if (icon == Icons.warning_rounded) return HugeIcons.strokeRoundedAlert02;
    if (icon == Icons.cloud_download_outlined) return HugeIcons.strokeRoundedDownload01;
    if (icon == Icons.chevron_right_rounded) return HugeIcons.strokeRoundedArrowRight04;
    if (icon == Icons.location_off_outlined) return HugeIcons.strokeRoundedLocation02;
    if (icon == Icons.local_pharmacy_rounded) return HugeIcons.strokeRoundedMedicine01;
    if (icon == Icons.access_time_rounded) return HugeIcons.strokeRoundedClock02;
    if (icon == Icons.help_outline_rounded) return HugeIcons.strokeRoundedHelpCircle;
    if (icon == Icons.send_rounded) return HugeIcons.strokeRoundedArrowRight01;
    if (icon == Icons.favorite_rounded) return HugeIcons.strokeRoundedHeartAdd;
    if (icon == Icons.error_outline_rounded) return HugeIcons.strokeRoundedAlertSquare;
    if (icon == Icons.accessible_rounded) return HugeIcons.strokeRoundedStethoscope;
    if (icon == Icons.air_rounded) return HugeIcons.strokeRoundedFire;
    return null;
  }
}
