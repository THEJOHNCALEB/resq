import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _loading = true;
  String _loadingStatus = 'Preparing guidance...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    final gemma = ref.read(gemmaServiceProvider);

    setState(() => _loadingStatus = 'Analysing your emergency...');

    try {
      final guidance = await gemma.generateGuidance(
        context: emergency.emergencyDescription,
        imagePath: emergency.imagePaths.isNotEmpty ? emergency.imagePaths.first : null,
        audioPath: emergency.audioPath.isNotEmpty ? emergency.audioPath : null,
      );

      if (guidance.isNotEmpty) {
        final data = json.decode(_extractJson(guidance));
        setState(() {
          _assessment = data['assessment'] ?? '';
          _actions = List<String>.from(data['actions'] ?? []);
          _avoid = List<String>.from(data['avoid'] ?? []);
          _monitor = List<String>.from(data['monitor'] ?? []);
          _seekCare = data['seekCare'] ?? '';
          _loading = false;
        });
        final n = ref.read(currentEmergencyProvider.notifier);
        n.setImmediateActions(_actions);
        n.setThingsToAvoid(_avoid);
        n.setMonitor(_monitor);
        n.setWhenToSeekCare(_seekCare);
        return;
      }
    } catch (e) {
      debugPrint('[ResQ] Gemma failed: $e');
    }

    _setGeneric();
  }

  void _setGeneric() {
    setState(() {
      _assessment = 'Monitor the situation carefully.';
      _actions = ['Stay calm', 'Ensure scene safety', 'Call for help', 'Provide basic first aid'];
      _avoid = ['Do not move the person unless necessary', 'Do not leave them unattended'];
      _monitor = ['Breathing rate and depth', 'Level of consciousness', 'Skin colour', 'Any changes'];
      _seekCare = 'Seek immediate medical care if the condition worsens.';
      _loading = false;
    });
  }

  Future<void> _generateSummary() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    setState(() => _generating = true);

    final gemma = ref.read(gemmaServiceProvider);
    final profile = ref.read(profileProvider).valueOrNull;

    final g = 'Assessment: $_assessment\nActions: ${_actions.join(", ")}';
    final summary = await gemma.generateSummary(
      context: emergency.emergencyDescription,
      guidance: g,
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
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFE04B3D),
    Color(0xFFD97706),
    Color(0xFF6D5BD0),
  ];

  static const cardIcons = [
    Icons.psychology_outlined,
    Icons.check_circle_outline_rounded,
    Icons.do_not_disturb_rounded,
    Icons.visibility_rounded,
    Icons.local_hospital_rounded,
  ];

  static const cardTitles = [
    'Assessment',
    'Immediate Actions',
    'Things To Avoid',
    'Monitor',
    'When To Seek Care',
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(children: [
                  IconButton(
                    onPressed: () { if (context.canPop()) context.pop(); else context.go(AppRouter.home); },
                    icon: const AppIcon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.primary, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('Emergency Guidance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ),
              Expanded(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
                    const SizedBox(height: 20),
                    Text(_loadingStatus, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(
                  onPressed: () { if (context.canPop()) context.pop(); else context.go(AppRouter.home); },
                  icon: const AppIcon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: AppColors.primary, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text('Emergency Guidance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                children: _buildCards(),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(AppRouter.continueToCare),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Continue to Care'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generating ? null : _generateSummary,
                icon: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const AppIcon(Icons.description_outlined, size: 18),
                label: Text(_generating ? 'Generating...' : 'Medical Summary'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps() async {
    try { await launchUrl(Uri.parse('https://www.google.com/maps/search/hospital+near+me'), mode: LaunchMode.externalApplication); }
    catch (e) { debugPrint('[ResQ] Maps error: $e'); }
  }

  Widget _buildMapsCard() {
    return GestureDetector(
      onTap: _openMaps,
      child: Container(
        height: 140,
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/resq_overlay.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0xCC1E293B), BlendMode.srcOver)),
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Find Hospitals', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('Click to find hospitals and clinics near you', style: TextStyle(color: Color(0xBBFFFFFF), fontSize: 13)),
            ])),
            SizedBox(width: 12),
            Icon(Icons.map_outlined, color: Colors.white70, size: 28),
          ]),
        ),
      ),
    );
  }

  List<Widget> _buildCards() {
    final items = <_CardData>[];
    if (_assessment.isNotEmpty) items.add(_CardData(title: cardTitles[0], icon: cardIcons[0], color: cardColors[0], content: _assessment));
    if (_actions.isNotEmpty) items.add(_CardData(title: cardTitles[1], icon: cardIcons[1], color: cardColors[1], list: _actions));
    if (_avoid.isNotEmpty) items.add(_CardData(title: cardTitles[2], icon: cardIcons[2], color: cardColors[2], list: _avoid));
    if (_monitor.isNotEmpty) items.add(_CardData(title: cardTitles[3], icon: cardIcons[3], color: cardColors[3], list: _monitor));
    if (_seekCare.isNotEmpty) items.add(_CardData(title: cardTitles[4], icon: cardIcons[4], color: cardColors[4], content: _seekCare));

    return [...items.map((d) => _buildCard(d)), _buildMapsCard()];
  }

  Widget _buildCard(_CardData data) {
    final color = data.color;
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;
    final iconColor = luminance > 0.5 ? color.withAlpha(160) : Colors.white60;
    final isList = data.list != null;

    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(color: color),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (isList)
              ...data.list!.map((item) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 5), child: Container(width: 5, height: 5, decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: TextStyle(color: textColor.withAlpha(200), fontSize: 13, height: 1.4))),
              ])))
            else
              Text(data.content!, style: TextStyle(color: textColor.withAlpha(200), fontSize: 13, height: 1.5)),
          ])),
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(data.icon, color: iconColor, size: 28)),
        ]),
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
  _CardData({required this.title, required this.icon, required this.color, this.content, this.list});
}
