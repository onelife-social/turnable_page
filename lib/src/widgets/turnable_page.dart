import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../enums/page_view_mode.dart';
import '../flip/flip_settings.dart';
import '../model/paper_boundary_decoration.dart';
import '../utils/page_cache_manager.dart';
import 'page_flip_controller.dart';
import 'turnable_page_view.dart';

class TurnablePage extends StatelessWidget {
  final PageFlipController? controller;
  final TurnableBuilder builder;
  final ValueNotifier<bool>? zoomNotifier;
  final int pageCount;
  final TurnablePageCallback? onPageChanged;
  final FlipSettings settings;
  final PageViewMode pageViewMode;
  final bool autoResponseSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final double? aspectRatio;
  final bool pagesBoundaryIsEnabled;
  final PageCacheManager? cacheManager;

  TurnablePage({
    super.key,
    this.controller,
    this.aspectRatio,
    required this.builder,
    this.zoomNotifier,
    required this.pageCount,
    this.onPageChanged,
    this.pageViewMode = PageViewMode.single,
    this.autoResponseSize = true,
    this.paperBoundaryDecoration = PaperBoundaryDecoration.vintage,
    FlipSettings? settings,
    this.pagesBoundaryIsEnabled = true,
    this.cacheManager,
  }) : settings = settings ?? FlipSettings() {
    if (settings != null) {
      assert(
        this.settings.startPageIndex >= 0,
        'Page count must be greater than 0',
      );
      assert(
        this.settings.startPageIndex < pageCount,
        'Start page index must be less than page count',
      );
    }
  }

  Size _calculateBookSize({
    required double maxWidth,
    required double maxHeight,
    required double aspectRatio,
    required double devicePixelRatio,
    required bool usePortrait,
  }) {
    double height = maxWidth / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      maxWidth = height * aspectRatio;
    }

    if (devicePixelRatio <= 0) {
      return Size(maxWidth, height);
    }

    int widthPixels = (maxWidth * devicePixelRatio).floor();
    if (!usePortrait && widthPixels.isOdd) {
      widthPixels = math.max(2, widthPixels - 1);
    }
    widthPixels = math.max(1, widthPixels);

    final snappedWidth = widthPixels / devicePixelRatio;
    int heightPixels = ((snappedWidth / aspectRatio) * devicePixelRatio)
        .round();
    if (heightPixels <= 0) {
      heightPixels = math.max(1, (height * devicePixelRatio).floor());
    }

    if (maxHeight.isFinite) {
      final maxHeightPixels = (maxHeight * devicePixelRatio).floor();
      heightPixels = math.min(heightPixels, math.max(1, maxHeightPixels));
    }

    final snappedHeight = heightPixels / devicePixelRatio;
    return Size(snappedWidth, snappedHeight);
  }

  double _getAspectRatio(bool isMobile) {
    if (!autoResponseSize && pageViewMode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3;
    }
    if (pageViewMode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3 * (isMobile ? 1 : 2);
    }
    return aspectRatio ?? (2 / 3) * 2;
  }

  FlipSettings _getAdjustedSetting(bool isMobile) {
    if (!autoResponseSize && pageViewMode == PageViewMode.single) {
      return settings.copyWith(usePortrait: true);
    }
    final usePortrait = pageViewMode == PageViewMode.single && isMobile;
    return settings.copyWith(usePortrait: usePortrait);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final aspectRatio = _getAspectRatio(isMobile);
        FlipSettings adjustedSettings = _getAdjustedSetting(isMobile);
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

        final bookSize = _calculateBookSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          aspectRatio: aspectRatio,
          devicePixelRatio: devicePixelRatio,
          usePortrait: adjustedSettings.usePortrait,
        );
        adjustedSettings = adjustedSettings.copyWith(
          width: bookSize.width,
          height: bookSize.height,
        );

        return TurnablePageView(
          builder: (context, index) => builder(context, index, constraints),
          zoomNotifier: zoomNotifier,
          bookSize: bookSize,
          settings: adjustedSettings,
          pageCount: pageCount,
          controller: controller,
          aspectRatio: aspectRatio,
          onPageChanged: onPageChanged,
          pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
          paperBoundaryDecoration: paperBoundaryDecoration,
          cacheManager: cacheManager,
        );
      },
    );
  }
}

typedef TurnableBuilder =
    Widget Function(
      BuildContext context,
      int pageIndex,
      BoxConstraints constraints,
    );
typedef TurnablePageCallback =
    void Function(int leftPageIndex, int rightPageIndex);
typedef PageWidgetBuilder = Widget Function(BuildContext context, int index);
