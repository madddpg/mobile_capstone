/// Targets on [MainHomeScreen] the first-login tour can spotlight.
enum HomeGuideTarget {
  welcome,
  startEstimate,
  postBidding,
  canvassTracking,
}

class HomeGuideStep {
  final HomeGuideTarget target;
  final String title;
  final String body;
  final String nextLabel;

  const HomeGuideStep({
    required this.target,
    required this.title,
    required this.body,
    required this.nextLabel,
  });
}

/// Short, skippable tour shown after a builder's first login.
///
/// Copy stays in the planning / canvassing phase: estimate materials, request
/// quotations, compare bids. It does not describe on-site construction.
List<HomeGuideStep> homeGuideSteps({String? firstName}) {
  final trimmed = firstName?.trim() ?? '';
  final greet = trimmed.isNotEmpty && trimmed.toLowerCase() != 'user'
      ? 'Welcome, $trimmed.'
      : 'Welcome.';

  return [
    HomeGuideStep(
      target: HomeGuideTarget.welcome,
      title: greet,
      body:
          'iConstruct helps you plan materials and canvass hardware shops — before you buy. Here is the path.',
      nextLabel: "Let's go",
    ),
    const HomeGuideStep(
      target: HomeGuideTarget.startEstimate,
      title: 'Start here',
      body:
          'Name an estimate, then plan materials with AI or a template. Quantities scale to your floor area.',
      nextLabel: 'Next',
    ),
    const HomeGuideStep(
      target: HomeGuideTarget.postBidding,
      title: 'Ask shops for prices',
      body:
          'When the list looks right, request private quotations from hardware shops.',
      nextLabel: 'Next',
    ),
    const HomeGuideStep(
      target: HomeGuideTarget.canvassTracking,
      title: 'Compare and choose',
      body:
          'Watch offers come in, compare them side by side, and pick a supplier.',
      nextLabel: 'Got it',
    ),
  ];
}
