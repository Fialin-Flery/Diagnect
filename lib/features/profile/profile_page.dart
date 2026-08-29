import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/services/auth_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.onProfileUpdated,
  });

  final ValueChanged<Map<String, dynamic>>? onProfileUpdated;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthManager _authManager = AuthManager.instance;

  final TextEditingController _nameController =
  TextEditingController();

  String? _selectedBloodGroup;

  DateTime? _selectedDateOfBirth;

  String? _abhaNumber;

  bool _loading = true;
  bool _saving = false;

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    try {
      /*
       * Load local profile first so the page can appear
       * immediately even if the network is slow.
       */
      final localProfile =
      await _authManager.getLocalProfile();

      if (localProfile != null) {
        _applyProfile(localProfile);
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      /*
       * Then fetch the latest profile from the backend.
       */
      try {
        final remoteProfile =
        await _authManager.fetchProfile();

        _applyProfile(remoteProfile);

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint(
          'Unable to refresh profile: $e',
        );
      }
    } catch (e) {
      debugPrint(
        'Unable to load profile: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load your profile.',
      );
    }
  }

  // =========================================================
  // APPLY PROFILE
  // =========================================================

  void _applyProfile(
      Map<String, dynamic> profile,
      ) {
    final name =
    profile['name']?.toString();

    final bloodGroup =
    profile['blood_group']?.toString();

    final dateOfBirth =
    profile['date_of_birth']?.toString();

    final abhaNumber =
    profile['abha_number']?.toString();

    if (name != null) {
      _nameController.text = name;
    }

    if (bloodGroup != null &&
        _bloodGroups.contains(bloodGroup.toUpperCase())) {
      _selectedBloodGroup =
          bloodGroup.toUpperCase();
    }

    if (dateOfBirth != null &&
        dateOfBirth.isNotEmpty) {
      try {
        _selectedDateOfBirth =
            DateTime.parse(dateOfBirth);
      } catch (_) {
        _selectedDateOfBirth = null;
      }
    }

    _abhaNumber = abhaNumber;
  }

  // =========================================================
  // DATE DISPLAY
  // =========================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Select date of birth';
    }

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _apiDate(
      DateTime date,
      ) {
    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final initialDate =
        _selectedDateOfBirth ??
            DateTime(
              now.year - 18,
              now.month,
              now.day,
            );

    final firstDate =
    DateTime(
      1900,
      1,
      1,
    );

    final lastDate =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final selected =
    await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate)
          ? lastDate
          : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select date of birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDateOfBirth = selected;
    });
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _saveProfile() async {
    final name =
    _nameController.text.trim();

    if (name.length < 2) {
      _showError(
        'Please enter a valid name.',
      );
      return;
    }

    if (_selectedBloodGroup == null) {
      _showError(
        'Please select your blood group.',
      );
      return;
    }

    if (_selectedDateOfBirth == null) {
      _showError(
        'Please select your date of birth.',
      );
      return;
    }

    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final updatedProfile =
      await _authManager.updateProfile(
        name: name,
        dateOfBirth:
        _apiDate(
          _selectedDateOfBirth!,
        ),
        bloodGroup:
        _selectedBloodGroup!,
      );

      if (!mounted) {
        return;
      }

      widget.onProfileUpdated?.call(
        updatedProfile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(
        updatedProfile,
      );
    } catch (e) {
      debugPrint(
        'Unable to update profile: $e',
      );

      if (!mounted) {
        return;
      }

      _showError(
        _cleanErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String _cleanErrorMessage(
      Object error,
      ) {
    final message =
    error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
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
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color:
            AppColors.primaryText,
            fontSize: 21,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Personal Information',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildNameField(),

              const SizedBox(
                height: 16,
              ),

              _buildBloodGroupField(),

              const SizedBox(
                height: 16,
              ),

              _buildDateOfBirthField(),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'ABHA Information',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildAbhaCard(),

              const SizedBox(
                height: 32,
              ),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE HEADER
  // =========================================================

  Widget _buildProfileHeader() {
    final name =
    _nameController.text.trim();

    final initial =
    name.isNotEmpty
        ? name[0].toUpperCase()
        : 'U';

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
            color:
            AppColors.primary.withValues(
              alpha: 0.15,
            ),
            blurRadius: 18,
            offset:
            const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color:
              Colors.white.withValues(
                alpha: 0.20,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
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
                  name.isEmpty
                      ? 'Your Profile'
                      : name,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'Manage your personal health information',
                  style: TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle(
      String title,
      ) {
    return Text(
      title,
      style:
      const TextStyle(
        fontSize: 18,
        fontWeight:
        FontWeight.w700,
        color:
        AppColors.primaryText,
      ),
    );
  }

  // =========================================================
  // NAME
  // =========================================================

  Widget _buildNameField() {
    return TextField(
      controller:
      _nameController,
      textCapitalization:
      TextCapitalization.words,
      decoration:
      const InputDecoration(
        labelText: 'Full Name',
        hintText:
        'Enter your full name',
        prefixIcon:
        Icon(
          Icons.person_outline_rounded,
        ),
      ),
    );
  }

  // =========================================================
  // BLOOD GROUP
  // =========================================================

  Widget _buildBloodGroupField() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      decoration:
      const InputDecoration(
        labelText: 'Blood Group',
        prefixIcon:
        Icon(
          Icons.bloodtype_outlined,
        ),
      ),
      items:
      _bloodGroups.map(
            (group) {
          return DropdownMenuItem<String>(
            value: group,
            child: Text(group),
          );
        },
      ).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBloodGroup =
              value;
        });
      },
    );
  }

  // =========================================================
  // DATE OF BIRTH
  // =========================================================

  Widget _buildDateOfBirthField() {
    return InkWell(
      onTap:
      _selectDateOfBirth,
      borderRadius:
      BorderRadius.circular(12),
      child: InputDecorator(
        decoration:
        const InputDecoration(
          labelText:
          'Date of Birth',
          prefixIcon:
          Icon(
            Icons
                .calendar_today_outlined,
          ),
        ),
        child: Text(
          _formatDate(
            _selectedDateOfBirth,
          ),
          style:
          TextStyle(
            fontSize: 15,
            color:
            _selectedDateOfBirth ==
                null
                ? AppColors
                .secondaryText
                : AppColors
                .primaryText,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ABHA CARD
  // =========================================================

  Widget _buildAbhaCard() {
    final hasAbha =
        _abhaNumber != null &&
            _abhaNumber!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        AppColors.surface,
        borderRadius:
        BorderRadius.circular(16),
        border:
        Border.all(
          color:
          Colors.grey.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
            BoxDecoration(
              color:
              AppColors.lightViolet
                  .withValues(
                alpha: 0.15,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child:
            const Icon(
              Icons
                  .medical_information_outlined,
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
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABHA Number',
                  style:
                  TextStyle(
                    fontSize: 12,
                    color:
                    AppColors
                        .secondaryText,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  hasAbha
                      ? _abhaNumber!
                      : 'Not linked',
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    AppColors
                        .primaryText,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            hasAbha
                ? Icons
                .verified_rounded
                : Icons
                .link_off_rounded,
            color: hasAbha
                ? AppColors.success
                : AppColors
                .secondaryText,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SAVE BUTTON
  // =========================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed:
        _saving
            ? null
            : _saveProfile,
        child: _saving
            ? const SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
            Colors.white,
          ),
        )
            : const Text(
          'Save Changes',
        ),
      ),
    );
  }
}
