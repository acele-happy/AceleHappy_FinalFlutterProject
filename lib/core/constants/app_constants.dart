class AppConstants {
  static const appName = 'VentureLink';
  static const appTagline = 'ALU Internship & Startup Hub';

  static const aluEmailDomains = ['alueducation.com', 'alustudent.com'];

  static bool isAllowedAluEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return aluEmailDomains.any((domain) => normalized.endsWith('@$domain'));
  }

  static String get aluEmailDomainsLabel =>
      aluEmailDomains.map((domain) => '@$domain').join(' or ');

  static const collectionUsers = 'users';
  static const collectionStartups = 'startups';
  static const collectionOpportunities = 'opportunities';
  static const collectionApplications = 'applications';
  static const collectionNotifications = 'notifications';
  static const collectionBookmarks = 'bookmarks';

  static const studentSkills = [
    'Software Development',
    'UI/UX Design',
    'Marketing',
    'Operations',
    'Research',
    'Business Analysis',
    'Content Creation',
    'Community Management',
    'Data Analysis',
    'Product Management',
  ];

  static const industries = [
    'EdTech',
    'FinTech',
    'HealthTech',
    'AgriTech',
    'E-Commerce',
    'Social Impact',
    'Media',
    'SaaS',
    'Other',
  ];

  static const opportunityTypes = ['Internship', 'Project', 'Volunteer'];
}
