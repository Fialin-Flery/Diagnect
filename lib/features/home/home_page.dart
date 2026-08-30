import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/features/auth/login_page.dart';
import 'package:diagnect/features/reports/add_report_page.dart';
import 'package:diagnect/features/reports/reports_page.dart';
import 'package:diagnect/models/report_model.dart';
import 'package:diagnect/services/auth_manager.dart';
import 'package:diagnect/features/privacy/privacy_access_page.dart';
import 'package:diagnect/features/profile/profile_page.dart';
import 'package:diagnect/features/qr_scan/qr_scanner_widget.dart';
import 'package:diagnect/features/medical_history/medical_history_page.dart';
import 'package:diagnect/models/medical_history_model.dart';
import 'package:diagnect/services/diagnect_session_service.dart';
import 'package:diagnect/services/sharing_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.verificationId,
    this.status,
  });

  final String? verificationId;
  final String? status;

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  int _selectedIndex = 0;


  final SharingService _sharingService =
      SharingService.instance;

  final AuthManager _authManager =
      AuthManager.instance;

  Map<String, dynamic>? _profile;

  List<ReportModel> _reports = [];

  MedicalHistoryModel? _medicalHistory;

  bool _loadingMedicalHistory = true;

  bool _loadingProfile = true;

  bool _loadingReports = true;

  final List<String> _titles = const [
    'Home',
    'Scan QR',
    'Add Report',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();

    _loadProfile();
    _loadReports();
    _loadMedicalHistory();

    _sharingService.addListener(
      _onSharingSessionChanged,
    );
  }

  void _onSharingSessionChanged() {
    if (!mounted) {
      return;
    }

    debugPrint(
      'HomePage: sharing session changed.',
    );

    setState(() {});
  }

  @override
  void dispose() {
    _sharingService.removeListener(
      _onSharingSessionChanged,
    );

    super.dispose();
  }

  // =========================================================
  // PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    final localProfile =
    await _authManager.getLocalProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = localProfile;
      _loadingProfile = false;
    });

    try {
      final remoteProfile =
      await _authManager.fetchProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = remoteProfile;
      });
    } catch (e) {
      debugPrint(
        'Background profile sync failed: $e',
      );
    }
  }

  // =========================================================
