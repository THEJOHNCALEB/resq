import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/providers/app_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _sheetShown = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModelAfterDelay();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkModelAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('model_sheet_dismissed') ?? false) return;

    final gemma = ref.read(gemmaServiceProvider);
    if (!gemma.modelLoaded && !_sheetShown) {
      _sheetShown = true;
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ModelSheet(onDismissed: () async {
          final p = await SharedPreferences.getInstance();
          await p.setBool('model_sheet_dismissed', true);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelReady = ref.watch(gemmaServiceProvider).modelLoaded;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            _buildHeader(theme, modelReady),
            const Spacer(flex: 2),
            _buildEmergencyButton(),
            const Spacer(flex: 2),
            _buildQuickActions(),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool modelReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            'ResQ',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: modelReady ? AppColors.safe : AppColors.warning,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                modelReady ? 'Gemma 4 Ready' : 'Basic Mode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: () {
          ref.read(currentEmergencyProvider.notifier).startNewSession();
          context.push(AppRouter.emergencyFlow);
        },
        child: Container(
          width: 176,
          height: 176,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emergency,
            boxShadow: [
              BoxShadow(
                color: AppColors.emergency.withAlpha(60),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(Icons.warning_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 6),
              Text(
                'Start\nEmergency',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.person_outline_rounded,
              label: 'Medical Profile',
              subtitle: 'Allergies, blood group, contacts',
              onTap: () => context.push(AppRouter.profile),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionCard(
              icon: Icons.history_rounded,
              label: 'Care History',
              subtitle: 'Past emergency sessions',
              onTap: () => context.push(AppRouter.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(label, style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelSheet extends StatefulWidget {
  final VoidCallback? onDismissed;
  const _ModelSheet({this.onDismissed});

  @override
  State<_ModelSheet> createState() => _ModelSheetState();
}

class _ModelSheetState extends State<_ModelSheet> {
  bool _downloading = false;
  double _progress = 0;
  String _status = '';
  bool _done = false;
  bool _installed = false;

  static const _url =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_q4_k_fp16.task';
  static const _nativePath = '/data/local/tmp/llm/model.bin';

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _status = 'Starting download...';
    });

    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(_url));
      final res = await req.close();

      final total = res.contentLength;
      var downloaded = 0;

      final dir = await getDownloadsDirectory();
      final resqDir = Directory('${dir!.path}/ResQ');
      if (!await resqDir.exists()) await resqDir.create(recursive: true);
      final file = File('${resqDir.path}/model.bin');

      final sink = file.openWrite();
      await for (final chunk in res) {
        downloaded += chunk.length;
        sink.add(chunk);
        if (total > 0 && mounted) {
          setState(() {
            _progress = downloaded / total;
            _status = '${(downloaded / 1024 / 1024).toStringAsFixed(0)} of ${(total / 1024 / 1024).toStringAsFixed(0)} MB';
          });
        }
      }
      await sink.close();
      client.close();

      setState(() => _status = 'Installing...');

      final installed = await _tryInstall(file);

      setState(() {
        _progress = 1;
        _downloading = false;
        _done = true;
        _installed = installed;
        _status = installed
            ? 'Model ready. Restart ResQ to activate.'
            : 'Saved to Downloads/ResQ/model.bin\nTap to restart and try again.';
      });
    } catch (e) {
      setState(() {
        _downloading = false;
        _status = 'Download failed. Try again.';
      });
    }
  }

  Future<bool> _tryInstall(File source) async {
    for (final fn in [
      () => Process.run('cp', [source.path, _nativePath]),
      () async {
        await File(_nativePath).parent.create(recursive: true);
        await source.copy(_nativePath);
        return ProcessResult(0, 0, '', '');
      },
    ]) {
      try {
        final r = await fn();
        if (r.exitCode == 0) return true;
      } catch (_) {}
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text('Get Gemma 4', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Download the model for AI-powered emergency guidance on this device.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          if (_downloading) ...[
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: _progress, minHeight: 8,
                backgroundColor: AppColors.primary.withAlpha(20), color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(_status, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
          ],
          if (_done && !_downloading) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_installed ? AppColors.safe : AppColors.warning).withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                AppIcon(_installed ? Icons.check_circle_outline : Icons.info_outline, size: 22,
                  color: _installed ? AppColors.safe : AppColors.warning),
                const SizedBox(width: 12),
                Expanded(child: Text(_status,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {
                widget.onDismissed?.call();
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Close'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(
              onPressed: _done
                  ? () { widget.onDismissed?.call(); Navigator.pop(context); }
                  : _downloading ? null : _download,
              icon: AppIcon(_done ? Icons.check_rounded : Icons.download_rounded, size: 18),
              label: Text(_done ? 'Done' : 'Download'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          ]),
        ],
      ),
    );
  }
}
