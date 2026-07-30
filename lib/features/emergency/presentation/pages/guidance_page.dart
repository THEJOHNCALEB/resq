import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/services/agent/resq_agent.dart';

class GuidancePage extends ConsumerStatefulWidget {
  const GuidancePage({super.key});

  @override
  ConsumerState<GuidancePage> createState() => _GuidancePageState();
}

class _GuidancePageState extends ConsumerState<GuidancePage> {
  List<_CardData> _cards = [];
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
    final profile = ref.read(profileProvider).valueOrNull;

    final facilitiesService = ref.read(emergencyFacilitiesServiceProvider);
    try {
      await facilitiesService.loadFacilities();
    } catch (_) {}

    setState(() => _loadingStatus = 'Analysing your emergency...');

    try {
      final turn = await gemma
          .agentGuidance(
            emergencyDescription: emergency.emergencyDescription,
            imagePath: emergency.imagePaths.isNotEmpty
                ? emergency.imagePaths.first
                : null,
            audioPath: emergency.audioPath.isNotEmpty
                ? emergency.audioPath
                : null,
            profile: profile,
            facilities: facilitiesService.getSortedByDistance(),
          )
          .timeout(const Duration(seconds: 90), onTimeout: () {
        return AgentTurn('', []);
      });

      if (turn.reply.isNotEmpty && turn.reply.length > 20) {
        final dynamicCards = _parseDynamicCards(turn.reply);
        if (dynamicCards.isNotEmpty) {
          setState(() {
            _cards = dynamicCards;
            _loading = false;
          });
          _saveToEmergency(dynamicCards);
          return;
        }

        final legacyCards = _parseLegacyCards(turn.reply);
        if (legacyCards.isNotEmpty) {
          setState(() {
            _cards = legacyCards;
            _loading = false;
          });
          _saveToEmergency(legacyCards);
          return;
        }
      }
    } catch (e) {
      debugPrint('[ResQ] Agent guidance failed: $e');
    }

