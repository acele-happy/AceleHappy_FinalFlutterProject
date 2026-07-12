import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../models/opportunity_model.dart';
import '../../providers/app_providers.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common_widgets.dart';

class OpportunityDetailScreen extends ConsumerStatefulWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  ConsumerState<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState
    extends ConsumerState<OpportunityDetailScreen> {
  Opportunity? _opportunity;
  bool _loading = true;
  bool _hasApplied = false;
  final _coverLetterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final opp = await ref
        .read(opportunityServiceProvider)
        .getOpportunity(widget.opportunityId);
    final user = ref.read(currentUserProvider).valueOrNull;
    var applied = false;
    if (user != null && user.isStudent) {
      applied = await ref.read(applicationServiceProvider).hasApplied(
            user.id,
            widget.opportunityId,
          );
    }
    if (mounted) {
      setState(() {
        _opportunity = opp;
        _hasApplied = applied;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final opp = _opportunity;
    if (user == null || opp == null) return;

    if (_coverLetterController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a brief cover letter (at least 20 characters).'),
        ),
      );
      return;
    }

    try {
      await ref.read(applicationServiceProvider).submitApplication(
            Application(
              id: '',
              opportunityId: opp.id,
              opportunityTitle: opp.title,
              studentId: user.id,
              studentName: user.displayName,
              startupId: opp.startupId,
              startupName: opp.startupName,
              coverLetter: _coverLetterController.text.trim(),
            ),
          );
      if (mounted) {
        setState(() => _hasApplied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApplicationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }

    final opp = _opportunity;
    if (opp == null) {
      return const Scaffold(
        body: ErrorView(message: 'Opportunity not found'),
      );
    }

    final user = ref.watch(currentUserProvider).valueOrNull;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opp.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => context.push('/startup/${opp.startupId}'),
              child: Text(
                opp.startupName,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow(Icons.work_outline, 'Type', opp.type),
            _DetailRow(
              Icons.location_on_outlined,
              'Location',
              opp.isRemote ? 'Remote' : opp.location,
            ),
            _DetailRow(Icons.schedule, 'Hours/week', '${opp.hoursPerWeek}h'),
            if (opp.deadline != null)
              _DetailRow(
                Icons.event,
                'Deadline',
                dateFormat.format(opp.deadline!),
              ),
            _DetailRow(
              Icons.people_outline,
              'Applications',
              '${opp.applicationCount}',
            ),
            const SizedBox(height: 24),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              opp.description,
              style: const TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text('Required Skills',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            SkillChips(skills: opp.skills, maxVisible: 10),
            if (user?.isStudent == true) ...[
              const SizedBox(height: 32),
              if (_hasApplied)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 12),
                      Text('You have applied to this opportunity'),
                    ],
                  ),
                )
              else ...[
                const Text('Cover Letter',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _coverLetterController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        'Explain why you\'re interested and what you bring...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: opp.isOpen ? _apply : null,
                    child: Text(opp.isOpen ? 'Apply Now' : 'Closed'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class CreateOpportunityScreen extends ConsumerStatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  ConsumerState<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState
    extends ConsumerState<CreateOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(text: 'Kigali Campus');
  final _hoursController = TextEditingController(text: '10');
  String _type = AppConstants.opportunityTypes.first;
  bool _isRemote = false;
  final _selectedSkills = <String>{};
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one skill')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final startup = await ref.read(startupServiceProvider).getStartupByFounder(user.id);
    if (startup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create your startup profile first')),
      );
      return;
    }

    if (!startup.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your startup must be verified before posting opportunities.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(opportunityServiceProvider).createOpportunity(
            Opportunity(
              id: '',
              startupId: startup.id,
              startupName: startup.name,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              skills: _selectedSkills.toList(),
              type: _type,
              location: _locationController.text.trim(),
              isRemote: _isRemote,
              hoursPerWeek: int.tryParse(_hoursController.text) ?? 10,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity posted!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post opportunity')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Opportunity')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: AppConstants.opportunityTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Remote opportunity'),
              value: _isRemote,
              onChanged: (v) => setState(() => _isRemote = v),
            ),
            if (!_isRemote)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hours per week'),
            ),
            const SizedBox(height: 24),
            const Text('Skills Needed', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.studentSkills.map((skill) {
                final selected = _selectedSkills.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.remove(skill);
                      } else {
                        _selectedSkills.add(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Publish Opportunity'),
            ),
          ],
        ),
      ),
    );
  }
}
