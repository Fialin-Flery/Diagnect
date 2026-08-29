import 'dart:io';

import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/models/report_model.dart';
import 'package:diagnect/services/auth_manager.dart';
import 'package:diagnect/features/reports/pdf_viewer_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    this.onAddReport,
    this.onReportChanged,
  });

  final VoidCallback? onAddReport;
  final VoidCallback? onReportChanged;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final AuthManager _authManager = AuthManager.instance;

  final TextEditingController _searchController =
  TextEditingController();

  List<ReportModel> _reports = [];

  bool _loading = true;

  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Lab Report',
    'Prescription',
    'Imaging',
    'Consultation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD REPORTS
  // =========================================================

  Future<void> _loadReports() async {
    try {
      final reports = await _authManager.getReports();

      if (!mounted) {
        return;
      }

      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Unable to load reports: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reports = [];
        _loading = false;
      });
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> refreshReports() async {
    await _loadReports();
  }

  // =========================================================
  // FILTERED REPORTS
  // =========================================================

  List<ReportModel> get _filteredReports {
    final search = _searchController.text
        .trim()
        .toLowerCase();

    return _reports.where((report) {
      final matchesSearch =
          search.isEmpty ||
              report.title
                  .toLowerCase()
                  .contains(search) ||
              (report.hospital ?? '')
                  .toLowerCase()
                  .contains(search) ||
              (report.description ?? '')
                  .toLowerCase()
                  .contains(search);

      final matchesType =
          _selectedFilter == 'All' ||
              report.type == _selectedFilter;

      return matchesSearch && matchesType;
    }).toList();
  }

  // =========================================================
  // SHOW REPORT DETAILS
  // =========================================================

  void _showReportDetails(
      ReportModel report,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return _ReportDetailsDialog(
          report: report,
          onDelete: () async {
            await _deleteReport(report);
          },
        );
      },
    );
  }

  // =========================================================
  // DELETE REPORT
  // =========================================================

  Future<void> _deleteReport(
      ReportModel report,
      ) async {
    if (report.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Report',
          ),
          content: Text(
            'Are you sure you want to delete '
                '"${report.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _authManager.deleteReport(
        report.id!,
      );

      /*
       * IMPORTANT:
       * Update this page immediately.
       * No restart required.
       */

      if (!mounted) {
        return;
      }

      setState(() {
        _reports.removeWhere(
              (item) => item.id == report.id,
        );
      });

      widget.onReportChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report deleted.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete report: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // DATE
  // =========================================================

  String _displayDate(
      String value,
      ) {
    try {
      final date = DateTime.parse(value);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  // =========================================================
  // REPORT ICON
  // =========================================================

  IconData _reportIcon(
      String type,
      ) {
    switch (type) {
      case 'Lab Report':
        return Icons.science_outlined;

      case 'Prescription':
        return Icons.medication_outlined;

      case 'Imaging':
        return Icons.image_outlined;

      case 'Consultation':
        return Icons.local_hospital_outlined;

      default:
        return Icons.description_outlined;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final reports = _filteredReports;

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            const Text(
              'Your Reports',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'All your uploaded and received '
                  'medical reports.\nPlease refresh if file is not found..',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------
            // SEARCH
            // -------------------------------------------------

            TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search reports',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // -------------------------------------------------
            // FILTERS
            // -------------------------------------------------

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      right: 8,
                    ),
                    child: FilterChip(
                      label: Text(filter),
                      selected:
                      _selectedFilter == filter,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor:
                      AppColors.lightViolet
                          .withValues(
                        alpha: 0.25,
                      ),
                      checkmarkColor:
                      AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------
            // CONTENT
            // -------------------------------------------------

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (reports.isEmpty)
              _buildEmptyState()
            else
              ...reports.map(
                    (report) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                    _buildReportCard(report),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // REPORT CARD
  // =========================================================

  Widget _buildReportCard(
      ReportModel report,
      ) {
    return InkWell(
      onTap: () {
        _showReportDetails(report);
      },
      borderRadius:
      BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------
            // PREVIEW
            // -------------------------------------------------

            _buildReportPreview(report),

            const SizedBox(width: 14),

            // -------------------------------------------------
            // DETAILS
            // -------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color:
                      AppColors.primaryText,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    report.type,
                    style:
                    const TextStyle(
                      fontSize: 13,
                      color:
                      AppColors.primary,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    report.hospital ??
                        'Personal Record',
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      AppColors.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _displayDate(
                      report.reportDate,
                    ),
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------
            // DELETE
            // -------------------------------------------------

            IconButton(
              onPressed: () {
                _deleteReport(report);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color:
                AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // REPORT PREVIEW
  // =========================================================

  Widget _buildReportPreview(
      ReportModel report,
      ) {
    String? imagePath;

    for (final path in report.filePaths) {
      final lower = path.toLowerCase();

      if (lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp')) {
        imagePath = path;
        break;
      }
    }

    if (imagePath != null) {
      final file = File(imagePath);

      if (file.existsSync()) {
        return ClipRRect(
          borderRadius:
          BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 58,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) {
              return _fileIcon();
            },
          ),
        );
      }
    }

    if (report.fileType == 'pdf' ||
        report.fileType == 'scan_pdf') {
      return Container(
        width: 58,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.lightViolet
              .withValues(alpha: 0.15),
          borderRadius:
          BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.picture_as_pdf_outlined,
          color: AppColors.primary,
          size: 30,
        ),
      );
    }

    return _fileIcon();
  }

  // =========================================================
  // FILE ICON
  // =========================================================

  Widget _fileIcon() {
    return Container(
      width: 58,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.lightViolet
            .withValues(alpha: 0.15),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.description_outlined,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.lightViolet
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'No reports yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Add your first medical report '
                'to start building your health history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color:
              AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: widget.onAddReport,
            icon: const Icon(Icons.add),
            label:
            const Text('Add Report'),
          ),
        ],
      ),
    );
  }
}


// =============================================================
// REPORT DETAILS DIALOG
//
// IMPORTANT:
// This class belongs in THIS SAME FILE:
//
// lib/features/reports/reports_page.dart
//
// Put it AFTER _ReportsPageState.
// =============================================================

class _ReportDetailsDialog extends StatefulWidget {
  const _ReportDetailsDialog({
    required this.report,
    required this.onDelete,
  });

  final ReportModel report;

  final Future<void> Function() onDelete;

  @override
  State<_ReportDetailsDialog> createState() =>
      _ReportDetailsDialogState();
}

class _ReportDetailsDialogState
    extends State<_ReportDetailsDialog> {

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _delete() async {
    Navigator.of(context).pop();

    await widget.onDelete();
  }

  // =========================================================
  // pdf viewer
  // =========================================================

  void _openPdf(
      String filePath,
      ) {
    final file =
    File(filePath);

    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF file could not be found.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          filePath: filePath,
          title: widget.report.title,
        ),
      ),
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  String _displayDate(
      String value,
      ) {
    try {
      final date = DateTime.parse(value);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final report = widget.report;

    return AlertDialog(
      title: Text(
        report.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),

      content: SizedBox(
        width: 500,

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // -------------------------------------------------
              // ATTACHMENTS
              // -------------------------------------------------

              if (report.filePaths.isNotEmpty)
                _buildAttachments(report),

              const SizedBox(height: 18),

              if (report.filePaths.any(
                    (path) => path.toLowerCase().endsWith('.pdf'),
              ))
                Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final pdfPath =
                        report.filePaths.firstWhere(
                              (path) =>
                              path.toLowerCase().endsWith('.pdf'),
                        );

                        _openPdf(pdfPath);
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                      ),
                      label: const Text(
                        'Open PDF',
                      ),
                    ),
                  ),
                ),

              // -------------------------------------------------
              // TYPE
              // -------------------------------------------------

              _detail(
                'Type',
                report.type,
              ),

              const SizedBox(height: 14),

              // -------------------------------------------------
              // DATE
              // -------------------------------------------------

              _detail(
                'Date',
                _displayDate(
                  report.reportDate,
                ),
              ),

              // -------------------------------------------------
              // HOSPITAL
              // -------------------------------------------------

              if (report.hospital != null &&
                  report.hospital!.isNotEmpty) ...[
                const SizedBox(height: 14),

                _detail(
                  'Hospital / Clinic',
                  report.hospital!,
                ),
              ],

              // -------------------------------------------------
              // DESCRIPTION
              // -------------------------------------------------

              if (report.description != null &&
                  report.description!.isNotEmpty) ...[
                const SizedBox(height: 14),

                _detail(
                  'Description',
                  report.description!,
                ),
              ],
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Close',
          ),
        ),

        TextButton.icon(
          onPressed: _delete,
          icon: const Icon(
            Icons.delete_outline,
          ),
          label: const Text(
            'Delete',
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ATTACHMENTS
  // =========================================================

  Widget _buildAttachments(
      ReportModel report,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
            AppColors.primaryText,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 180,

          child: ListView.separated(
            scrollDirection:
            Axis.horizontal,

            itemCount:
            report.filePaths.length,

            separatorBuilder: (_, __) =>
            const SizedBox(width: 10),

            itemBuilder:
                (context, index) {
              final filePath =
              report.filePaths[index];

              return _buildAttachment(
                filePath,
                index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SINGLE ATTACHMENT
  // =========================================================

  Widget _buildAttachment(
      String filePath,
      int index,
      ) {
    final file =
    File(filePath);

    final lower =
    filePath.toLowerCase();

    final isImage =
        lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp');

    final isPdf =
    lower.endsWith('.pdf');

    return InkWell(
      onTap: isPdf
          ? () {
        _openPdf(filePath);
      }
          : null,
      borderRadius:
      BorderRadius.circular(12),
      child: Container(
        width: 150,
        decoration:
        BoxDecoration(
          color:
          AppColors.background,
          borderRadius:
          BorderRadius.circular(12),
          border:
          Border.all(
            color:
            Colors.grey.withValues(
              alpha: 0.15,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                  top:
                  Radius.circular(12),
                ),
                child:
                isImage &&
                    file.existsSync()
                    ? Image.file(
                  file,
                  width:
                  double.infinity,
                  fit:
                  BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) {
                    return _attachmentIcon(
                      Icons
                          .broken_image_outlined,
                    );
                  },
                )
                    : isPdf
                    ? Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    const Icon(
                      Icons
                          .picture_as_pdf_rounded,
                      size: 52,
                      color:
                      AppColors
                          .primary,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      'Open PDF',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight
                            .w600,
                        color:
                        AppColors
                            .primary,
                      ),
                    ),
                  ],
                )
                    : _attachmentIcon(
                  Icons
                      .description_outlined,
                ),
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.all(8),
              child: Text(
                isPdf
                    ? 'PDF'
                    : 'Page $index',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ATTACHMENT ICON
  // =========================================================

  Widget _attachmentIcon(
      IconData icon,
      ) {
    return Center(
      child: Icon(
        icon,
        size: 42,
        color: AppColors.primary,
      ),
    );
  }

  // =========================================================
  // DETAIL
  // =========================================================

  Widget _detail(
      String title,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color:
            AppColors.secondaryText,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
            FontWeight.w600,
            color:
            AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}