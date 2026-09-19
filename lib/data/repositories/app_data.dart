import '../models/models.dart';

/// Static seed data matching Figma / App.tsx exactly.
abstract final class AppData {
  static const platforms = <PlatformModel>[
    PlatformModel(id: 'facebook', name: 'Facebook', color: 0xFF1877F2, accounts: ['Company Page', 'Brand Page', 'Personal Profile']),
    PlatformModel(id: 'instagram', name: 'Instagram', color: 0xFFE1306C, accounts: ['Brand Account', 'Product Account']),
    PlatformModel(id: 'threads', name: 'Threads', color: 0xFF000000, accounts: ['Main Profile']),
    PlatformModel(id: 'linkedin', name: 'LinkedIn', color: 0xFF0A66C2, accounts: ['Personal Profile']),
    // PlatformModel(id: 'linkedin_organization', name: 'LinkedIn Organization', color: 0xFFD4AF37, accounts: ['Company Page']),
    PlatformModel(id: 'tiktok', name: 'TikTok', color: 0xFF010101, accounts: ['Main Account']),
    PlatformModel(id: 'x', name: 'X (Twitter)', color: 0xFF000000, accounts: ['Main Profile', 'Support Handle']),
    PlatformModel(id: 'pinterest', name: 'Pinterest', color: 0xFFE60023, accounts: ['Brand Board']),
    PlatformModel(id: 'youtube', name: 'YouTube', color: 0xFFFF0000, accounts: ['Main Channel']),
    PlatformModel(id: 'google', name: 'Google Business', color: 0xFF4285F4, accounts: ['Primary Location']),
    PlatformModel(id: 'snapchat', name: 'Snapchat', color: 0xFFFFFC00, accounts: ['Public Profile']),
  ];

  static const initials = <String, String>{
    'facebook': 'f',
    'instagram': 'ig',
    'threads': '@',
    'linkedin': 'in',
    // 'linkedin_organization': 'in',
    'tiktok': 'tt',
    'x': 'X',
    'pinterest': 'P',
    'youtube': '▶',
    'google': 'G',
    'snapchat': 'S',
  };

