import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/features/alumni/providers/alumni_provider.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _posterNameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _salaryRangeController;
  late TextEditingController _contactEmailController;
  late TextEditingController _descriptionController;

  String _type = 'Internship';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value;
    final userName = user != null ? user['name']?.toString() ?? '' : '';
    final userEmail = user != null ? user['email']?.toString() ?? '' : '';
    _posterNameController = TextEditingController(text: userName);
    _titleController = TextEditingController();
    _companyController = TextEditingController();
    _locationController = TextEditingController(text: 'Remote');
    _salaryRangeController = TextEditingController();
    _contactEmailController = TextEditingController(text: userEmail);
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _posterNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryRangeController.dispose();
    _contactEmailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(alumniServiceProvider);
      await service.postJob(
        posterName: _posterNameController.text.trim(),
        type: _type,
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim(),
        salaryRange: _salaryRangeController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      CustomSnackBar.show(
        context,
        message: 'Opportunity posted successfully!',
      );

      // Refresh jobs feed
      ref.invalidate(alumniJobsProvider);

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: e.toString().replaceAll('AlumniApiException: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.primaryText, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post Opportunity',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: colors.borderColor.withValues(alpha: 0.5),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opportunity Type Selector
              Text(
                'Opportunity Type',
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeRadioTile(
                      colors,
                      label: 'Internship',
                      value: 'Internship',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeRadioTile(
                      colors,
                      label: 'Full-Time Job',
                      value: 'Job',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title
              _buildTextField(
                colors,
                controller: _titleController,
                label: 'Position Title',
                hint: 'e.g. QA intern, Flutter Developer',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a title' : null,
              ),

              const SizedBox(height: 16),

              // Company
              _buildTextField(
                colors,
                controller: _companyController,
                label: 'Company / Organization',
                hint: 'e.g. MELO AI, SWYNX',
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter company name'
                    : null,
              ),

              const SizedBox(height: 16),

              // Location & Salary Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      colors,
                      controller: _locationController,
                      label: 'Location',
                      hint: 'e.g. Remote, Sarang',
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter location'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      colors,
                      controller: _salaryRangeController,
                      label: 'Stipend / Salary',
                      hint: 'e.g. ₹15000/month',
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter stipend/salary'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Poster Name & Contact Email
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      colors,
                      controller: _posterNameController,
                      label: 'Your Name',
                      hint: 'Poster name',
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter your name' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      colors,
                      controller: _contactEmailController,
                      label: 'Contact Email',
                      hint: 'Application email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || !val.contains('@')
                          ? 'Enter valid email'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              _buildTextField(
                colors,
                controller: _descriptionController,
                label: 'Opportunity Description',
                hint: 'Describe key responsibilities, requirements, and benefits...',
                maxLines: 5,
                validator: (val) => val == null || val.length < 10
                    ? 'Please enter a description (at least 10 chars)'
                    : null,
              ),

              const SizedBox(height: 32),

              // Submit CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: colors.onPrimaryAccent,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onPrimaryAccent,
                          ),
                        )
                      : const Text(
                          'Post Opportunity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeRadioTile(
    AppColors colors, {
    required String label,
    required String value,
  }) {
    final isSelected = _type == value;

    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryAccent.withValues(alpha: 0.12)
              : colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? colors.primaryAccent : colors.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.primaryAccent : colors.primaryText,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    AppColors colors, {
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.secondaryText.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            filled: true,
            fillColor: colors.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primaryAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
