import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
//import 'package:diagnect/features/home/home_page.dart';
import 'package:diagnect/services/auth_manager.dart';
import 'package:diagnect/features/profile/abha_setup_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({
    super.key,
  });

  @override
  State<ProfileSetupPage> createState() =>
      _ProfileSetupPageState();
}

class _ProfileSetupPageState
    extends State<ProfileSetupPage> {

  final AuthManager _authManager =
      AuthManager.instance;

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _dobController =
  TextEditingController();

  String? _bloodGroup;

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();

    super.dispose();
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _saveProfile() async {

    FocusScope.of(context).unfocus();

    final name =
    _nameController.text.trim();

    final dob =
    _dobController.text.trim();

    if (name.length < 2) {

      _showError(
        'Please enter your full name.',
      );

      return;
    }

    if (dob.isEmpty) {

      _showError(
        'Please enter your date of birth.',
      );

      return;
    }

    if (_bloodGroup == null) {

      _showError(
        'Please select your blood group.',
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {

      await _authManager.updateProfile(
        name: name,
        dateOfBirth: dob,
        bloodGroup: _bloodGroup!,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
          const AbhaSetupPage(),
        ),
            (route) => false,
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      _showError(
        e.toString(),
      );

    } finally {

      if (mounted) {

        setState(() {
          _loading = false;
        });

      }
    }
  }

  // =========================================================
  // ERROR
  // =========================================================

  void _showError(
      String message,
      ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> _selectDate() async {

    final now =
    DateTime.now();

    final selected =
    await showDatePicker(
      context: context,

      initialDate:
      DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),

      firstDate:
      DateTime(1900),

      lastDate:
      now,
    );

    if (selected == null) {
      return;
    }

    final month =
    selected.month
        .toString()
        .padLeft(2, '0');

    final day =
    selected.day
        .toString()
        .padLeft(2, '0');

    _dobController.text =
    '${selected.year}-$month-$day';
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
        title: const Text(
          'Complete Your Profile',
        ),

        backgroundColor:
        AppColors.background,

        elevation: 0,

        automaticallyImplyLeading:
        false,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 20),

              const Text(
                'Welcome to Diagnect',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Complete your health profile to '
                    'start using your medical wallet.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                  AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 36),

              // NAME

              const Text(
                'Full Name',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  color:
                  AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                _nameController,

                textCapitalization:
                TextCapitalization.words,

                decoration:
                const InputDecoration(
                  hintText:
                  'Enter your full name',
                  prefixIcon:
                  Icon(
                    Icons.person_outline,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // DOB

              const Text(
                'Date of Birth',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  color:
                  AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                _dobController,

                readOnly: true,

                onTap:
                _selectDate,

                decoration:
                const InputDecoration(
                  hintText:
                  'Select your date of birth',

                  prefixIcon:
                  Icon(
                    Icons.calendar_today_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // BLOOD GROUP

              const Text(
                'Blood Group',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  color:
                  AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,

                decoration:
                const InputDecoration(
                  prefixIcon:
                  Icon(
                    Icons.bloodtype_outlined,
                  ),
                ),

                items: const [
                  'A+',
                  'A-',
                  'B+',
                  'B-',
                  'AB+',
                  'AB-',
                  'O+',
                  'O-',
                  'Unknown',
                ]
                    .map(
                      (group) =>
                      DropdownMenuItem(
                        value: group,
                        child:
                        Text(group),
                      ),
                )
                    .toList(),

                onChanged: (value) {
                  setState(() {
                    _bloodGroup =
                        value;
                  });
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width:
                double.infinity,

                height: 52,

                child: ElevatedButton(
                  onPressed:
                  _loading
                      ? null
                      : _saveProfile,

                  child:
                  _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}