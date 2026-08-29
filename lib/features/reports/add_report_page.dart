import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/services/auth_manager.dart';

class AddReportPage extends StatefulWidget {
  const AddReportPage({
    super.key,
    this.onReportChanged,
  });

  final VoidCallback? onReportChanged;

  @override
  State<AddReportPage> createState() =>
      _AddReportPageState();
}

class _AddReportPageState extends State<AddReportPage> {
  final AuthManager _authManager =
      AuthManager.instance;

  // =========================================================
  // PDF UPLOAD
  // =========================================================

  Future<void> _pickPdf() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
        ],
      );

      if (result == null ||
          result.files.single.path == null) {
        return;
      }

      final file = result.files.single;

      await _openReportForm(
        filePaths: [
          file.path!,
        ],
        fileType: 'pdf',
        suggestedTitle:
        file.name.replaceFirst(
          RegExp(
            r'\.pdf$',
            caseSensitive: false,
          ),
          '',
        ),
        defaultType: 'Lab Report',
      );
    } catch (e) {
      _showError(
        'Unable to select PDF: $e',
      );
    }
  }

  // =========================================================
  // IMAGE UPLOAD
  // =========================================================

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      final image =
      await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) {
        return;
      }

      await _openReportForm(
        filePaths: [
          image.path,
        ],
        fileType: 'image',
        suggestedTitle:
        image.name.replaceFirst(
          RegExp(r'\.[^.]+$'),
          '',
        ),
        defaultType: 'Other',
      );
    } catch (e) {
      _showError(
        'Unable to select image: $e',
      );
    }
  }

  // =========================================================
  // SCAN DOCUMENT
  //
  // Scan -> PDF -> temporary scanner PDF
  //       -> AuthManager copies PDF into permanent
  //          application storage
  //       -> PDF path stored in ReportModel/database
  //
  // =========================================================

  Future<void> _scanDocument() async {
    DocumentScanner? scanner;

    try {
      const Set<DocumentFormat> documentFormats = {
        DocumentFormat.jpeg,
        DocumentFormat.pdf,
      };

      final options = DocumentScannerOptions(
        documentFormats: documentFormats,
        pageLimit: 20,
        isGalleryImport: false,
      );

      scanner = DocumentScanner(
        options: options,
      );

      final result =
      await scanner.scanDocument();

      final pdf = result.pdf;

      if (pdf == null ||
          pdf.uri.trim().isEmpty) {
        _showError(
          'The scanner did not return a PDF.',
        );
        return;
      }

      final pdfPath = pdf.uri;

      final pdfFile = File(pdfPath);

      if (!await pdfFile.exists()) {
        _showError(
          'The scanned PDF could not be found.',
        );
        return;
      }

      final pageCount = pdf.pageCount;

      await _openReportForm(
        filePaths: [
          pdfPath,
        ],
        fileType: 'scan_pdf',
        suggestedTitle:
        pageCount == 1
            ? 'Scanned Medical Report'
            : 'Scanned Medical Report '
            '($pageCount pages)',
        defaultType: 'Other',
      );
    } catch (e) {
      _showError(
        'Unable to scan document: $e',
      );
    } finally {
      try {
        await scanner?.close();
      } catch (e) {
        debugPrint(
          'Unable to close document scanner: $e',
        );
      }
    }
  }

  // =========================================================
  // MANUAL REPORT
  // =========================================================

  Future<void> _createManualReport() async {
    await _openReportForm(
      filePaths: const [],
      fileType: null,
      suggestedTitle: 'Medical Report',
      defaultType: 'Consultation',
    );
  }

  // =========================================================
  // REPORT FORM
  // =========================================================
  //
  // IMPORTANT:
  //
  // Controllers are NO LONGER created here.
  //
  // The dialog owns its own controllers.
  //
  // This prevents the FocusNode/TextField/controller
  // lifecycle problem when cancelling while the keyboard
  // is active.
  //
  // =========================================================

  Future<void> _openReportForm({
    required List<String> filePaths,
    required String? fileType,
    required String suggestedTitle,
    required String defaultType,
  }) async {
    final result =
    await showDialog<_ReportFormResult>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _ReportDetailsDialog(
          suggestedTitle: suggestedTitle,
          selectedType: defaultType,
          selectedDate: DateTime.now(),
          filePaths: filePaths,
        );
      },
    );

    // ---------------------------------------------------------
    // USER CANCELLED
    // ---------------------------------------------------------

    if (result == null) {
      return;
    }

    // ---------------------------------------------------------
    // GET VALUES FROM DIALOG
    // ---------------------------------------------------------

    final title =
    result.title.trim();

    final hospital =
    result.hospital.trim();

    final description =
    result.description.trim();

    // ---------------------------------------------------------
    // VALIDATE TITLE
    // ---------------------------------------------------------

    if (title.isEmpty) {
      _showError(
        'Please enter a report title.',
      );
      return;
    }

    // ---------------------------------------------------------
    // VALIDATE FILES
    // ---------------------------------------------------------

    for (final filePath in filePaths) {
      if (filePath.trim().isEmpty) {
        continue;
      }

      final file = File(filePath);

      if (!await file.exists()) {
        _showError(
          'Attached file could not be found.',
        );
        return;
      }
    }

    // ---------------------------------------------------------
    // SAVE REPORT
    // ---------------------------------------------------------

    try {
      await _authManager.addReport(
        title: title,
        hospital:
        hospital.isEmpty
            ? null
            : hospital,
        type: result.type,
        description:
        description.isEmpty
            ? null
            : description,
        filePaths: filePaths,
        fileType: fileType,
        reportDate:
        _formatDate(
          result.date,
        ),
      );

      // -------------------------------------------------------
      // NOTIFY PARENT
      // -------------------------------------------------------

      widget.onReportChanged?.call();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Medical report added successfully.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showError(
        'Unable to save report: $e',
      );
    }
  }

  // =========================================================
  // DATE
  // =========================================================

  String _formatDate(
      DateTime date,
      ) {
    final month =
    date.month
        .toString()
        .padLeft(2, '0');

    final day =
    date.day
        .toString()
        .padLeft(2, '0');

    return '${date.year}-$month-$day';
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
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
    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 12,
          ),

          const Text(
            'Add Medical Report',
            style: TextStyle(
              fontSize: 26,
              fontWeight:
              FontWeight.w700,
              color:
              AppColors.primaryText,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Add a medical document to your personal health record.',
            style: TextStyle(
              fontSize: 14,
              color:
              AppColors.secondaryText,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // ---------------------------------------------------
          // PDF
          // ---------------------------------------------------

          _reportAction(
            icon:
            Icons.picture_as_pdf_outlined,
            title:
            'Upload PDF',
            subtitle:
            'Add a PDF medical report.',
            onTap:
            _pickPdf,
          ),

          const SizedBox(
            height: 12,
          ),

          // ---------------------------------------------------
          // IMAGE
          // ---------------------------------------------------

          _reportAction(
            icon:
            Icons.image_outlined,
            title:
            'Upload Image',
            subtitle:
            'Add a photo of your report.',
            onTap:
            _pickImage,
          ),

          const SizedBox(
            height: 12,
          ),

          // ---------------------------------------------------
          // SCAN
          // ---------------------------------------------------

          _reportAction(
            icon:
            Icons.document_scanner_outlined,
            title:
            'Scan Document',
            subtitle:
            'Scan multiple pages and save them as one PDF.',
            onTap:
            _scanDocument,
          ),

          const SizedBox(
            height: 12,
          ),

          // ---------------------------------------------------
          // MANUAL
          // ---------------------------------------------------

          _reportAction(
            icon:
            Icons.edit_note_rounded,
            title:
            'Enter Manually',
            subtitle:
            'Create a report without a file.',
            onTap:
            _createManualReport,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REPORT ACTION
  // =========================================================

  Widget _reportAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(20),
        decoration:
        BoxDecoration(
          color:
          AppColors.surface,
          borderRadius:
          BorderRadius.circular(18),
          border:
          Border.all(
            color: Colors.grey
                .withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
              BoxDecoration(
                color: AppColors
                    .lightViolet
                    .withValues(
                  alpha: 0.15,
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color:
                AppColors.primary,
                size: 27,
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      AppColors.primaryText,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    subtitle,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .chevron_right_rounded,
              color:
              AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// REPORT FORM RESULT
// =============================================================

class _ReportFormResult {
  const _ReportFormResult({
    required this.title,
    required this.hospital,
    required this.type,
    required this.description,
    required this.date,
  });

  final String title;
  final String hospital;
  final String type;
  final String description;
  final DateTime date;
}

// =============================================================
// REPORT DETAILS DIALOG
//
// IMPORTANT:
// The dialog owns ALL TextEditingControllers.
//
// This is the important fix for:
//
// '_dependents.isEmpty': is not true
//
// when cancelling while a TextField is focused.
// =============================================================

class _ReportDetailsDialog
    extends StatefulWidget {
  const _ReportDetailsDialog({
    required this.suggestedTitle,
    required this.selectedType,
    required this.selectedDate,
    required this.filePaths,
  });

  final String suggestedTitle;
  final String selectedType;
  final DateTime selectedDate;
  final List<String> filePaths;

  @override
  State<_ReportDetailsDialog> createState() =>
      _ReportDetailsDialogState();
}

class _ReportDetailsDialogState
    extends State<_ReportDetailsDialog> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  late final TextEditingController
  _titleController;

  late final TextEditingController
  _hospitalController;

  late final TextEditingController
  _descriptionController;

  // =========================================================
  // STATE
  // =========================================================

  late String _selectedType;
  late DateTime _selectedDate;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
          text: widget.suggestedTitle,
        );

    _hospitalController =
        TextEditingController();

    _descriptionController =
        TextEditingController();

    _selectedType =
        widget.selectedType;

    _selectedDate =
        widget.selectedDate;
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _hospitalController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // =========================================================
  // CANCEL
  //
  // IMPORTANT:
  //
  // Remove focus BEFORE removing the dialog.
  //
  // This gives Flutter's EditableText / keyboard / focus
  // system a clean lifecycle.
  // =========================================================

  void _cancel() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop();
  }

  // =========================================================
  // SAVE
  // =========================================================

  void _save() {
    final title =
    _titleController.text.trim();

    if (title.isEmpty) {
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a report title.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final result =
    _ReportFormResult(
      title: title,
      hospital:
      _hospitalController.text,
      type: _selectedType,
      description:
      _descriptionController.text,
      date: _selectedDate,
    );

    // Remove keyboard/focus before closing.
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(result);
  }

  // =========================================================
  // SELECT DATE
  // =========================================================

  Future<void> _selectDate() async {
    // Remove focus before opening date picker.
    FocusScope.of(context).unfocus();

    final date =
    await showDatePicker(
      context: context,
      initialDate:
      _selectedDate,
      firstDate:
      DateTime(1900),
      lastDate:
      DateTime.now(),
    );

    if (!mounted || date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(
      DateTime date,
      ) {
    final month =
    date.month
        .toString()
        .padLeft(2, '0');

    final day =
    date.day
        .toString()
        .padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return AlertDialog(
      title:
      const Text(
        'Report Details',
      ),

      content:
      SingleChildScrollView(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            // -------------------------------------------------
            // ATTACHMENT
            // -------------------------------------------------

            if (widget.filePaths
                .isNotEmpty)
              _buildAttachmentInfo(),

            // -------------------------------------------------
            // TITLE
            // -------------------------------------------------

            TextField(
              controller:
              _titleController,
              textInputAction:
              TextInputAction.next,
              decoration:
              const InputDecoration(
                labelText:
                'Report Title',
                hintText:
                'e.g. Complete Blood Count',
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // -------------------------------------------------
            // HOSPITAL
            // -------------------------------------------------

            TextField(
              controller:
              _hospitalController,
              textInputAction:
              TextInputAction.next,
              decoration:
              const InputDecoration(
                labelText:
                'Hospital / Clinic',
                hintText:
                'e.g. City Diagnostics',
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // -------------------------------------------------
            // TYPE
            // -------------------------------------------------

            DropdownButtonFormField<
                String>(
              initialValue:
              _selectedType,
              decoration:
              const InputDecoration(
                labelText:
                'Report Type',
              ),
              items: const [
                DropdownMenuItem(
                  value:
                  'Lab Report',
                  child: Text(
                    'Lab Report',
                  ),
                ),
                DropdownMenuItem(
                  value:
                  'Prescription',
                  child: Text(
                    'Prescription',
                  ),
                ),
                DropdownMenuItem(
                  value:
                  'Imaging',
                  child: Text(
                    'Imaging',
                  ),
                ),
                DropdownMenuItem(
                  value:
                  'Consultation',
                  child: Text(
                    'Consultation',
                  ),
                ),
                DropdownMenuItem(
                  value:
                  'Other',
                  child: Text(
                    'Other',
                  ),
                ),
              ],
              onChanged:
                  (value) {
                if (value == null) {
                  return;
                }

                FocusScope.of(context)
                    .unfocus();

                setState(() {
                  _selectedType =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 14,
            ),

            // -------------------------------------------------
            // DESCRIPTION
            // -------------------------------------------------

            TextField(
              controller:
              _descriptionController,
              maxLines: 3,
              textInputAction:
              TextInputAction.done,
              decoration:
              const InputDecoration(
                labelText:
                'Description',
                hintText:
                'Optional description',
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // -------------------------------------------------
            // DATE
            // -------------------------------------------------

            ListTile(
              contentPadding:
              EdgeInsets.zero,
              leading:
              const Icon(
                Icons
                    .calendar_today_outlined,
              ),
              title:
              const Text(
                'Report Date',
              ),
              subtitle:
              Text(
                _formatDate(
                  _selectedDate,
                ),
              ),
              trailing:
              const Icon(
                Icons
                    .chevron_right_rounded,
              ),
              onTap:
              _selectDate,
            ),
          ],
        ),
      ),

      actions: [
        // -----------------------------------------------------
        // CANCEL
        // -----------------------------------------------------

        TextButton(
          onPressed:
          _cancel,
          child:
          const Text(
            'Cancel',
          ),
        ),

        // -----------------------------------------------------
        // SAVE
        // -----------------------------------------------------

        ElevatedButton(
          onPressed:
          _save,
          child:
          const Text(
            'Save Report',
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ATTACHMENT INFO
  // =========================================================

  Widget _buildAttachmentInfo() {
    final count =
        widget.filePaths.length;

    final isPdf =
        widget.filePaths.length == 1 &&
            widget.filePaths.first
                .toLowerCase()
                .endsWith('.pdf');

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(12),
      decoration:
      BoxDecoration(
        color: AppColors
            .lightViolet
            .withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPdf
                ? Icons
                .picture_as_pdf_outlined
                : Icons
                .attach_file_rounded,
            color:
            AppColors.primary,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              isPdf
                  ? 'Scanned PDF attached'
                  : count == 1
                  ? '1 file attached'
                  : '$count files attached',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}