    setState(() {
      _loading = false;
      _loadingStatus = 'The AI model could not generate guidance. Please ensure the model is downloaded and try again.';
      _cards = [];
    });
  }

  void _saveToEmergency(List<_CardData> cards) {
    final n = ref.read(currentEmergencyProvider.notifier);
    for (final card in cards) {
      switch (card.title.toLowerCase()) {
        case 'assessment':
          if (card.content != null) n.setAiAssessment(card.content!);
          break;
        case 'immediate actions':
          n.setImmediateActions(card.list ?? []);
          break;
        case 'things to avoid':
          n.setThingsToAvoid(card.list ?? []);
          break;
        case 'monitor':
          n.setMonitor(card.list ?? []);
          break;
        case 'when to seek care':
          if (card.content != null) n.setWhenToSeekCare(card.content!);
          break;
      }
    }
  }

  List<_CardData> _parseDynamicCards(String text) {
    try {
      final json = _extractJson(text);
      final data = jsonDecode(json);
      if (data is! Map || data['cards'] is! List) return [];
      final list = data['cards'] as List;
      return list.map((item) {
        if (item is! Map) return null;
        final type = item['type'] as String? ?? 'text';
        final colorStr = item['color'] as String? ?? '#2563EB';
        final iconName = item['icon'] as String? ?? 'circle_outlined';
        return _CardData(
          title: item['title'] as String? ?? '',
          icon: _iconFromName(iconName),
          color: _colorFromHex(colorStr),
          content: type == 'text' ? (item['content'] as String?) : null,
          list: type == 'list' && item['content'] is List
              ? List<String>.from(item['content'])
              : null,
        );
      }).whereType<_CardData>().toList();
    } catch (e) {
      debugPrint('[ResQ] Dynamic card parse: $e');
      return [];
    }
  }

  List<_CardData> _parseLegacyCards(String text) {
    try {
      final json = _extractJson(text);
      final data = jsonDecode(json);
      if (data is! Map) return [];
      final cards = <_CardData>[];
      if (data['assessment'] is String && (data['assessment'] as String).isNotEmpty) {
        cards.add(_CardData(title: 'Assessment', icon: Icons.psychology_outlined, color: const Color(0xFF2563EB), content: data['assessment']));
      }
      if (data['actions'] is List) {
        cards.add(_CardData(title: 'Immediate Actions', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF0D9488), list: List<String>.from(data['actions'])));
      }
      if (data['avoid'] is List) {
        cards.add(_CardData(title: 'Things To Avoid', icon: Icons.do_not_disturb_rounded, color: const Color(0xFFE04B3D), list: List<String>.from(data['avoid'])));
      }
      if (data['monitor'] is List) {
        cards.add(_CardData(title: 'Monitor', icon: Icons.visibility_rounded, color: const Color(0xFFD97706), list: List<String>.from(data['monitor'])));
      }
      if (data['seekCare'] is String && (data['seekCare'] as String).isNotEmpty) {
        cards.add(_CardData(title: 'When To Seek Care', icon: Icons.local_hospital_rounded, color: const Color(0xFF6D5BD0), content: data['seekCare']));
      }
      return cards;
    } catch (e) {
      debugPrint('[ResQ] Legacy card parse: $e');
      return [];
    }
  }

  Future<void> _generateSummary() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    setState(() => _generating = true);

    final gemma = ref.read(gemmaServiceProvider);
    final profile = ref.read(profileProvider).valueOrNull;

    final actions = _cards
        .where((c) => c.list != null)
        .expand((c) => c.list!)
        .join(', ');
    final assessment = _cards
        .where((c) => c.content != null && c.title.toLowerCase() == 'assessment')
        .map((c) => c.content!)
        .join('. ');
    final g = 'Assessment: $assessment\nActions: $actions';
    final summary = await gemma.generateSummary(
      context: emergency.emergencyDescription,
      guidance: g,
      profileInfo: profile != null
          ? '${profile.name}, ${profile.age}, ${profile.bloodGroup}'
          : null,
    );

    if (summary.isNotEmpty) {
      ref.read(currentEmergencyProvider.notifier).setSummary(summary);
    }

    if (mounted) {
      context.go(AppRouter.summary);
    }
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'psychology_outlined': return Icons.psychology_outlined;
      case 'check_circle_outline_rounded': return Icons.check_circle_outline_rounded;
      case 'do_not_disturb_rounded': return Icons.do_not_disturb_rounded;
      case 'visibility_rounded': return Icons.visibility_rounded;
      case 'local_hospital_rounded': return Icons.local_hospital_rounded;
      case 'warning_amber_rounded': return Icons.warning_amber_rounded;
      case 'medical_services_rounded': return Icons.medical_services_rounded;
      case 'healing_rounded': return Icons.healing_rounded;
      case 'favorite_rounded': return Icons.favorite_rounded;
      case 'shield_rounded': return Icons.shield_rounded;
      case 'info_rounded': return Icons.info_rounded;
      case 'error_outline_rounded': return Icons.error_outline_rounded;
      case 'help_outline_rounded': return Icons.help_outline_rounded;
      case 'lightbulb_outline_rounded': return Icons.lightbulb_outline_rounded;
      case 'handshake_rounded': return Icons.handshake_rounded;
      case 'medication_rounded': return Icons.medication_rounded;
      case 'sanitizer_rounded': return Icons.sanitizer_rounded;
      case 'masks_rounded': return Icons.masks_rounded;
      case 'water_drop_rounded': return Icons.water_drop_rounded;
      case 'directions_run_rounded': return Icons.directions_run_rounded;
      case 'air_rounded': return Icons.air_rounded;
      case 'bloodtype_rounded': return Icons.bloodtype_rounded;
      case 'fire_extinguisher_rounded': return Icons.fire_extinguisher_rounded;
      case 'warning_rounded': return Icons.warning_rounded;
      default: return Icons.circle_outlined;
    }
  }

  Color _colorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

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
              child: _cards.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppIcon(Icons.psychology_outlined, size: 48, color: AppColors.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(
                              _loadingStatus,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 15, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton(
                              onPressed: _load,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
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

  String _extractJson(String text) {
    text = text.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
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
          image: DecorationImage(image: AssetImage('assets/images/map.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0xCC1E293B), BlendMode.srcOver)),
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
    return [..._cards.map((d) => _buildCard(d)), _buildMapsCard()];
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
