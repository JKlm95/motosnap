import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../camera/scan_camera_controller.dart';
import '../camera/scan_camera_layer.dart';
import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';
import '../widgets/scan_camera_overlay.dart';
import 'scan_flow_overlay.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ScanCameraController _cameraController;
  final ValueNotifier<bool> _hudVisible = ValueNotifier(true);
  ScanFlowPhase _lastFlowPhase = ScanFlowPhase.idle;

  @override
  void initState() {
    super.initState();
    _cameraController = ScanCameraController()..attach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraController.setTabActive(MainShellLayout.scanTabActiveOf(context));
  }

  @override
  void dispose() {
    _hudVisible.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _syncHudVisible(ScanState state) {
    final busy =
        state.phase == ScanFlowPhase.requestingPermissions ||
        state.phase == ScanFlowPhase.saving;
    final show =
        state.phase != ScanFlowPhase.success &&
        state.errorMessage == null &&
        !busy;
    if (_hudVisible.value != show) {
      _hudVisible.value = show;
    }
  }

  Future<void> _onEmbeddedCapture(BuildContext context, String lang) async {
    final cubit = context.read<ScanCubit>();
    if (cubit.state.phase == ScanFlowPhase.saving ||
        cubit.state.phase == ScanFlowPhase.requestingPermissions) {
      return;
    }

    AppHaptics.lightImpact();
    final file = await _cameraController.takePicture();
    if (!context.mounted || file == null) {
      return;
    }
    await cubit.saveScanFromPhoto(file, lang);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    final tabActive = MainShellLayout.scanTabActiveOf(context);

    return BlocListener<ScanCubit, ScanState>(
      listenWhen: (prev, next) =>
          prev.phase != next.phase || prev.errorMessage != next.errorMessage,
      listener: (context, state) {
        _syncHudVisible(state);
        if (_lastFlowPhase != state.phase) {
          if (state.phase == ScanFlowPhase.success) {
            AppHaptics.success();
          } else if (state.phase == ScanFlowPhase.error &&
              state.errorMessage != null) {
            AppHaptics.error();
          }
          _lastFlowPhase = state.phase;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          title: Text(s.scanTabTitle),
          backgroundColor: Colors.transparent,
          actions: [
            PopupMenuButton<ScanCaptureSource>(
              tooltip: s.scanOpenGallery,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (source) async {
                final cubit = context.read<ScanCubit>();
                switch (source) {
                  case ScanCaptureSource.gallery:
                    await cubit.importFromGallery(lang);
                  case ScanCaptureSource.systemCamera:
                    await cubit.captureAndSaveScan(lang);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: ScanCaptureSource.gallery,
                  child: Text(s.scanOpenGallery),
                ),
                PopupMenuItem(
                  value: ScanCaptureSource.systemCamera,
                  child: Text(s.scanSystemCamera),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            ScanCameraLayer(
              controller: _cameraController,
              hudVisible: _hudVisible,
              tabActive: tabActive,
              onTapFocus: (p) {
                AppHaptics.lightImpact();
                _cameraController.setFocusPoint(p);
              },
            ),
            if (kDebugMode)
              ScanRebuildProbe(
                label: 'scan_flow_overlay',
                child: ScanFlowOverlay(
                  cameraController: _cameraController,
                  onEmbeddedCapture: _onEmbeddedCapture,
                ),
              )
            else
              ScanFlowOverlay(
                cameraController: _cameraController,
                onEmbeddedCapture: _onEmbeddedCapture,
              ),
          ],
        ),
      ),
    );
  }
}
