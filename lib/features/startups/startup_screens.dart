import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firestore_utils.dart';
import '../../models/startup_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class StartupDetailScreen extends ConsumerStatefulWidget {
  const StartupDetailScreen({super.key, required this.startupId});

  final String startupId;

  @override
  ConsumerState<StartupDetailScreen> createState() =>
      _StartupDetailScreenState();
}

class _StartupDetailScreenState extends ConsumerState<StartupDetailScreen> {
  Startup? _startup;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final startup =
        await ref.read(startupServiceProvider).getStartup(widget.startupId);
    if (mounted) {
      setState(() {
        _startup = startup;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }

    final startup = _startup;
    if (startup == null) {
      return const Scaffold(body: ErrorView(message: 'Startup not found'));
    }

    final opportunities =
        ref.watch(startupOpportunitiesProvider(startup.id));

    return Scaffold(
      appBar: AppBar(title: Text(startup.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    startup.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startup.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(startup.industry),
                      const SizedBox(height: 4),
                      VerificationBadge(status: startup.verificationStatus),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (startup.aluProgram != null)
              _InfoRow('ALU Program', startup.aluProgram!),
            _InfoRow('Stage', startup.stage),
            _InfoRow('Team Size', '${startup.teamSize} members'),
            const SizedBox(height: 16),
            const Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              startup.description,
              style: const TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Open Opportunities',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            opportunities.when(
              data: (list) {
                final open = list.where((o) => o.isOpen).toList();
                if (open.isEmpty) {
                  return const Text(
                    'No open opportunities at the moment.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                return Column(
                  children: open
                      .map(
                        (opp) => Card(
                          child: ListTile(
                            title: Text(opp.title),
                            subtitle: Text(opp.type),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.push('/opportunity/${opp.id}'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => Text(firestoreErrorMessage(e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class StartupProfileScreen extends ConsumerStatefulWidget {
  const StartupProfileScreen({super.key});

  @override
  ConsumerState<StartupProfileScreen> createState() =>
      _StartupProfileScreenState();
}

class _StartupProfileScreenState extends ConsumerState<StartupProfileScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _programController = TextEditingController();
  final _websiteController = TextEditingController();
  String _industry = AppConstants.industries.first;
  Startup? _startup;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final startup =
        await ref.read(startupServiceProvider).getStartupByFounder(user.id);
    if (startup != null) {
      _nameController.text = startup.name;
      _descController.text = startup.description;
      _programController.text = startup.aluProgram ?? '';
      _websiteController.text = startup.website ?? '';
      _industry = startup.industry;
    }

    if (mounted) {
      setState(() {
        _startup = startup;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _programController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Startup name and description are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_startup == null) {
        await ref.read(startupServiceProvider).createStartup(
              Startup(
                id: '',
                founderId: user.id,
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
                industry: _industry,
                aluProgram: _programController.text.trim(),
                website: _websiteController.text.trim().isEmpty
                    ? null
                    : _websiteController.text.trim(),
              ),
            );
      } else {
        await ref.read(startupServiceProvider).updateStartup(
              _startup!.copyWith(
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
                industry: _industry,
                aluProgram: _programController.text.trim(),
                website: _websiteController.text.trim().isEmpty
                    ? null
                    : _websiteController.text.trim(),
              ),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save startup profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Startup Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_startup != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VerificationBadge(status: _startup!.verificationStatus),
            ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Startup Name'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _industry,
            decoration: const InputDecoration(labelText: 'Industry'),
            items: AppConstants.industries
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _industry = v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _programController,
            decoration: const InputDecoration(labelText: 'ALU Program'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website (optional)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
