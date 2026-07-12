import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/startup_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Student fields
  final _bioController = TextEditingController();
  final _majorController = TextEditingController();
  final _yearController = TextEditingController();
  final _selectedSkills = <String>{};

  // Founder fields
  final _startupNameController = TextEditingController();
  final _startupDescController = TextEditingController();
  final _aluProgramController = TextEditingController();
  String _selectedIndustry = AppConstants.industries.first;

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _majorController.dispose();
    _yearController.dispose();
    _startupNameController.dispose();
    _startupDescController.dispose();
    _aluProgramController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      if (user.isStudent) {
        await ref.read(authServiceProvider).updateUserProfile(
              user.copyWith(
                bio: _bioController.text.trim(),
                major: _majorController.text.trim(),
                graduationYear: int.tryParse(_yearController.text.trim()),
                skills: _selectedSkills.toList(),
                onboardingComplete: true,
              ),
            );
      } else if (user.isFounder) {
        if (_startupNameController.text.trim().isEmpty ||
            _startupDescController.text.trim().isEmpty) {
          _showError('Please fill in your startup details.');
          return;
        }

        await ref.read(startupServiceProvider).createStartup(
              Startup(
                id: '',
                founderId: user.id,
                name: _startupNameController.text.trim(),
                description: _startupDescController.text.trim(),
                industry: _selectedIndustry,
                aluProgram: _aluProgramController.text.trim(),
              ),
            );

        await ref.read(authServiceProvider).updateUserProfile(
              user.copyWith(onboardingComplete: true),
            );
      } else {
        await ref.read(authServiceProvider).updateUserProfile(
              user.copyWith(onboardingComplete: true),
            );
      }

      if (mounted) context.go('/home');
    } on FirebaseException catch (e) {
      _showError(
        e.message ?? 'Could not complete onboarding. Please try again.',
      );
    } catch (e) {
      _showError('Could not complete onboarding. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: List.generate(2, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _WelcomePage(user: user),
                user.isStudent
                    ? _StudentProfilePage(
                        bioController: _bioController,
                        majorController: _majorController,
                        yearController: _yearController,
                        selectedSkills: _selectedSkills,
                        onSkillToggle: (skill) {
                          setState(() {
                            if (_selectedSkills.contains(skill)) {
                              _selectedSkills.remove(skill);
                            } else {
                              _selectedSkills.add(skill);
                            }
                          });
                        },
                      )
                    : _FounderProfilePage(
                        nameController: _startupNameController,
                        descController: _startupDescController,
                        programController: _aluProgramController,
                        selectedIndustry: _selectedIndustry,
                        onIndustryChanged: (v) =>
                            setState(() => _selectedIndustry = v),
                      ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextPage,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentPage == 0 ? 'Continue' : 'Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user.displayName}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            user.isStudent
                ? 'ALU Connect helps you discover meaningful internship experiences with ALU student-led startups. Let\'s set up your profile so founders can find you.'
                : 'Post opportunities, review applications, and grow your team with talented ALU students. Let\'s set up your startup profile.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _FeatureItem(
            icon: Icons.verified_outlined,
            title: 'Verified ALU Ecosystem',
            subtitle: 'Only recognized campus ventures are verified',
          ),
          const SizedBox(height: 16),
          _FeatureItem(
            icon: Icons.sync,
            title: 'Real-time Updates',
            subtitle: 'Track applications and notifications instantly',
          ),
          const SizedBox(height: 16),
          _FeatureItem(
            icon: Icons.search,
            title: 'Smart Discovery',
            subtitle: 'Filter opportunities by skills and interests',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentProfilePage extends StatelessWidget {
  const _StudentProfilePage({
    required this.bioController,
    required this.majorController,
    required this.yearController,
    required this.selectedSkills,
    required this.onSkillToggle,
  });

  final TextEditingController bioController;
  final TextEditingController majorController;
  final TextEditingController yearController;
  final Set<String> selectedSkills;
  final ValueChanged<String> onSkillToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Student Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: majorController,
            decoration: const InputDecoration(
              labelText: 'Major / Program',
              prefixIcon: Icon(Icons.school),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Graduation Year',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Short Bio',
              hintText: 'Tell startups about your interests and experience',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Skills',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select skills to get better-matched opportunities',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.studentSkills.map((skill) {
              final selected = selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: selected,
                onSelected: (_) => onSkillToggle(skill),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FounderProfilePage extends StatelessWidget {
  const _FounderProfilePage({
    required this.nameController,
    required this.descController,
    required this.programController,
    required this.selectedIndustry,
    required this.onIndustryChanged,
  });

  final TextEditingController nameController;
  final TextEditingController descController;
  final TextEditingController programController;
  final String selectedIndustry;
  final ValueChanged<String> onIndustryChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Startup Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your startup will be reviewed by ALU before verification',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Startup Name',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedIndustry,
            decoration: const InputDecoration(
              labelText: 'Industry',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: AppConstants.industries
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: (v) {
              if (v != null) onIndustryChanged(v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: programController,
            decoration: const InputDecoration(
              labelText: 'ALU Program / Cohort',
              hintText: 'e.g. Global Challenges, Year 2',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'About Your Startup',
              hintText: 'What problem are you solving?',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
