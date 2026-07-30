import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/calm_button.dart';
import '../../../../shared/providers/app_providers.dart';

class EmergencyFlowPage extends ConsumerStatefulWidget {
  const EmergencyFlowPage({super.key});

  @override
  ConsumerState<EmergencyFlowPage> createState() => _EmergencyFlowPageState();
}

class _EmergencyFlowPageState extends ConsumerState<EmergencyFlowPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _capturedImagePath;
  String? _audioPath;
  final TextEditingController _descriptionController = TextEditingController();
  int _currentStep = 0;
  bool _isProcessing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _audioRecorder.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (state == AppLifecycleState.inactive) {
      _cameraController!.dispose();
      _isCameraReady = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      setState(() => _errorMessage = 'Camera permission required');
      return;
    }

    _cameras = await availableCameras();

    if (_cameras == null || _cameras!.isEmpty) {
      setState(() => _errorMessage = 'No camera available');
      return;
    }

    _cameraController = CameraController(
      _cameras!.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera');
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraReady) return;

    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImagePath = image.path);
      _nextStep();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to capture image');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _capturedImagePath = image.path);
      _nextStep();
    }
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() => _errorMessage = 'Microphone permission required');
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _audioPath = '${dir.path}/emergency_audio.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );

        setState(() => _isRecording = true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() => _isRecording = false);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to stop recording');
    }
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  Future<void> _processEmergency() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() => _isProcessing = true);

    final emergencyNotifier = ref.read(currentEmergencyProvider.notifier);
    emergencyNotifier.updateDescription(description);

    if (_capturedImagePath != null) {
      emergencyNotifier.addImagePath(_capturedImagePath!);
    }
    if (_audioPath != null) {
      emergencyNotifier.setAudioPath(_audioPath!);
    }

    final gemma = ref.read(gemmaServiceProvider);
    if (!gemma.isReady) {
      await gemma.initialize();
    }

    final response = await gemma.analyzeEmergency(
      userDescription: description,
      imagePath: _capturedImagePath,
    );

    if (response.isNotEmpty) {
      try {
        emergencyNotifier.setAiAssessment(response);
      } catch (_) {
        emergencyNotifier.setEmergencyType('Emergency');
        emergencyNotifier.setAiAssessment(description);
      }
    }

    setState(() => _isProcessing = false);

    if (mounted) {
      context.push(AppRouter.guidance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    if (_errorMessage.isNotEmpty && _currentStep == 0) {
      return _buildErrorState(context, theme);
    }

    final isCameraStep = _currentStep == 0;

    return Scaffold(
      backgroundColor: isCameraStep ? Colors.black : AppColors.background,
      resizeToAvoidBottomInset: !isCameraStep,
      appBar: AppBar(
        backgroundColor: isCameraStep ? Colors.black : AppColors.background,
        foregroundColor: isCameraStep ? Colors.white : AppColors.onSurface,
        elevation: 0,
        title: Text(_getStepTitle()),
        leading: IconButton(
          icon: AppIcon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildStepContent(context, theme, size)),
            _buildBottomControls(context, theme),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Tell me briefly what happened';
      case 1:
        return 'Describe the situation';
      default:
        return 'Emergency';
    }
  }

  Widget _buildStepContent(BuildContext context, ThemeData theme, Size size) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _errorMessage,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isProcessing) {
      return _buildProcessingScreen(theme);
    }

    switch (_currentStep) {
      case 0:
        return _buildCameraStep(size);
      case 1:
        return _buildDescriptionStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProcessingScreen(ThemeData theme) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Processing your emergency',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Analysing your description and image\nto provide the best guidance.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _ProcessingStep(
                index: 1,
                label: 'Analysing your description',
                isComplete: true,
              ),
              const SizedBox(height: 12),
              _ProcessingStep(
                index: 2,
                label: 'Evaluating visible findings',
                isComplete: false,
              ),
              const SizedBox(height: 12),
              _ProcessingStep(
                index: 3,
                label: 'Generating structured guidance',
                isComplete: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraStep(Size size) {
    if (!_isCameraReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isCameraReady) CameraPreview(_cameraController!),
        if (_capturedImagePath != null)
          Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Take a photo of the situation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionStep(ThemeData theme) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Text(
            'Tell me briefly what happened',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type your description or use your voice',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Example: I was cooking and hot oil spilled on my hand. The skin is red and there are blisters forming...',
                  hintMaxLines: 3,
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
          ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withAlpha(50)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recording... tap Stop when done',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, ThemeData theme) {
    if (_isProcessing) return const SizedBox.shrink();

    switch (_currentStep) {
      case 0:
        return _buildCameraControls(context, theme);
      case 1:
        return _buildDescriptionControls(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCameraControls(BuildContext context, ThemeData theme) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _pickFromGallery,
            icon: AppIcon(
              Icons.camera_alt,
              color: Colors.white70,
              size: 28,
            ),
            tooltip: 'Choose from gallery',
          ),
          InkWell(
            onTap: _captureImage,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDescriptionControls(ThemeData theme) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalmButton(
            label: 'Continue',
            icon: Icons.send_rounded,
            isPrimary: true,
            isFullWidth: true,
            height: 52,
            onPressed: _processEmergency,
          ),
          const SizedBox(height: 8),
          CalmButton(
            label: _isRecording ? 'Stop Recording' : 'Start Recording',
            icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            isPrimary: false,
            isEmergency: _isRecording,
            isFullWidth: true,
            height: 48,
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency'),
        leading: IconButton(
          icon: AppIcon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppIcon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please grant the required permissions in your device settings and try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              CalmButton(
                label: 'Go Back',
                icon: Icons.arrow_back_rounded,
                isPrimary: false,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingStep extends StatefulWidget {
  final int index;
  final String label;
  final bool isComplete;

  const _ProcessingStep({
    required this.index,
    required this.label,
    required this.isComplete,
  });

  @override
  State<_ProcessingStep> createState() => _ProcessingStepState();
}

class _ProcessingStepState extends State<_ProcessingStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _animation,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isComplete
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(20),
              border: Border.all(
                color: widget.isComplete
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                width: 1.5,
              ),
            ),
            child: widget.isComplete
                ? AppIcon(Icons.check, size: 16, color: Colors.white)
                : Center(
                    child: Text(
                      '${widget.index}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.isComplete
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
              fontWeight: widget.isComplete
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
