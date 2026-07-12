import 'package:flutter_test/flutter_test.dart';

import 'package:alu_venture_link/models/opportunity_model.dart';
import 'package:alu_venture_link/providers/app_providers.dart';

void main() {
  group('filterOpportunities', () {
    final opportunities = [
      const Opportunity(
        id: '1',
        startupId: 's1',
        startupName: 'EduStart',
        title: 'Flutter Developer Intern',
        description: 'Build mobile apps',
        skills: ['Software Development'],
        type: 'Internship',
        isRemote: true,
      ),
      const Opportunity(
        id: '2',
        startupId: 's2',
        startupName: 'MarketHub',
        title: 'Marketing Assistant',
        description: 'Social media campaigns',
        skills: ['Marketing'],
        type: 'Volunteer',
        isRemote: false,
      ),
    ];

    test('filters by search query', () {
      final result = filterOpportunities(
        opportunities,
        const OpportunityFilter(query: 'flutter'),
      );
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('filters by skill and remote', () {
      final result = filterOpportunities(
        opportunities,
        const OpportunityFilter(skill: 'Marketing', remoteOnly: false),
      );
      expect(result.length, 1);
      expect(result.first.id, '2');
    });
  });
}
