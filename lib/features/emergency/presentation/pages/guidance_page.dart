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
  bool _isLoading = true;
  String _assessment = '';
  List<String> _actions = [];
  List<String> _avoid = [];
  List<String> _monitor = [];
  String _seekCare = '';

  late PageController _pageController;
  int _currentCard = 0;
  int _totalCards = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGuidance();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadGuidance() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    final gemma = ref.read(gemmaServiceProvider);
    final context = emergency.emergencyDescription;

    final response = await gemma.generateGuidance(context: context);

    if (response.isNotEmpty) {
      try {
        final data = json.decode(_extractJson(response));
        setState(() {
          _assessment = data['assessment'] ?? '';
          _actions = List<String>.from(data['actions'] ?? []);
          _avoid = List<String>.from(data['avoid'] ?? []);
          _monitor = List<String>.from(data['monitor'] ?? []);
          _seekCare = data['seekCare'] ?? '';
          _totalCards = _countCards();
        });
        final notifier = ref.read(currentEmergencyProvider.notifier);
        notifier.setAiAssessment(_assessment);
        notifier.setImmediateActions(_actions);
        notifier.setThingsToAvoid(_avoid);
        notifier.setMonitor(_monitor);
        notifier.setWhenToSeekCare(_seekCare);
      } catch (_) {
        _setGeneric();
      }
    } else {
      _setGeneric();
    }

    setState(() => _isLoading = false);
  }

  void _setGeneric() {
    setState(() {
      _assessment = 'Assessment pending. Monitor the situation carefully.';
      _actions = ['Stay calm and assess the situation', 'Ensure the scene is safe', 'Call for emergency help if available'];
      _avoid = ['Do not move the person unless necessary', 'Do not leave the person unattended'];
      _monitor = ['Breathing rate and depth', 'Level of consciousness', 'Any changes in condition'];
      _seekCare = 'Seek medical care if the condition worsens.';
      _totalCards = _countCards();
    });
  }

  int _countCards() {
    int c = 0;
    if (_assessment.isNotEmpty) c++;
    if (_actions.isNotEmpty) c++;
    if (_avoid.isNotEmpty) c++;
    if (_monitor.isNotEmpty) c++;
    if (_seekCare.isNotEmpty) c++;
    return c;
  }

  Future<void> _generateSummary() async {
    final emergency = ref.read(currentEmergencyProvider);
    if (emergency == null) return;

    setState(() => _isLoading = true);

    final gemma = ref.read(gemmaServiceProvider);
    final profile = ref.read(profileProvider).valueOrNull;

    final guidance = '''
Assessment: $_assessment
Actions: ${_actions.join(', ')}
Avoid: ${_avoid.join(', ')}
Monitor: ${_monitor.join(', ')}
''';

    final summary = await gemma.generateSummary(
      context: emergency.emergencyDescription,
      guidance: guidance,
      profileInfo: profile != null
          ? 'Name: ${profile.name}, Age: ${profile.age}, Blood: ${profile.bloodGroup}'
          : null,
    );

    if (summary.isNotEmpty) {
      ref.read(currentEmergencyProvider.notifier).setSummary(summary);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      context.go(AppRouter.summary);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(child: _buildCards()),
            _buildBottom(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final colors = [
      AppColors.primary,
      AppColors.safe,
      AppColors.error,
      AppColors.warning,
      AppColors.error,
    ];
    final labels = [
      'Assessment',
      'Actions',
      'Avoid',
      'Monitor',
      'Seek Care',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
                icon: const AppIcon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: AppColors.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              Text(
                'Emergency Guidance',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_totalCards, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _totalCards - 1 ? 4 : 0),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _currentCard
                          ? colors[i.clamp(0, colors.length - 1)]
                          : AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _currentCard < labels.length ? labels[_currentCard] : '',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors[_currentCard.clamp(0, colors.length - 1)],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards() {
    final cards = <Widget>[];
    final colors = [
      AppColors.primary,
      AppColors.safe,
      AppColors.error,
      AppColors.warning,
      AppColors.error,
    ];
    final icons = [
      Icons.psychology_outlined,
      Icons.check_circle_outline_rounded,
      Icons.do_not_disturb_rounded,
      Icons.visibility_rounded,
      Icons.local_hospital_rounded,
    ];
    final titles = [
      'Current Assessment',
      'Immediate Actions',
      'Things To Avoid',
      'Monitor',
      'When To Seek Care',
    ];

    final contents = [_assessment, null, null, null, _seekCare];
    final lists = [null, _actions, _avoid, _monitor, null];

    for (int i = 0; i < titles.length; i++) {
      final content = contents[i];
      final list = lists[i];
      if (content == null && (list == null || list.isEmpty)) continue;

      cards.add(
        _buildCard(
          icon: icons[i],
          color: colors[i],
          title: titles[i],
          content: content,
          items: list,
          number: cards.length + 1,
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentCard = i),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    String? content,
    List<String>? items,
    required int number,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AppIcon(icon, size: 26, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: content != null
                      ? Text(
                          content,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.7,
                            fontSize: 16,
                          ),
                        )
                      : Column(
                          children: List.generate(
                            items?.length ?? 0,
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: number == 2 ? 28 : 8,
                                    height: number == 2 ? 28 : 8,
                                    decoration: BoxDecoration(
                                      color: number == 2
                                          ? color.withAlpha(20)
                                          : color,
                                      borderRadius: BorderRadius.circular(
                                          number == 2 ? 8 : 4),
                                    ),
                                    child: number == 2
                                        ? Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.safe,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      items![i],
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        height: 1.6,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottom(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: FilledButton.icon(
        onPressed: _generateSummary,
        icon: const AppIcon(Icons.description_outlined, size: 18),
        label: const Text('Generate Medical Summary'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
