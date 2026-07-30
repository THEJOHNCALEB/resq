import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/providers/app_providers.dart';

class GuidancePage extends ConsumerStatefulWidget {
  const GuidancePage({super.key});

  @override
  ConsumerState<GuidancePage> createState() => _GuidancePageState();
}

class _GuidancePageState extends ConsumerState<GuidancePage> {
  String _assessment = '';
  List<String> _actions = [];
  List<String> _avoid = [];
  List<String> _monitor = [];
  String _seekCare = '';
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    final gemma = ref.read(gemmaServiceProvider);
    final response = await gemma.generateGuidance(context: emergency.emergencyDescription);

    if (response.isNotEmpty) {
      try {
        final data = json.decode(_extractJson(response));
        setState(() {
          _assessment = data['assessment'] ?? '';
          _actions = List<String>.from(data['actions'] ?? []);
          _avoid = List<String>.from(data['avoid'] ?? []);
          _monitor = List<String>.from(data['monitor'] ?? []);
          _seekCare = data['seekCare'] ?? '';
        });
        final n = ref.read(currentEmergencyProvider.notifier);
        n.setAiAssessment(_assessment);
        n.setImmediateActions(_actions);
        n.setThingsToAvoid(_avoid);
        n.setMonitor(_monitor);
        n.setWhenToSeekCare(_seekCare);
      } catch (e) {
        debugPrint('[ResQ] Guidance parse error: $e');
        _setGeneric();
      }
    } else {
      _setGeneric();
    }
  }

  void _setGeneric() {
    setState(() {
      _assessment = 'Monitor the situation carefully.';
      _actions = ['Stay calm', 'Ensure scene safety', 'Call for help if available', 'Provide basic first aid'];
      _avoid = ['Do not move the person unless necessary', 'Do not leave them unattended'];
      _monitor = ['Breathing', 'Consciousness', 'Skin colour', 'Any changes'];
      _seekCare = 'Seek medical care if the condition worsens.';
    });
  }

  Future<void> _generateSummary() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    setState(() => _generating = true);

    final gemma = ref.read(gemmaServiceProvider);
    final profile = ref.read(profileProvider).valueOrNull;

    final guidance = 'Assessment: $_assessment\nActions: ${_actions.join(", ")}';
    final summary = await gemma.generateSummary(
      context: emergency.emergencyDescription,
      guidance: guidance,
      profileInfo: profile != null ? '${profile.name}, ${profile.age}, ${profile.bloodGroup}' : null,
    );

    if (summary.isNotEmpty) {
      ref.read(currentEmergencyProvider.notifier).setSummary(summary);
    }

    if (mounted) {
      context.go(AppRouter.summary);
    }
  }

  String _extractJson(String text) {
    text = text.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) return text.substring(start, end + 1);
    return text;
  }

  static const cardColors = [
    Color(0xFF4F9EF8),
    Color(0xFF2CB5A5),
    Color(0xFFFF8C7A),
    Color(0xFFF5B74F),
    Color(0xFF8B7CF6),
  ];

  static const cardIcons = [
    Icons.psychology_outlined,
    Icons.check_circle_outline_rounded,
    Icons.do_not_disturb_rounded,
    Icons.visibility_rounded,
    Icons.local_hospital_rounded,
  ];

  static const cardTitles = [
    'Current Assessment',
    'Immediate Actions',
    'Things To Avoid',
    'Monitor',
    'When To Seek Care',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () { if (context.canPop()) context.pop(); },
                    icon: const AppIcon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('Emergency Guidance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: _buildCards(),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: FilledButton.icon(
          onPressed: _generating ? null : _generateSummary,
          icon: _generating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const AppIcon(Icons.description_outlined, size: 18),
          label: Text(_generating ? 'Generating...' : 'Generate Medical Summary'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ),
    );
  }

  Widget _buildCards() {
    final items = <_CardData>[];

    if (_assessment.isNotEmpty) {
      items.add(_CardData(title: cardTitles[0], icon: cardIcons[0], color: cardColors[0], content: _assessment));
    }
    if (_actions.isNotEmpty) {
      items.add(_CardData(title: cardTitles[1], icon: cardIcons[1], color: cardColors[1], list: _actions, numbered: true));
    }
    if (_avoid.isNotEmpty) {
      items.add(_CardData(title: cardTitles[2], icon: cardIcons[2], color: cardColors[2], list: _avoid, numbered: false));
    }
    if (_monitor.isNotEmpty) {
      items.add(_CardData(title: cardTitles[3], icon: cardIcons[3], color: cardColors[3], list: _monitor, numbered: false));
    }
    if (_seekCare.isNotEmpty) {
      items.add(_CardData(title: cardTitles[4], icon: cardIcons[4], color: cardColors[4], content: _seekCare));
    }

    final leftCards = <Widget>[];
    final rightCards = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final card = _buildCard(items[i], i);
      if (i % 2 == 0) {
        leftCards.add(card);
      } else {
        rightCards.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: _stagger(leftCards, true))),
        const SizedBox(width: 12),
        Expanded(child: Column(children: _stagger(rightCards, false))),
      ],
    );
  }

  List<Widget> _stagger(List<Widget> cards, bool isLeft) {
    final result = <Widget>[];
    for (int i = 0; i < cards.length; i++) {
      if (isLeft && i == 0) {
        result.add(const SizedBox(height: 8));
      }
      if (!isLeft && i == 0) {
        result.add(const SizedBox(height: 56));
      }
      result.add(cards[i]);
      result.add(const SizedBox(height: 12));
    }
    return result;
  }

  Widget _buildCard(_CardData data, int index) {
    final isList = data.list != null;
    final color = data.color;
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;
    final iconColor = luminance > 0.5 ? color.withAlpha(180) : Colors.white70;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (isList)
                  ...data.list!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(color: textColor.withAlpha(200), fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ))
                else
                  Text(
                    data.content!,
                    style: TextStyle(color: textColor.withAlpha(200), fontSize: 13, height: 1.5),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(data.icon, color: iconColor, size: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardData {
  final String title;
  final IconData icon;
  final Color color;
  final String? content;
  final List<String>? list;
  final bool numbered;

  _CardData({
    required this.title,
    required this.icon,
    required this.color,
    this.content,
    this.list,
    this.numbered = false,
  });
}
