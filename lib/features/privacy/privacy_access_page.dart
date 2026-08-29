import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';

class PrivacyAccessPage extends StatelessWidget {
  const PrivacyAccessPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryText,
          ),
        ),
        title: const Text(
          'Privacy & Access',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // TRUST HEADER
              // =====================================================

              _buildTrustHeader(),

              const SizedBox(height: 24),

              // =====================================================
              // YOUR PRIVACY MATTERS
              // =====================================================

              const Text(
                'Your privacy comes first',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your medical records belong to you. '
                    'Diagnect is designed to help you keep control '
                    'over when and how your health information is shared.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 22),

              // =====================================================
              // SECURITY FEATURES
              // =====================================================

              _buildSecurityCard(
                icon: Icons.lock_outline_rounded,
                title: 'Your health data stays protected',
                description:
                'Your medical information is handled through '
                    'secure authentication and controlled access. '
                    'Only authorized flows can be used to access '
                    'your records.',
              ),

              const SizedBox(height: 12),

              _buildSecurityCard(
                icon: Icons.verified_user_outlined,
                title: 'ABHA adds another layer of trust',
                description:
                'Diagnect is designed to work with ABHA-based '
                    'health identity and consent mechanisms. This '
                    'helps keep your health information connected '
                    'to a verified identity and supports secure '
                    'health-data sharing.',
              ),

              const SizedBox(height: 12),

              _buildSecurityCard(
                icon: Icons.visibility_off_outlined,
                title: 'No unnecessary access',
                description:
                'A doctor does not receive permanent access to '
                    'your complete medical history just because you '
                    'visited them. Access is provided for the '
                    'specific consultation flow.',
              ),

              const SizedBox(height: 28),

              // =====================================================
              // DOCTOR ACCESS SECTION
              // =====================================================

              _buildSectionTitle(
                'When you scan a doctor QR',
              ),

              const SizedBox(height: 12),

              _buildAccessFlowCard(),

              const SizedBox(height: 28),

              // =====================================================
              // 45 MINUTE ACCESS
              // =====================================================

              _buildLimitedAccessCard(),

              const SizedBox(height: 28),

              // =====================================================
              // YOUR CONTROL
              // =====================================================

              _buildSectionTitle(
                'You stay in control',
              ),

              const SizedBox(height: 12),

              _buildControlPoint(
                icon: Icons.qr_code_scanner_rounded,
                title: 'You initiate access',
                description:
                'Medical information is shared through an '
                    'intentional QR-based access flow.',
              ),

              const SizedBox(height: 14),

              _buildControlPoint(
                icon: Icons.timer_outlined,
                title: 'Access is temporary',
                description:
                'Doctor access is limited to the permitted '
                    'consultation window rather than becoming '
                    'permanent access to your records.',
              ),

              const SizedBox(height: 14),

              _buildControlPoint(
                icon: Icons.file_download_off_outlined,
                title: 'Records are not downloadable',
                description:
                'The doctor-side access is designed for viewing '
                    'the information needed for consultation, not '
                    'for downloading your complete medical records.',
              ),

              const SizedBox(height: 28),

              // =====================================================
              // SIMPLE PROMISE
              // =====================================================

              _buildPromiseCard(),

              const SizedBox(height: 30),

              // =====================================================
              // CONTACT
              // =====================================================

              const Text(
                'Need more information?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'If you have questions about privacy, security, '
                    'or how your information is handled, you can '
                    'contact us directly.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 14),

              _buildContactCard(),

              const SizedBox(height: 24),

              // =====================================================
              // FOOTER
              // =====================================================

              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary.withValues(
                        alpha: 0.55,
                      ),
                      size: 22,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your health. Your records. Your control.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TRUST HEADER
  // =============================================================

  Widget _buildTrustHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.lightViolet,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.16,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Your health information\nis yours.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Diagnect is built around privacy, '
                'controlled access, and transparency.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privacy-focused medical record sharing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  // =============================================================
  // SECURITY CARD
  // =============================================================

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
    );
  }

  // =============================================================
  // ACCESS FLOW
  // =============================================================

  Widget _buildAccessFlowCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildFlowStep(
            number: '1',
            icon: Icons.qr_code_2_rounded,
            title: 'Scan',
            description:
            'You scan the QR code provided by the doctor.',
          ),

          _buildFlowConnector(),

          _buildFlowStep(
            number: '2',
            icon: Icons.verified_user_outlined,
            title: 'Authorize',
            description:
            'The access flow is initiated for your consultation.',
          ),

          _buildFlowConnector(),

          _buildFlowStep(
            number: '3',
            icon: Icons.medical_information_outlined,
            title: 'Consult',
            description:
            'The doctor can view the information needed for care.',
          ),

          _buildFlowConnector(),

          _buildFlowStep(
            number: '4',
            icon: Icons.timer_off_outlined,
            title: 'Access ends',
            description:
            'The temporary access window expires after the permitted period.',
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightViolet.withValues(
                  alpha: 0.18,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 21,
              ),
            ),
          ],
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowConnector() {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: 5,
        bottom: 5,
      ),
      height: 18,
      width: 1.5,
      color: AppColors.lightViolet.withValues(
        alpha: 0.45,
      ),
    );
  }

  // =============================================================
  // LIMITED ACCESS CARD
  // =============================================================

  Widget _buildLimitedAccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Text(
                  'Temporary doctor access',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'Maximum access window',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            '45 minutes',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'After you scan and authorize a doctor QR, '
                'the doctor-side access to your medical information '
                'is temporary and limited to a maximum of 45 minutes '
                'for the consultation flow.',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),

                SizedBox(width: 9),

                Expanded(
                  child: Text(
                    'The doctor does not receive a permanent copy '
                        'of your medical wallet through this access flow.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.primaryText,
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

  // =============================================================
  // CONTROL POINT
  // =============================================================

  Widget _buildControlPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: Colors.grey.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // PROMISE CARD
  // =============================================================

  Widget _buildPromiseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.handshake_outlined,
              color: AppColors.success,
              size: 26,
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'A simple promise',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Diagnect is being built to make your medical '
                'history easier to carry without making your '
                'privacy harder to protect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CONTACT CARD
  // =============================================================

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildContactRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'fialinflery@gmail.com',
          ),

          const SizedBox(height: 16),

          Divider(
            height: 1,
            color: Colors.grey.withValues(
              alpha: 0.10,
            ),
          ),

          const SizedBox(height: 16),

          _buildContactRow(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: '9789592130',
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.09,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}