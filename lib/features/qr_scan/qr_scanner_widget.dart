import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:diagnect/app/theme/app_colors.dart';

class QrScannerWidget extends StatefulWidget {
  const QrScannerWidget({
    super.key,
    this.onQrScanned,
    required this.isActive,
  });

  final ValueChanged<String>? onQrScanned;
  final bool isActive;

  @override
  State<QrScannerWidget> createState() =>
      _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  // =========================================================
  // CAMERA CONTROLLER
  // =========================================================

  late final MobileScannerController _controller;

  // =========================================================
  // STATE
  // =========================================================

  /// True while the camera scanner is actively running.
  bool _isScanning = false;

  /// True while we are waiting for the camera to finish stopping.
  bool _isStopping = false;

  /// Prevents multiple QR callbacks from being processed
  /// while one QR result is already being handled.
  bool _isProcessingResult = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      autoStart: false,
    );

    debugPrint('QR scanner widget initialized.');
  }

  // =========================================================
  // WIDGET UPDATE
  // =========================================================

  @override
  void didUpdateWidget(
      covariant QrScannerWidget oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    // ---------------------------------------------------------
    // PAGE/SECTION BECAME INACTIVE
    // ---------------------------------------------------------

    if (oldWidget.isActive && !widget.isActive) {
      debugPrint(
        'QR scanner: widget became inactive.',
      );

      _stopScanner();
    }

    // ---------------------------------------------------------
    // PAGE/SECTION BECAME ACTIVE AGAIN
    // ---------------------------------------------------------

    if (!oldWidget.isActive && widget.isActive) {
      debugPrint(
        'QR scanner: widget became active again.',
      );

      // The camera does NOT automatically start.
      //
      // User must press "Scan QR".
      //
      // Reset the result-processing state so that scanning
      // can be started again.
      if (mounted) {
        setState(() {
          _isProcessingResult = false;
        });
      }
    }
  }

  // =========================================================
  // START SCANNER
  // =========================================================

  Future<void> _startScanner() async {
    // ---------------------------------------------------------
    // SAFETY CHECKS
    // ---------------------------------------------------------

    if (_isScanning) {
      debugPrint(
        'QR scanner: already scanning.',
      );
      return;
    }

    if (_isStopping) {
      debugPrint(
        'QR scanner: still stopping. Start ignored.',
      );
      return;
    }

    if (_isProcessingResult) {
      debugPrint(
        'QR scanner: result still being processed. Start ignored.',
      );
      return;
    }

    if (!widget.isActive) {
      debugPrint(
        'QR scanner: widget is inactive. Start ignored.',
      );
      return;
    }

    // ---------------------------------------------------------
    // UPDATE UI BEFORE STARTING CAMERA
    // ---------------------------------------------------------

    if (mounted) {
      setState(() {
        _isScanning = true;
      });
    }

    try {
      debugPrint(
        'QR scanner: starting camera...',
      );

      await _controller.start();

      debugPrint(
        'QR scanner: camera started.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'QR scanner: unable to start camera: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isScanning = false;
        _isStopping = false;
        _isProcessingResult = false;
      });

      _showError(
        'Unable to start camera.',
      );
    }
  }

  // =========================================================
  // STOP SCANNER
  // =========================================================

  Future<void> _stopScanner() async {
    // ---------------------------------------------------------
    // IF CAMERA IS NOT RUNNING, NOTHING TO DO.
    // ---------------------------------------------------------

    if (!_isScanning) {
      debugPrint(
        'QR scanner: stop requested but camera is not scanning.',
      );

      return;
    }

    // ---------------------------------------------------------
    // PREVENT MULTIPLE STOP CALLS
    // ---------------------------------------------------------

    if (_isStopping) {
      debugPrint(
        'QR scanner: stop already in progress.',
      );

      return;
    }

    _isStopping = true;

    debugPrint(
      'QR scanner: stopping camera...',
    );

    try {
      await _controller.stop();

      debugPrint(
        'QR scanner: camera stopped.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'QR scanner: unable to stop camera: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isScanning = false;
        _isStopping = false;
      });
    }
  }

  // =========================================================
  // QR DETECTED
  // =========================================================

  Future<void> _onDetect(
      BarcodeCapture capture,
      ) async {
    // ---------------------------------------------------------
    // IGNORE RESULTS WHEN:
    //
    // 1. Camera isn't scanning
    // 2. Camera is stopping
    // 3. Another QR result is already being processed
    // ---------------------------------------------------------

    if (!_isScanning) {
      return;
    }

    if (_isStopping) {
      return;
    }

    if (_isProcessingResult) {
      return;
    }

    // ---------------------------------------------------------
    // FIND FIRST VALID QR VALUE
    // ---------------------------------------------------------

    String? qrText;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        qrText = value.trim();
        break;
      }
    }

    // Nothing useful detected.
    if (qrText == null) {
      return;
    }

    // ---------------------------------------------------------
    // LOCK RESULT PROCESSING
    //
    // MobileScanner can detect the same QR across multiple
    // consecutive frames.
    //
    // This flag prevents multiple callbacks.
    // ---------------------------------------------------------

    _isProcessingResult = true;

    debugPrint(
      '========================================',
    );

    debugPrint(
      'QR CODE SCANNED',
    );

    debugPrint(
      qrText,
    );

    debugPrint(
      '========================================',
    );

    // ---------------------------------------------------------
    // STOP CAMERA FIRST
    // ---------------------------------------------------------

    await _stopScanner();

    if (!mounted) {
      return;
    }

    // ---------------------------------------------------------
    // IMPORTANT:
    //
    // The old implementation left `_qrAlreadyScanned`
    // permanently true.
    //
    // We explicitly release the result-processing lock here
    // AFTER the camera has stopped.
    //
    // This allows the Scan QR button to return to its normal
    // enabled state.
    // ---------------------------------------------------------

    setState(() {
      _isProcessingResult = false;
      _isScanning = false;
      _isStopping = false;
    });

    debugPrint(
      'QR scanner: ready for another scan.',
    );

    // ---------------------------------------------------------
    // SEND RESULT TO HOMEPAGE
    // ---------------------------------------------------------

    widget.onQrScanned?.call(qrText);
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    debugPrint(
      'QR scanner widget disposed.',
    );

    // Do not call _stopScanner() here.
    //
    // dispose() should not start a new asynchronous lifecycle.
    //
    // MobileScannerController.dispose() handles the native
    // camera resource cleanup.
    _controller.dispose();

    super.dispose();
  }

  // =========================================================
  // ERROR
  // =========================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    // ---------------------------------------------------------
    // BUTTON SHOULD ONLY BE DISABLED WHILE:
    //
    // - Camera is actively scanning
    // - Camera is stopping
    // - A QR result is currently being processed
    //
    // There is NO permanent "already scanned" state anymore.
    // ---------------------------------------------------------

    final bool canStartScanning =
        !_isScanning &&
            !_isStopping &&
            !_isProcessingResult &&
            widget.isActive;

    return Column(
      children: [
        // =====================================================
        // CAMERA PREVIEW
        // =====================================================

        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: double.infinity,
            height: 330,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // -------------------------------------------------
                // BLACK BACKGROUND
                // -------------------------------------------------

                Container(
                  color: Colors.black,
                ),

                // -------------------------------------------------
                // CAMERA
                // -------------------------------------------------

                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),

                // -------------------------------------------------
                // SCANNING OVERLAY
                // -------------------------------------------------

                if (_isScanning)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ScannerOverlayPainter(),
                    ),
                  ),

                // -------------------------------------------------
                // IDLE STATE
                // -------------------------------------------------

                if (!_isScanning)
                  Container(
                    color: Colors.black.withValues(
                      alpha: 0.35,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  ),

                // -------------------------------------------------
                // SCANNING LABEL
                // -------------------------------------------------

                if (_isScanning)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: const Text(
                          'Scanning...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // -------------------------------------------------
                // PROCESSING STATE
                //
                // This is only visible during the tiny period
                // between QR detection and callback.
                // -------------------------------------------------

                if (_isProcessingResult && !_isScanning)
                  Container(
                    color: Colors.black.withValues(
                      alpha: 0.35,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        // =====================================================
        // SCAN BUTTON
        // =====================================================

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canStartScanning
                ? _startScanner
                : null,
            icon: const Icon(
              Icons.camera_alt_outlined,
            ),
            label: Text(
              _isScanning
                  ? 'Scanning...'
                  : _isStopping
                  ? 'Stopping...'
                  : _isProcessingResult
                  ? 'Processing...'
                  : 'Scan QR',
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// SCANNER OVERLAY
// =============================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    const double boxSize = 210;

    final double left =
        (size.width - boxSize) / 2;

    final double top =
        (size.height - boxSize) / 2;

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const double cornerLength = 28;

    // =========================================================
    // TOP LEFT
    // =========================================================

    canvas.drawLine(
      Offset(left, top),
      Offset(
        left + cornerLength,
        top,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(left, top),
      Offset(
        left,
        top + cornerLength,
      ),
      paint,
    );

    // =========================================================
    // TOP RIGHT
    // =========================================================

    canvas.drawLine(
      Offset(
        left + boxSize,
        top,
      ),
      Offset(
        left + boxSize - cornerLength,
        top,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        left + boxSize,
        top,
      ),
      Offset(
        left + boxSize,
        top + cornerLength,
      ),
      paint,
    );

    // =========================================================
    // BOTTOM LEFT
    // =========================================================

    canvas.drawLine(
      Offset(
        left,
        top + boxSize,
      ),
      Offset(
        left + cornerLength,
        top + boxSize,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        left,
        top + boxSize,
      ),
      Offset(
        left,
        top + boxSize - cornerLength,
      ),
      paint,
    );

    // =========================================================
    // BOTTOM RIGHT
    // =========================================================

    canvas.drawLine(
      Offset(
        left + boxSize,
        top + boxSize,
      ),
      Offset(
        left + boxSize - cornerLength,
        top + boxSize,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        left + boxSize,
        top + boxSize,
      ),
      Offset(
        left + boxSize,
        top + boxSize - cornerLength,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}