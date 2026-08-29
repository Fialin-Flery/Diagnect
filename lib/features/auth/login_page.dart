import 'package:flutter/material.dart';
import 'package:diagnect/services/auth_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import 'package:diagnect/services/pending_verification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.verificationFailed = false,
    this.verificationStatus,
  });

  final bool verificationFailed;
  final String? verificationStatus;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _aadhaarController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _consentGiven = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }



  Future<void> _startDigiLockerVerification() async {
    final aadhaar = _aadhaarController.text.replaceAll(RegExp(r'\s+'), '');



    if (aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid 12-digit Aadhaar number',
          ),
        ),
      );
      return;
    }

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide consent to continue.',
          ),
        ),
      );
      return;
    }

    PendingVerificationService.instance.saveAadhaar(
      aadhaar,
    );

    try {
      setState(() {
        _isLoading = true;
      });

      final startResponse =
      await _authApiService.startDigiLocker(
        aadhaar,
      );

      final cashfree = startResponse['cashfree'];

      final verificationId =
      cashfree['verification_id'];

      final status =
      cashfree['status'];

      final String userFlow;

      if (status == 'ACCOUNT_EXISTS') {
        userFlow = 'signin';
      } else if (status == 'ACCOUNT_NOT_FOUND') {
        userFlow = 'signup';
      } else {
        throw Exception(
          'Unexpected DigiLocker status: $status',
        );
      }

      final urlResponse =
      await _authApiService.createDigiLockerUrl(
        verificationId,
        userFlow,
      );

      final url =
      urlResponse['cashfree']['url'];

      final uri = Uri.parse(url);

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception(
          'Could not open DigiLocker',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatAadhaar(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length <= 4) {
      return digits;
    }

    if (digits.length <= 8) {
      return '${digits.substring(0, 4)} '
          '${digits.substring(4)}';
    }

    return '${digits.substring(0, 4)} '
        '${digits.substring(4, 8)} '
        '${digits.substring(8, digits.length > 12 ? 12 : digits.length)}';
  }

  bool _isValidAadhaar(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    return digits.length == 12;
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    final aadhaar = _aadhaarController.text
        .replaceAll(RegExp(r'\D'), '');

    // 1. Validate Aadhaar
    if (!_isValidAadhaar(aadhaar)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid 12-digit Aadhaar number.',
          ),
        ),
      );
      return;
    }

    // 2. Check consent
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide consent to continue.',
          ),
        ),
      );
      return;
    }

    // 3. Start DigiLocker verification
    await _startDigiLockerVerification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),


                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/diagnect_logo.png',
                          height: 120,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 8),
                        Image.asset(
                          'assets/images/diagnect_text.png',
                          height: 50,
                          filterQuality: FilterQuality.high,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Your medical history.\nWherever you go.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.5,
                      color: AppColors.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 44),

                  const Text(
                    'Aadhaar Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _aadhaarController,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'XXXX XXXX XXXX',
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                      ),
                    ),
                    onChanged: (value) {
                      final formatted =
                      _formatAadhaar(value);

                      if (formatted != value) {
                        _aadhaarController.value =
                            TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consentGiven,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _consentGiven = value ?? false;
                          });
                        },
                      ),

                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 12,
                          ),
                          child: Text(
                            'I consent to Aadhaar-based '
                                'identity verification for '
                                'accessing Diagnect.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color:
                              AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _continue,
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Continue'),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Your Aadhaar number is used only '
                        'for identity verification. '
                        'Your medical information is shared '
                        'only with your permission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}