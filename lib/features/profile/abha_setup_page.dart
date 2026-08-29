import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/features/home/home_page.dart';
import 'package:diagnect/services/auth_manager.dart';

class AbhaSetupPage extends StatefulWidget {
  const AbhaSetupPage({
    super.key,
  });

  @override
  State<AbhaSetupPage> createState() =>
      _AbhaSetupPageState();
}

class _AbhaSetupPageState
    extends State<AbhaSetupPage> {

  final AuthManager _authManager =
      AuthManager.instance;

  final TextEditingController
  _abhaAddressController =
  TextEditingController();

  bool _loading = true;
  bool _processing = false;

  bool _abhaExists = false;
  bool _abhaLinked = false;

  String? _abhaNumber;

  @override
  void initState() {
    super.initState();

    _loadAbhaStatus();
  }

  @override
  void dispose() {
    _abhaAddressController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD ABHA STATUS
  // =========================================================

  Future<void> _loadAbhaStatus() async {
    try {
      final status =
      await _authManager.getAbhaStatus();

      debugPrint(
        'ABHA STATUS: $status',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _abhaExists =
            status['exists'] == true ||
                status['abha_exists'] == true;

        _abhaLinked =
            status['linked'] == true ||
                status['abha_linked'] == true;

        _abhaNumber =
            status['abha_number']?.toString();
      });
    } catch (e) {
      debugPrint(
        'ABHA status failed: $e',
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
  // LINK EXISTING ABHA
  // =========================================================

  Future<void> _linkAbha() async {
    setState(() {
      _processing = true;
    });

    try {
      final result =
      await _authManager.linkAbha();

      debugPrint(
        'ABHA LINK RESULT: $result',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ABHA linked successfully.',
          ),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
          const HomePage(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // =========================================================
  // CREATE ABHA
  // =========================================================

  Future<void> _createAbha() async {
    FocusScope.of(context).unfocus();

    final address =
    _abhaAddressController.text.trim();

    if (address.isEmpty) {
      _showError(
        'Please enter an ABHA address.',
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final result =
      await _authManager.createAbha(
        abhaAddress: address,
      );

      debugPrint(
        'ABHA CREATE RESULT: $result',
      );

      // Refresh authoritative profile.
      await _authManager.fetchProfile();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ABHA created successfully.',
          ),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
          const HomePage(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // =========================================================
  // SKIP
  // =========================================================

  void _continueWithoutAbha() {
    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const HomePage(),
      ),
          (route) => false,
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          error
              .toString()
              .replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
        AppColors.background,
        elevation: 0,
        title: const Text(
          'ABHA Setup',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 24),

              Container(
                width: 72,
                height: 72,

                decoration:
                BoxDecoration(
                  color: AppColors.primary
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color:
                  AppColors.primary,
                  size: 38,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Set up your ABHA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'ABHA helps connect your health '
                    'records across healthcare providers.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                  AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 32),

              if (_abhaLinked) ...[
                _buildLinkedCard(),
              ] else if (_abhaExists) ...[
                _buildExistingAbha(),
              ] else ...[
                _buildCreateAbha(),
              ],

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed:
                  _processing
                      ? null
                      : _continueWithoutAbha,
                  child: const Text(
                    'Continue without ABHA',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LINKED
  // =========================================================

  Widget _buildLinkedCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),

      decoration:
      BoxDecoration(
        color: AppColors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary
              .withValues(alpha: 0.2),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.primary,
            size: 34,
          ),

          const SizedBox(height: 14),

          const Text(
            'ABHA already linked',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w700,
              color:
              AppColors.primaryText,
            ),
          ),

          if (_abhaNumber != null) ...[
            const SizedBox(height: 8),

            Text(
              _abhaNumber!,
              style: const TextStyle(
                fontSize: 15,
                color:
                AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // EXISTING ABHA
  // =========================================================

  Widget _buildExistingAbha() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Container(
          width: double.infinity,

          padding:
          const EdgeInsets.all(18),

          decoration:
          BoxDecoration(
            color: AppColors.surface,
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey
                  .withValues(
                alpha: 0.12,
              ),
            ),
          ),

          child: const Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Icon(
                Icons.link_rounded,
                color:
                AppColors.primary,
                size: 32,
              ),

              SizedBox(height: 12),

              Text(
                'Existing ABHA found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.primaryText,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Link your existing ABHA to Diagnect.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,

          child: ElevatedButton(
            onPressed:
            _processing
                ? null
                : _linkAbha,

            child:
            _processing
                ? const SizedBox(
              width: 22,
              height: 22,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Link Existing ABHA',
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CREATE
  // =========================================================

  Widget _buildCreateAbha() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        const Text(
          'Create a new ABHA',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.w700,
            color:
            AppColors.primaryText,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Choose an ABHA address for your account.',
          style: TextStyle(
            fontSize: 14,
            color:
            AppColors.secondaryText,
          ),
        ),

        const SizedBox(height: 18),

        TextField(
          controller:
          _abhaAddressController,

          decoration:
          const InputDecoration(
            prefixIcon:
            Icon(
              Icons.alternate_email_rounded,
            ),
            hintText:
            'yourname@abdm',
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,

          child: ElevatedButton(
            onPressed:
            _processing
                ? null
                : _createAbha,

            child:
            _processing
                ? const SizedBox(
              width: 22,
              height: 22,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Create ABHA',
            ),
          ),
        ),
      ],
    );
  }
}