  static String platformName(String id) {
    final key = id.toLowerCase();
    for (final p in platforms) {
      if (p.id == key) return p.name;
    }
    if (key == 'linkedin_organization') return 'LinkedIn Organization';
    if (key.isEmpty) return id;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  static const posts = <PostModel>[
    PostModel(
      id: '1',
      title: 'Q4 Product Launch Campaign',
      caption: "Exciting news! Our latest product update is live. Discover how we're transforming the way teams collaborate. #ProductLaunch #Innovation",
      platforms: ['facebook', 'instagram', 'linkedin'],
      status: PostStatus.scheduled,
      publishAt: 'Jan 22 · 10:00 AM',
      thumbnail: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=80&h=80&fit=crop&auto=format',
    ),
    PostModel(
      id: '2',
      title: 'Weekly Tips & Tricks',
      caption: 'Here are 5 productivity hacks that will change how you work. Save this for later!',
      platforms: ['instagram', 'tiktok', 'x'],
      status: PostStatus.published,
      publishAt: 'Jan 15 · 2:00 PM',
      thumbnail: 'https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=80&h=80&fit=crop&auto=format',
    ),
    PostModel(
      id: '3',
      title: 'Behind the Scenes: Team Retreat',
      caption: 'A peek inside our annual team retreat. Culture is everything. #TeamWork',
      platforms: ['linkedin', 'facebook'],
      status: PostStatus.draft,
      thumbnail: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=80&h=80&fit=crop&auto=format',
    ),
    PostModel(
      id: '4',
      title: 'Customer Success Story',
      caption: 'How Acme Corp increased their social engagement by 340% using SocialSyncc.',
      platforms: ['linkedin', 'x'],
      status: PostStatus.failed,
      publishAt: 'Jan 12 · 9:00 AM',
      thumbnail: 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=80&h=80&fit=crop&auto=format',
    ),
    PostModel(
      id: '5',
      title: 'New Feature: AI Captions',
      caption: 'Introducing AI-powered captions. Write less, publish more. Available now for Pro users.',
      platforms: ['facebook', 'instagram', 'linkedin', 'x'],
      status: PostStatus.scheduled,
      publishAt: 'Jan 25 · 3:00 PM',
      thumbnail: 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=80&h=80&fit=crop&auto=format',
    ),
    PostModel(
      id: '6',
      title: 'Industry Insights Report 2024',
      caption: "We analyzed 10M+ posts across 8 platforms. Here's what the data tells us about 2024 social trends.",
      platforms: ['linkedin'],
      status: PostStatus.published,
      publishAt: 'Jan 8 · 8:00 AM',
      thumbnail: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=80&h=80&fit=crop&auto=format',
    ),
  ];

  static const notifications = <NotificationModel>[
    NotificationModel(id: '1', type: 'success', title: 'Post Published', body: 'Q4 Campaign was published to Facebook, Instagram, LinkedIn.', time: '2 min ago', read: false),
    NotificationModel(id: '2', type: 'failed', title: 'Publishing Failed', body: 'Weekly Tips failed to publish to TikTok. Token expired.', time: '1 hr ago', read: false),
    NotificationModel(id: '3', type: 'expired', title: 'Connection Expired', body: 'Your Instagram Brand Account needs to be reconnected.', time: '3 hrs ago', read: false),
    NotificationModel(id: '4', type: 'billing', title: '85% of Post Limit', body: 'Upgrade your plan to unlock unlimited posts.', time: 'Yesterday', read: true),
    NotificationModel(id: '5', type: 'clock', title: 'Post in 30 Minutes', body: 'AI Captions post is scheduled to go live at 3:00 PM.', time: 'Yesterday', read: true),
  ];

  static const analyticsTrend = <TrendPoint>[
    TrendPoint(date: 'Jan 1', pub: 12, fail: 1),
    TrendPoint(date: 'Jan 8', pub: 18, fail: 2),
    TrendPoint(date: 'Jan 15', pub: 24, fail: 0),
    TrendPoint(date: 'Jan 22', pub: 21, fail: 1),
    TrendPoint(date: 'Jan 29', pub: 32, fail: 2),
  ];

  static const analyticsFreq = <FreqPoint>[
    FreqPoint(day: 'Mon', v: 4),
    FreqPoint(day: 'Tue', v: 7),
    FreqPoint(day: 'Wed', v: 5),
    FreqPoint(day: 'Thu', v: 9),
    FreqPoint(day: 'Fri', v: 6),
    FreqPoint(day: 'Sat', v: 3),
    FreqPoint(day: 'Sun', v: 2),
  ];

  static const platformPie = <PieSlice>[
    PieSlice(name: 'LinkedIn', value: 32, color: 0xFF0A66C2),
    PieSlice(name: 'Instagram', value: 28, color: 0xFFE1306C),
    PieSlice(name: 'Facebook', value: 22, color: 0xFF1877F2),
    PieSlice(name: 'X', value: 11, color: 0xFF555555),
    PieSlice(name: 'TikTok', value: 7, color: 0xFF010101),
  ];

  static const calEvents = <int, List<CalEvent>>{
    5: [CalEvent(title: 'Product Update', platforms: ['facebook', 'linkedin'], time: '10:00 AM')],
    10: [CalEvent(title: 'Weekly Tips', platforms: ['instagram', 'tiktok'], time: '2:00 PM')],
    15: [
      CalEvent(title: 'Team Retreat BTS', platforms: ['linkedin'], time: '9:00 AM'),
      CalEvent(title: 'Promo Story', platforms: ['instagram'], time: '4:00 PM'),
    ],
    20: [CalEvent(title: 'Q4 Launch', platforms: ['facebook', 'instagram', 'linkedin'], time: '10:00 AM')],
    25: [CalEvent(title: 'AI Feature', platforms: ['facebook', 'instagram', 'linkedin', 'x'], time: '3:00 PM')],
  };

  static const plans = <PlanModel>[
    PlanModel(name: 'Free', price: '\$0', period: '/mo', features: ['3 accounts', '10 posts/mo', '1 workspace', 'Basic analytics']),
    PlanModel(name: 'Starter', price: '\$19', period: '/mo', features: ['10 accounts', '100 posts/mo', '3 workspaces', 'Advanced analytics', 'Bulk scheduling']),
    PlanModel(name: 'Professional', price: '\$49', period: '/mo', features: ['25 accounts', 'Unlimited posts', '10 workspaces', 'AI captions', 'Priority support'], current: true, popular: true),
    PlanModel(name: 'Enterprise', price: 'Custom', period: '', features: ['Unlimited accounts', 'Unlimited posts', 'Custom analytics', 'Dedicated support', 'SSO & SAML']),
  ];

  static const avatarUrl = 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=88&h=88&fit=crop&auto=format';
  static const previewImageUrl = 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=250&fit=crop';

  static PlatformModel? platformById(String id) {
    try {
      return platforms.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
