part of 'reader.dart';

class _ReaderGestureDetector extends StatefulWidget {
  const _ReaderGestureDetector({required this.child});

  final Widget child;

  @override
  State<_ReaderGestureDetector> createState() => _ReaderGestureDetectorState();
}

class _ReaderGestureDetectorState extends State<_ReaderGestureDetector> {
  late TapGestureRecognizer _tapGestureRecognizer;

  static const _kDoubleTapMinTime = Duration(milliseconds: 200);

  static const _kDoubleTapMaxDistanceSquared = 20.0 * 20.0;

  static const _kTapToTurnPagePercent = 0.3;

  @override
  void initState() {
    _tapGestureRecognizer = TapGestureRecognizer()
      ..onTapUp = onTapUp
      ..onSecondaryTapUp = (details) {
        onSecondaryTapUp(details.globalPosition);
      };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _tapGestureRecognizer.addPointer(event);
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          onMouseWheel(event.scrollDelta.dy > 0);
        }
      },
      child: widget.child,
    );
  }

  void onMouseWheel(bool forward) {
    if (forward) {
      if (!context.reader.toNextPage()) {
        context.reader.toNextChapter();
      }
    } else {
      if (!context.reader.toPrevPage()) {
        context.reader.toPrevChapter();
      }
    }
  }

  TapUpDetails? _previousEvent;

  void onTapUp(TapUpDetails event) {
    final location = event.globalPosition;
    final previousLocation = _previousEvent?.globalPosition;
    if (previousLocation != null) {
      if ((location - previousLocation).distanceSquared <
          _kDoubleTapMaxDistanceSquared) {
        onDoubleTap(location);
        _previousEvent = null;
        return;
      } else {
        onTap(previousLocation);
      }
    }
    _previousEvent = event;
    Future.delayed(_kDoubleTapMinTime, () {
      if (_previousEvent == event) {
        onTap(location);
        _previousEvent = null;
      }
    });
  }

  void onTap(Offset location) {
    if (context.readerScaffold.isOpen) {
      context.readerScaffold.openOrClose();
    } else {
      if (appdata.settings['enableTapToTurnPages']) {
        bool isLeft = false, isRight = false, isTop = false, isBottom = false;
        final width = context.width;
        final height = context.height;
        final x = location.dx;
        final y = location.dy;
        if (x < width * _kTapToTurnPagePercent) {
          isLeft = true;
        } else if (x > width * (1 - _kTapToTurnPagePercent)) {
          isRight = true;
        }
        if (y < height * _kTapToTurnPagePercent) {
          isTop = true;
        } else if (y > height * (1 - _kTapToTurnPagePercent)) {
          isBottom = true;
        }
        bool isCenter = false;
        switch (context.reader.mode) {
          case ReaderMode.galleryLeftToRight:
          case ReaderMode.continuousLeftToRight:
            if (isLeft) {
              context.reader.toPrevPage();
            } else if (isRight) {
              context.reader.toNextPage();
            } else {
              isCenter = true;
            }
          case ReaderMode.galleryRightToLeft:
          case ReaderMode.continuousRightToLeft:
            if (isLeft) {
              context.reader.toNextPage();
            } else if (isRight) {
              context.reader.toPrevPage();
            } else {
              isCenter = true;
            }
          case ReaderMode.galleryTopToBottom:
          case ReaderMode.continuousTopToBottom:
            if (isTop) {
              context.reader.toPrevPage();
            } else if (isBottom) {
              context.reader.toNextPage();
            } else {
              isCenter = true;
            }
        }
        if (!isCenter) {
          return;
        }
      }
      context.readerScaffold.openOrClose();
    }
  }

  void onDoubleTap(Offset location) {
    context.reader._imageViewController?.handleDoubleTap(location);
  }

  void onSecondaryTapUp(Offset location) {
    showDesktopMenu(
      context,
      location,
      [
        DesktopMenuEntry(text: "Settings".tl, onClick: () {
          context.readerScaffold.openSetting();
        }),
        DesktopMenuEntry(text: "Chapters".tl, onClick: () {
          context.readerScaffold.openChapterDrawer();
        }),
        DesktopMenuEntry(text: "Fullscreen".tl, onClick: () {
          context.reader.fullscreen();
        }),
        DesktopMenuEntry(text: "Exit".tl, onClick: () {
          context.pop();
        }),
      ],
    );
  }
}