// HANDLE DOCTOR QR
// =========================================================

  Future<void> _handleQrScanned(
      String qrText,
      ) async {
    debugPrint(
      '========================================',
    );

    debugPrint(
      'Handling doctor QR...',
    );

    debugPrint(
      'QR: $qrText',
    );

    debugPrint(
      '========================================',
    );

    if (!mounted) {
      return;
    }

    // =======================================================
    // VALIDATE QR
    //
    // SharingService is responsible for parsing the QR.
    // The expected format is:
    //
    // diagnect://patient-connect/<room_id>?token=<patient_token>
    //
    // Do not manually extract roomId here.
    // =======================================================

    try {
      debugPrint(
        'Joining sharing session...',
      );

      final result =
      await _sharingService.joinSession(
        qrText,
      );

      debugPrint(
        'Sharing session joined successfully.',
      );

      debugPrint(
        'Join response: $result',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Connected to doctor. Your medical records are now available for consultation.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      _selectPage(0);

    } catch (e, stackTrace) {

      debugPrint(
        'Unable to join sharing session: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to connect to doctor: $e',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }

    // =======================================================
    // CHECK AUTHENTICATED SESSION
    // =======================================================

    final token =
    await _authManager.getAccessToken();

    if (!mounted) {
      return;
    }

    if (token == null ||
        token.isEmpty) {
      debugPrint(
        'Cannot join sharing session: '
            'no access token.',
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Your session has expired. Please login again.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // =======================================================
    // JOIN SHARING SESSION
    //
    // IMPORTANT:
    //
    // SharingService.joinSession() accepts the COMPLETE
    // QR string as a positional argument.
    //
    // It internally:
    //
    // 1. Parses the QR
    // 2. Extracts room_id
    // 3. Extracts patient_token
    // 4. Calls /sharing/join
    // 5. Stores the sharing session information
    // 6. Opens the sharing WebSocket
    // 7. Sends patient data
    //
    // Therefore DO NOT call connectWebSocket() here.
    // =======================================================

    try {
      debugPrint(
        'Joining sharing session...',
      );

      final result =
      await _sharingService.joinSession(
        qrText,
      );

      debugPrint(
        'Sharing session joined successfully.',
      );

      debugPrint(
        'Join response: $result',
      );

      if (!mounted) {
        return;
      }

      // =====================================================
      // SESSION IS NOW ACTIVE
      //
      // SharingService.joinSession() already calls connect().
      //
      // The separate DiagnectSessionService is responsible
      // for the doctor-session WebSocket/event state.
      // =====================================================

      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Connected to doctor. Your medical records are now available for consultation.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      // =====================================================
      // RETURN TO HOME
      // =====================================================

      _selectPage(0);
    } catch (e, stackTrace) {
      debugPrint(
        'Unable to join sharing session: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to connect to doctor: '
                '${e.toString().replaceFirst(
              'Exception: ',
              '',
            )}',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // REPORTS
  // =========================================================

  Future<void> _loadReports() async {
    try {
      final reports =
      await _authManager.getReports();

      if (!mounted) {
        return;
      }

      setState(() {
        _reports = reports;
        _loadingReports = false;
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
        _loadingReports = false;
      });
    }
  }

  // =========================================================
  // MEDICAL HISTORY
  // =========================================================

  Future<void> _loadMedicalHistory() async {

    /*
     * First load the local copy so the UI can respond
     * immediately.
     */

    try {

      final localHistory =
      await _authManager
          .getLocalMedicalHistory();

      if (!mounted) {
        return;
      }

      setState(() {

        _medicalHistory =
            localHistory;

        _loadingMedicalHistory =
        false;
      });

    } catch (e) {

      debugPrint(
        'Unable to load local medical history: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _medicalHistory = null;
        _loadingMedicalHistory = false;
      });
    }

    /*
     * Then fetch the authoritative backend copy.
     */

    try {

      final remoteHistory =
      await _authManager
          .fetchMedicalHistory();

      if (!mounted) {
        return;
      }

      setState(() {

        _medicalHistory =
            remoteHistory;

      });

    } catch (e) {

      debugPrint(
        'Medical history background sync failed: $e',
      );
    }
  }

  bool get _medicalHistoryCompleted {

    return _medicalHistory != null &&
        _medicalHistory!.completed;
  }

  // =========================================================
  // PROFILE HELPERS
  // =========================================================

  String get _profileName {
    if (_loadingProfile) {
      return 'Loading...';
    }

    return _profile?['name']
        ?.toString() ??
        'User';
  }

  String get _profileDob {
    return _profile?['date_of_birth']
        ?.toString() ??
        'Not available';
  }

  String get _profileBloodGroup {
    return _profile?['blood_group']
        ?.toString() ??
        'Not available';
  }

  String get _profileAbhaNumber {
    return _profile?['abha_number']
        ?.toString() ??
        'Not linked';
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _selectPage(int index) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    /*
   * Refresh reports whenever the user navigates
   * to Home or Reports.
   */
    if (index == 0 || index == 3) {
      _loadReports();
    }
  }

  void _selectDrawerItem(
      int index,
      ) {
    Navigator.pop(context);

    setState(() {
      _selectedIndex = index;
    });
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout of Diagnect?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                try {
                  await _authManager
                      .logout();
                } catch (e) {
                  debugPrint(
                    'Logout error: $e',
                  );
                }

                if (!mounted) {
                  return;
                }

                Navigator.of(context)
                    .pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) =>
                    const LoginPage(),
                  ),
                      (route) => false,
                );
              },
              child:
              const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style:
          const TextStyle(
            color:
            AppColors.primaryText,
            fontSize: 21,
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [

          Stack(
            clipBehavior:
            Clip.none,

            children: [

              IconButton(
                tooltip:
                'Notifications',

                onPressed: () {

                  if (!_loadingMedicalHistory &&
                      !_medicalHistoryCompleted) {

                    _openMedicalHistory();

                  } else {

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content:
                        Text(
                          'You have no new notifications.',
                        ),
                        behavior:
                        SnackBarBehavior.floating,
                      ),
                    );
                  }
                },

                icon:
                const Icon(
                  Icons
                      .notifications_none_rounded,
                  color:
                  AppColors.primaryText,
                ),
              ),

              if (!_loadingMedicalHistory &&
                  !_medicalHistoryCompleted)

                Positioned(
                  right: 7,
                  top: 7,

                  child:
                  Container(
                    width: 9,
                    height: 9,

                    decoration:
                    const BoxDecoration(
                      color:
                      AppColors.primary,
                      shape:
                      BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            width: 8,
          ),
        ],

    ),

      drawer:
      _buildDrawer(),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),

          _buildScanPage(),

          AddReportPage(
            onReportChanged:
            _loadReports,
          ),

          ReportsPage(
            onAddReport: () {
              _selectPage(2);
            },
            onReportChanged: _loadReports,
          ),
        ],
      ),

      bottomNavigationBar:
      NavigationBar(
        selectedIndex:
        _selectedIndex,
        onDestinationSelected:
        _selectPage,
        backgroundColor:
        AppColors.surface,
        indicatorColor:
        AppColors.lightViolet
            .withValues(
          alpha: 0.25,
        ),
        destinations:
        const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
            Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons
                  .qr_code_scanner_outlined,
            ),
            selectedIcon:
            Icon(
              Icons
                  .qr_code_scanner_rounded,
            ),
            label: 'Scan QR',
          ),
          NavigationDestination(
            icon: Icon(
              Icons
                  .add_circle_outline_rounded,
            ),
            selectedIcon:
            Icon(
              Icons
                  .add_circle_rounded,
            ),
            label: 'Add Report',
          ),
          NavigationDestination(
            icon: Icon(
              Icons
                  .description_outlined,
            ),
            selectedIcon:
            Icon(
              Icons
                  .description_rounded,
            ),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HOME
  // =========================================================

  Widget _buildHomePage() {
    final recentReports =
    _reports.take(2).toList();

    final diagnosisCount =
        _reports
            .where(
              (report) =>
          report.type ==
              'Consultation',
        )
            .length;

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          28,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            if (!_loadingMedicalHistory &&
                !_medicalHistoryCompleted) ...[

              _buildMedicalHistoryNotification(),

              const SizedBox(
                height: 20,
              ),
            ],

            Text(
              'Good morning, $_profileName',
              style:
              const TextStyle(
                fontSize: 26,
                fontWeight:
                FontWeight.w700,
                color:
                AppColors.primaryText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Your health information, securely in one place.',
              style:
              TextStyle(
                fontSize: 14,
                color:
                AppColors.secondaryText,
              ),
            ),

            const SizedBox(height: 24),

            _buildProfileCard(),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child:
                  _buildStatCard(
                    icon: Icons
                        .description_outlined,
                    title: 'Reports',
                    value:
                    _loadingReports
                        ? '—'
                        : _reports.length
                        .toString(),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                  _buildStatCard(
                    icon: Icons
                        .medical_information_outlined,
                    title:
                    'Diagnoses',
                    value:
                    _loadingReports
                        ? '—'
                        : diagnosisCount
                        .toString(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Quick Actions',
              style:
              TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
                color:
                AppColors.primaryText,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child:
                  _buildQuickAction(
                    icon: Icons
                        .qr_code_scanner_rounded,
                    title:
                    'Scan Doctor QR',
                    onTap: () {
                      _selectPage(1);
                    },
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                  _buildQuickAction(
                    icon: Icons
                        .upload_file_rounded,
                    title:
                    'Add Report',
                    onTap: () {
                      _selectPage(2);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              children: [
                const Text(
                  'Recent Medical Records',
                  style:
                  TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppColors.primaryText,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    _selectPage(3);
                  },
                  child:
                  const Text(
                    'View all',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_loadingReports)
              const Center(
                child: Padding(
                  padding:
                  EdgeInsets.all(20),
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (recentReports.isEmpty)
              _buildEmptyReportsCard()
            else
              ...recentReports.map(
                    (report) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child:
                    _buildReportCard(
                      report,
                    ),
                  );
                },
              ),

            const SizedBox(height: 18),

            const Text(
              'Active Access',
              style:
              TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
                color:
                AppColors.primaryText,
              ),
            ),

            const SizedBox(height: 14),

            _buildActiveAccessCard(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE CARD
  // =========================================================

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.lightViolet,
          ],
        ),
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary
                .withValues(
              alpha: 0.15,
            ),
            blurRadius: 18,
            offset:
            const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white
                      .withValues(
                    alpha: 0.2,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                const Icon(
                  Icons
                      .person_rounded,
                  color:
                  Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      _profileName,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 19,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    const Text(
                      'Health Profile',
                      style:
                      TextStyle(
                        color:
                        Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.18,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child:
                const Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .verified_rounded,
                      color:
                      Colors.white,
                      size: 15,
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      'Verified',
                      style:
                      TextStyle(
                        color:
                        Colors.white,
                        fontSize: 11,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          Container(
            height: 1,
            color: Colors.white
                .withValues(
              alpha: 0.2,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Expanded(
                child:
                _profileInfo(
                  'Blood Group',
                  _profileBloodGroup,
                ),
              ),
              Expanded(
                child:
                _profileInfo(
                  'Date of Birth',
                  _profileDob,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          _profileInfo(
            'ABHA',
            _profileAbhaNumber,
          ),
        ],
      ),
    );
  }

  Widget _profileInfo(
      String title,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style:
          const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        AppColors.surface,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color:
              AppColors.lightViolet
                  .withValues(
                alpha: 0.15,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
              AppColors.primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                value,
                style:
                const TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.primaryText,
                ),
              ),
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 12,
                  color:
                  AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // QUICK ACTION
  // =========================================================

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration:
        BoxDecoration(
          color:
          AppColors.surface,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Colors.grey
                .withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
              BoxDecoration(
                color: AppColors
                    .primary
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  13,
                ),
              ),
              child: Icon(
                icon,
                color:
                AppColors.primary,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              title,
              style:
              const TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
                color:
                AppColors.primaryText,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'Get started',
              style:
              TextStyle(
                fontSize: 12,
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
  // REPORT CARD
  // =========================================================

  Widget _buildReportCard(
      ReportModel report,
      ) {
    final hospital =
        report.hospital ??
            'Personal Record';

    return InkWell(
      onTap: () {
        _showReportDetails(
          report,
        );
      },
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child: Container(
        padding:
        const EdgeInsets.all(16),
        decoration:
        BoxDecoration(
          color:
          AppColors.surface,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Colors.grey
                .withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
              BoxDecoration(
                color:
                AppColors.lightViolet
                    .withValues(
                  alpha: 0.15,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  13,
                ),
              ),
              child: Icon(
                _reportIcon(
                  report.type,
                ),
                color:
                AppColors.primary,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    hospital,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color:
                      AppColors.primaryText,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

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

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    report.description ??
                        report.title,
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

                  const SizedBox(
                    height: 5,
                  ),

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

            const Icon(
              Icons.chevron_right_rounded,
              color:
              AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // REPORT DETAILS
  // =========================================================

  void _showReportDetails(
      ReportModel report,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          Text(report.title),
          content:
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _detailRow(
                  'Type',
                  report.type,
                ),

                const SizedBox(
                  height: 12,
                ),

                _detailRow(
                  'Date',
                  _displayDate(
                    report.reportDate,
                  ),
                ),

                if (report.hospital != null &&
                    report.hospital!.isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  _detailRow(
                    'Hospital',
                    report.hospital!,
                  ),
                ],

                if (report.description != null &&
                    report.description!.isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  _detailRow(
                    'Description',
                    report.description!,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
      String title,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          const TextStyle(
            fontSize: 12,
            color:
            AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:
          const TextStyle(
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

  // =========================================================
  // EMPTY REPORTS
  // =========================================================

  Widget _buildEmptyReportsCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration:
      BoxDecoration(
        color:
        AppColors.surface,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
            BoxDecoration(
              color: AppColors
                  .lightViolet
                  .withValues(
                alpha: 0.15,
              ),
              shape:
              BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .description_outlined,
              color:
              AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'No reports yet',
            style:
            TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
              color:
              AppColors.primaryText,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Add your first medical report '
                'to start building your health history.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 12,
              height: 1.5,
              color:
              AppColors.secondaryText,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          OutlinedButton.icon(
            onPressed: () {
              _selectPage(2);
            },
            icon: const Icon(
              Icons.add,
            ),
            label:
            const Text(
              'Add Report',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVE ACCESS
  // =========================================================

  Widget _buildActiveAccessCard() {

    final session = _sharingService.activeSession;

    // =======================================================
    // NO ACTIVE SESSION
    // =======================================================

    if (session == null) {

      return Container(
        width: double.infinity,

        padding:
        const EdgeInsets.all(20),

        decoration: BoxDecoration(
          borderRadius:
          BorderRadius.circular(20),

          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              'No Active Session',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Scan a doctor\'s QR code '
                  'to share your medical records.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // SESSION INFORMATION
    // =======================================================

    final doctor =
    session['doctor'];

    String doctorName =
        'Doctor';

    String hospital =
        'Hospital';

    if (doctor is Map<String, dynamic>) {

      doctorName =
          doctor['name']
              ?.toString()
              ?? 'Doctor';

      hospital =
          doctor['hospital']
              ?.toString()
              ?? 'Hospital';
    }

    final expiresAt =
    session['expires_at']
        ?.toString();

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color: Colors.deepPurple.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Container(
                width: 10,
                height: 10,

                decoration:
                const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Text(
                'Active Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            doctorName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            hospital,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (expiresAt != null)
            Text(
              'Session expires: $expiresAt',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // SCAN PAGE
  // =========================================================

  Widget _buildScanPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),

          QrScannerWidget(
            isActive: _selectedIndex == 1,
            onQrScanned: (qrText) async {
              debugPrint(
                'HomePage received QR text: $qrText',
              );

              await _handleQrScanned(
                qrText,
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'Scan Doctor QR',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Scan a doctor or hospital QR code to review '
                'and approve access to your medical records.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'Your medical records will never be shared '
                'without your approval.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DRAWER
  // =========================================================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor:
      AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                24,
              ),
              decoration:
              BoxDecoration(
                color:
                AppColors.background,
                border:
                Border(
                  bottom:
                  BorderSide(
                    color: Colors.grey
                        .withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration:
                    BoxDecoration(
                      color:
                      AppColors.primary,
                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),
                    ),
                    child:
                    const Center(
                      child: Text(
                        'F',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 28,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Text(
                    _profileName,
                    style:
                    const TextStyle(
                      color:
                      AppColors.primaryText,
                      fontSize: 19,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  const Text(
                    'Personal Medical Wallet',
                    style:
                    TextStyle(
                      color:
                      AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding:
                const EdgeInsets
                    .symmetric(
                  vertical: 12,
                ),
                children: [
                  _drawerItem(
                    icon: Icons
                        .home_outlined,
                    selectedIcon:
                    Icons.home_rounded,
                    title: 'Home',
                    index: 0,
                  ),

                  _drawerItem(
                    icon: Icons
                        .qr_code_scanner_outlined,
                    selectedIcon:
                    Icons
                        .qr_code_scanner_rounded,
                    title:
                    'Scan Doctor QR',
                    index: 1,
                  ),

                  _drawerItem(
                    icon: Icons
                        .add_circle_outline_rounded,
                    selectedIcon:
                    Icons
                        .add_circle_rounded,
                    title:
                    'Add Medical Report',
                    index: 2,
                  ),

                  _drawerItem(
                    icon: Icons
                        .description_outlined,
                    selectedIcon:
                    Icons
                        .description_rounded,
                    title: 'Reports',
                    index: 3,
                  ),

                  const Divider(
                    height: 32,
                    indent: 20,
                    endIndent: 20,
                  ),


                  ListTile(
                    leading: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primaryText,
                    ),
                    title: const Text(
                      'My Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                    ),
                    onTap: () async {
                      Navigator.pop(context);

                      final updatedProfile =
                      await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            onProfileUpdated: (profile) {
                              if (!mounted) {
                                return;
                              }

                              setState(() {
                                _profile = profile;
                              });
                            },
                          ),
                        ),
                      );

                      if (!mounted ||
                          updatedProfile == null) {
                        return;
                      }

                      setState(() {
                        _profile = updatedProfile;
                      });
                    },
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.primaryText,
                    ),

                    title: const Text(
                      'Medical History',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),

                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                    ),

                    onTap: () async {

                      Navigator.pop(context);

                      await _openMedicalHistory();
                    },
                  ),


                  ListTile(
                    leading: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primaryText,
                    ),
                    title: const Text(
                      'Privacy & Access',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyAccessPage(),
                        ),
                      );
                    },
                  ),


                ],
              ),
            ),

            Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                8,
                16,
                20,
              ),
              child: ListTile(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                leading:
                const Icon(
                  Icons
                      .logout_rounded,
                  color:
                  AppColors.error,
                ),
                title:
                const Text(
                  'Logout',
                  style:
                  TextStyle(
                    color:
                    AppColors.error,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
  }) {
    final selected =
        _selectedIndex == index;

    return Padding(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 12,
        vertical: 2,
      ),
      child: ListTile(
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
        selected: selected,
        selectedTileColor:
        AppColors.lightViolet
            .withValues(
          alpha: 0.15,
        ),
        leading: Icon(
          selected
              ? selectedIcon
              : icon,
          color: selected
              ? AppColors.primary
              : AppColors.primaryText,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected
                ? AppColors.primary
                : AppColors.primaryText,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        onTap: () {
          _selectDrawerItem(
            index,
          );
        },
      ),
    );
  }

  Widget _comingSoonDrawerItem({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
        AppColors.primaryText,
      ),
      title: Text(
        title,
        style:
        const TextStyle(
          fontWeight:
          FontWeight.w500,
          color:
          AppColors.primaryText,
        ),
      ),
      trailing:
      const Icon(
        Icons
            .chevron_right_rounded,
        color:
        AppColors.secondaryText,
      ),
      onTap: () {
        Navigator.pop(context);

        _showComingSoon(
          title,
        );
      },
    );
  }

  // =========================================================
  // Medical History card
  // =========================================================

  Widget _buildMedicalHistoryNotification() {
    return Container(

      width:
      double.infinity,

      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(

        color:
        AppColors.lightViolet
            .withValues(
          alpha: 0.12,
        ),

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color:
          AppColors.primary
              .withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child:
      Row(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Container(

            width: 44,

            height: 44,

            decoration:
            BoxDecoration(

              color:
              AppColors.primary
                  .withValues(
                alpha: 0.12,
              ),

              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),

            child:
            const Icon(
              Icons.medical_information_rounded,
              color:
              AppColors.primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(

            child:
            Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const Text(
                  'Complete your Medical History',
                  style:
                  TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppColors.primaryText,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'Add your height, weight, allergies '
                      'and other important health information.',
                  style:
                  TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color:
                    AppColors.secondaryText,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                TextButton(

                  onPressed:
                  _openMedicalHistory,

                  style:
                  TextButton.styleFrom(
                    padding:
                    EdgeInsets.zero,
                    minimumSize:
                    Size.zero,
                    tapTargetSize:
                    MaterialTapTargetSize
                        .shrinkWrap,
                  ),

                  child:
                  const Text(
                    'Complete Now →',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _openMedicalHistory() async {

    /*
     * Refresh from backend before opening.
     *
     * This is useful if the medical history was changed
     * somewhere else.
     */

    try {

      final latestHistory =
      await _authManager
          .fetchMedicalHistory();

      if (mounted) {

        setState(() {

          _medicalHistory =
              latestHistory;

        });
      }

    } catch (e) {

      debugPrint(
        'Unable to refresh medical history before opening: $e',
      );
    }

    if (!mounted) {
      return;
    }

    final result =
    await Navigator.push<
        MedicalHistoryModel>(
      context,

      MaterialPageRoute(
        builder: (_) =>
            MedicalHistoryPage(
              initialHistory:
              _medicalHistory,

              onSave:
              _saveMedicalHistory,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null) {

      setState(() {

        _medicalHistory =
            result;

      });
    }
  }

  Future<bool> _saveMedicalHistory(
      MedicalHistoryModel history,
      ) async {

    try {

      final success =
      await _authManager
          .saveMedicalHistory(
        history,
      );

      if (!mounted) {
        return success;
      }

      if (success) {

        /*
         * Immediately update HomePage.
         *
         * This makes the notification disappear
         * as soon as the user successfully saves.
         */

        setState(() {

          _medicalHistory =
              MedicalHistoryModel(
                id:
                history.id,

                userId:
                history.userId,

                heightCm:
                history.heightCm,

                weightKg:
                history.weightKg,

                sex:
                history.sex,

                allergies:
                List<String>.from(
                  history.allergies,
                ),

                chronicConditions:
                history.chronicConditions,

                currentMedications:
                history.currentMedications,

                hivAids:
                history.hivAids,

                smoking:
                history.smoking,

                alcohol:
                history.alcohol,

                emergencyContact:
                history.emergencyContact,

                additionalNotes:
                history.additionalNotes,

                completed:
                true,
              );
        });
      }

      return success;

    } catch (e) {

      debugPrint(
        'Medical history save failed: $e',
      );

      if (mounted) {

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content:
            Text(
              e.toString()
                  .replaceFirst(
                'Exception: ',
                '',
              ),
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );
      }

      return false;
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
  // DATE
  // =========================================================

  String _displayDate(
      String value,
      ) {
    try {
      final date =
      DateTime.parse(value);

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
  // COMING SOON
  // =========================================================

  void _showComingSoon(
      String feature,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be available here.',
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }
}