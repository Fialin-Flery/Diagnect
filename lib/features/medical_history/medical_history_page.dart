import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/models/medical_history_model.dart';


class MedicalHistoryPage
    extends StatefulWidget {

  const MedicalHistoryPage({
    super.key,
    this.initialHistory,
    required this.onSave,
  });

  final MedicalHistoryModel?
  initialHistory;

  final Future<bool> Function(
      MedicalHistoryModel history,
      ) onSave;

  @override
  State<MedicalHistoryPage> createState() =>
      _MedicalHistoryPageState();
}


class _MedicalHistoryPageState
    extends State<MedicalHistoryPage> {

// =========================================================
// CONTROLLERS
// =========================================================

  late final TextEditingController
  _heightController;

  late final TextEditingController
  _weightController;

  late final TextEditingController
  _allergyController;

  late final TextEditingController
  _chronicConditionsController;

  late final TextEditingController
  _medicationsController;

  late final TextEditingController
  _emergencyContactController;

  late final TextEditingController
  _additionalNotesController;


// =========================================================
// STATE
// =========================================================

  String? _selectedSex;

  bool? _hivAids;

  bool? _smoking;

  bool? _alcohol;

  final List<String> _allergies =
  [];


  bool _saving = false;


// =========================================================
// INIT
// =========================================================

  @override
  void initState() {
    super.initState();

    final history =
        widget.initialHistory;

    _heightController =
        TextEditingController(
          text: history?.heightCm
              ?.toString() ??
              '',
        );

    _weightController =
        TextEditingController(
          text: history?.weightKg
              ?.toString() ??
              '',
        );

    _allergyController =
        TextEditingController();

    _chronicConditionsController =
        TextEditingController(
          text:
          history?.chronicConditions ??
              '',
        );

    _medicationsController =
        TextEditingController(
          text:
          history?.currentMedications ??
              '',
        );

    _emergencyContactController =
        TextEditingController(
          text:
          history?.emergencyContact ??
              '',
        );

    _additionalNotesController =
        TextEditingController(
          text:
          history?.additionalNotes ??
              '',
        );

    _selectedSex =
        history?.sex;

    _hivAids =
        history?.hivAids;

    _smoking =
        history?.smoking;

    _alcohol =
        history?.alcohol;

    _allergies.addAll(
      history?.allergies ??
          [],
    );
  }


// =========================================================
// DISPOSE
// =========================================================

  @override
  void dispose() {

    _heightController.dispose();

    _weightController.dispose();

    _allergyController.dispose();

    _chronicConditionsController
        .dispose();

    _medicationsController
        .dispose();

    _emergencyContactController
        .dispose();

    _additionalNotesController
        .dispose();

    super.dispose();
  }


// =========================================================
// ADD ALLERGY
// =========================================================

  void _addAllergy() {

    final allergy =
    _allergyController.text
        .trim();

    if (allergy.isEmpty) {
      return;
    }

    final exists =
    _allergies.any(
          (item) =>
      item.toLowerCase() ==
          allergy.toLowerCase(),
    );

    if (exists) {
      _allergyController.clear();
      return;
    }

    setState(() {

      _allergies.add(
        allergy,
      );

      _allergyController.clear();
    });
  }


// =========================================================
// REMOVE ALLERGY
// =========================================================

  void _removeAllergy(
      String allergy,
      ) {

    setState(() {

      _allergies.remove(
        allergy,
      );
    });
  }


// =========================================================
// SAVE
// =========================================================

  Future<void> _save() async {

    if (_saving) {
      return;
    }

    final heightText =
    _heightController.text
        .trim();

    final weightText =
    _weightController.text
        .trim();

    double? height;

    double? weight;

    if (heightText.isNotEmpty) {

      height =
          double.tryParse(
            heightText,
          );

      if (height == null ||
          height <= 0) {

        _showError(
          'Please enter a valid height.',
        );

        return;
      }
    }

    if (weightText.isNotEmpty) {

      weight =
          double.tryParse(
            weightText,
          );

      if (weight == null ||
          weight <= 0) {

        _showError(
          'Please enter a valid weight.',
        );

        return;
      }
    }

    setState(() {
      _saving = true;
    });

    final history =
    MedicalHistoryModel(

      id:
      widget.initialHistory?.id,

      userId:
      widget.initialHistory?.userId,

      heightCm:
      height,

      weightKg:
      weight,

      sex:
      _selectedSex,

      allergies:
      List<String>.from(
        _allergies,
      ),

      chronicConditions:
      _emptyToNull(
        _chronicConditionsController
            .text,
      ),

      currentMedications:
      _emptyToNull(
        _medicationsController
            .text,
      ),

      hivAids:
      _hivAids,

      smoking:
      _smoking,

      alcohol:
      _alcohol,

      emergencyContact:
      _emptyToNull(
        _emergencyContactController
            .text,
      ),

      additionalNotes:
      _emptyToNull(
        _additionalNotesController
            .text,
      ),

      completed: true,
    );

    try {

      final success =
      await widget.onSave(
        history,
      );

      if (!mounted) {
        return;
      }

      if (success) {

        Navigator.pop(
          context,
          history,
        );

      } else {

        _showError(
          'Unable to save medical history.',
        );
      }

    } catch (e) {

      if (!mounted) {
        return;
      }

      debugPrint(
        'Medical history save error: $e',
      );

      _showError(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          _saving = false;
        });
      }
    }
  }


  String? _emptyToNull(
      String value,
      ) {

    final trimmed =
    value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }


  void _showError(
      String message,
      ) {

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(message),
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

        title:
        const Text(
          'Medical History',
          style: TextStyle(
            color:
            AppColors.primaryText,
            fontSize: 21,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body:
      SafeArea(

        child:
        SingleChildScrollView(

          padding:
          const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),

          child:
          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              _buildIntro(),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Basic Information',
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                children: [

                  Expanded(
                    child:
                    _buildTextField(
                      controller:
                      _heightController,
                      label:
                      'Height',
                      hint:
                      '175',
                      suffix:
                      'cm',
                      keyboardType:
                      const TextInputType
                          .numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                    _buildTextField(
                      controller:
                      _weightController,
                      label:
                      'Weight',
                      hint:
                      '68',
                      suffix:
                      'kg',
                      keyboardType:
                      const TextInputType
                          .numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              _buildSexSelector(),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Allergies',
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Add all known allergies.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  AppColors.secondaryText,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              _buildAllergyInput(),

              const SizedBox(
                height: 12,
              ),

              _buildAllergyList(),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Medical Conditions',
              ),

              const SizedBox(
                height: 14,
              ),

              _buildMultilineField(
                controller:
                _chronicConditionsController,
                label:
                'Chronic Conditions',
                hint:
                'e.g. Asthma, diabetes, hypertension...',
              ),

              const SizedBox(
                height: 16,
              ),

              _buildMultilineField(
                controller:
                _medicationsController,
                label:
                'Current Medications',
                hint:
                'List medicines you currently take...',
              ),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Health Information',
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Choose Yes, No, or leave a field as Not specified.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color:
                  AppColors.secondaryText,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              _buildYesNoSlider(
                title:
                'HIV / AIDS',
                subtitle:
                'This information is kept private.',
                value:
                _hivAids,
                onChanged:
                    (value) {
                  setState(() {
                    _hivAids =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 10,
              ),

              _buildYesNoSlider(
                title:
                'Smoking',
                subtitle:
                'Do you currently smoke?',
                value:
                _smoking,
                onChanged:
                    (value) {
                  setState(() {
                    _smoking =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 10,
              ),

              _buildYesNoSlider(
                title:
                'Alcohol',
                subtitle:
                'Do you currently consume alcohol?',
                value:
                _alcohol,
                onChanged:
                    (value) {
                  setState(() {
                    _alcohol =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Emergency Contact',
              ),

              const SizedBox(
                height: 14,
              ),

              _buildTextField(
                controller:
                _emergencyContactController,
                label:
                'Emergency Contact',
                hint:
                'Phone number',
                keyboardType:
                TextInputType.phone,
              ),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Additional Information',
              ),

              const SizedBox(
                height: 14,
              ),

              _buildMultilineField(
                controller:
                _additionalNotesController,
                label:
                'Additional Notes',
                hint:
                'Anything else your doctor should know...',
              ),

              const SizedBox(
                height: 32,
              ),

              SizedBox(
                width:
                double.infinity,

                height:
                52,

                child:
                ElevatedButton(
                  onPressed:
                  _saving
                      ? null
                      : _save,

                  child:
                  _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2.5,
                    ),
                  )
                      : const Text(
                    'Save Medical History',
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
// INTRO
// =========================================================

  Widget _buildIntro() {

    return Container(

      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(

        color:
        AppColors.primary
            .withValues(
          alpha: 0.08,
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
            alpha: 0.15,
          ),
        ),
      ),

      child:
      const Row(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            Icons
                .medical_information_rounded,
            color:
            AppColors.primary,
          ),

          SizedBox(
            width: 12,
          ),

          Expanded(
            child:
            Text(
              'Keep your important health information '
                  'available in one secure place. You can '
                  'update this information whenever needed.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color:
                AppColors.primaryText,
              ),
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
// TEXT FIELD
// =========================================================

  Widget _buildTextField({

    required TextEditingController
    controller,

    required String label,

    required String hint,

    String? suffix,

    TextInputType? keyboardType,

  }) {

    return TextField(

      controller:
      controller,

      keyboardType:
      keyboardType,

      decoration:
      InputDecoration(

        labelText:
        label,

        hintText:
        hint,

        suffixText:
        suffix,

        filled:
        true,

        fillColor:
        AppColors.surface,

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide.none,
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey
                .withValues(
              alpha: 0.12,
            ),
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          const BorderSide(
            color:
            AppColors.primary,
          ),
        ),
      ),
    );
  }


// =========================================================
// MULTILINE FIELD
// =========================================================

  Widget _buildMultilineField({

    required TextEditingController
    controller,

    required String label,

    required String hint,

  }) {

    return TextField(

      controller:
      controller,

      maxLines:
      4,

      decoration:
      InputDecoration(

        labelText:
        label,

        hintText:
        hint,

        alignLabelWithHint:
        true,

        filled:
        true,

        fillColor:
        AppColors.surface,

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide.none,
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey
                .withValues(
              alpha: 0.12,
            ),
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          const BorderSide(
            color:
            AppColors.primary,
          ),
        ),
      ),
    );
  }


// =========================================================
// SEX
// =========================================================

  Widget _buildSexSelector() {

    return DropdownButtonFormField<String>(

      initialValue:
      _selectedSex,

      decoration:
      InputDecoration(

        labelText:
        'Sex',

        filled:
        true,

        fillColor:
        AppColors.surface,

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide.none,
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey
                .withValues(
              alpha: 0.12,
            ),
          ),
        ),
      ),

      items:
      const [

        DropdownMenuItem(
          value:
          'Male',
          child:
          Text('Male'),
        ),

        DropdownMenuItem(
          value:
          'Female',
          child:
          Text('Female'),
        ),

        DropdownMenuItem(
          value:
          'Other',
          child:
          Text('Other'),
        ),

        DropdownMenuItem(
          value:
          'Prefer not to say',
          child:
          Text(
            'Prefer not to say',
          ),
        ),
      ],

      onChanged:
          (value) {

        setState(() {
          _selectedSex =
              value;
        });
      },
    );
  }


// =========================================================
// ALLERGY INPUT
// =========================================================

  Widget _buildAllergyInput() {

    return Row(
      children: [

        Expanded(
          child:
          TextField(
            controller:
            _allergyController,

            textInputAction:
            TextInputAction.done,

            onSubmitted:
                (_) {
              _addAllergy();
            },

            decoration:
            InputDecoration(
              labelText:
              'Add Allergy',

              hintText:
              'e.g. Penicillin',

              filled:
              true,

              fillColor:
              AppColors.surface,

              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                borderSide:
                BorderSide.none,
              ),

              enabledBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                borderSide:
                BorderSide(
                  color:
                  Colors.grey
                      .withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        SizedBox(
          height: 56,
          width: 56,

          child:
          IconButton(
            onPressed:
            _addAllergy,

            style:
            IconButton.styleFrom(
              backgroundColor:
              AppColors.primary,
              foregroundColor:
              Colors.white,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
            ),

            icon:
            const Icon(
              Icons.add_rounded,
            ),
          ),
        ),
      ],
    );
  }


// =========================================================
// ALLERGY LIST
// =========================================================

  Widget _buildAllergyList() {

    if (_allergies.isEmpty) {

      return const Text(
        'No allergies added.',
        style:
        TextStyle(
          fontSize: 12,
          color:
          AppColors.secondaryText,
        ),
      );
    }

    return Wrap(

      spacing: 8,

      runSpacing: 8,

      children:
      _allergies.map(
            (allergy) {

          return Chip(

            label:
            Text(
              allergy,
            ),

            deleteIcon:
            const Icon(
              Icons.close_rounded,
              size: 17,
            ),

            onDeleted:
                () {
              _removeAllergy(
                allergy,
              );
            },
          );
        },
      ).toList(),
    );
  }


// =========================================================
// THREE-STATE YES / NO SLIDER
// =========================================================

  Widget _buildYesNoSlider({

    required String title,

    required String subtitle,

    required bool? value,

    required ValueChanged<bool?>
    onChanged,

  }) {

    final selectedIndex =
    value == null
        ? 0
        : value
        ? 2
        : 1;

    return Container(

      padding:
      const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),

      decoration:
      BoxDecoration(

        color:
        AppColors.surface,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color:
          Colors.grey
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),

      child:
      Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

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
            height: 3,
          ),

          Text(
            subtitle,
            style:
            const TextStyle(
              fontSize: 11,
              color:
              AppColors.secondaryText,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [

              Expanded(
                child:
                _sliderOption(
                  label:
                  'Not specified',
                  selected:
                  selectedIndex == 0,
                  onTap: () {
                    onChanged(null);
                  },
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _sliderOption(
                  label:
                  'No',
                  selected:
                  selectedIndex == 1,
                  onTap: () {
                    onChanged(false);
                  },
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _sliderOption(
                  label:
                  'Yes',
                  selected:
                  selectedIndex == 2,
                  onTap: () {
                    onChanged(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _sliderOption({

    required String label,

    required bool selected,

    required VoidCallback onTap,

  }) {

    return GestureDetector(

      onTap:
      onTap,

      child:
      AnimatedContainer(

        duration:
        const Duration(
          milliseconds: 180,
        ),

        height:
        38,

        alignment:
        Alignment.center,

        decoration:
        BoxDecoration(

          color:
          selected
              ? AppColors.primary
              : AppColors.background,

          borderRadius:
          BorderRadius.circular(
            11,
          ),

          border:
          Border.all(
            color:
            selected
                ? AppColors.primary
                : Colors.grey
                .withValues(
              alpha: 0.12,
            ),
          ),
        ),

        child:
        Text(
          label,
          textAlign:
          TextAlign.center,
          style:
          TextStyle(
            fontSize: 11,
            fontWeight:
            selected
                ? FontWeight.w700
                : FontWeight.w500,
            color:
            selected
                ? Colors.white
                : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

