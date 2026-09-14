import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';
import '../widgets/stitch_formatted_text.dart';
import '../services/supabase_service.dart';
import '../config/gemini_config.dart';
import '../services/gemini_service.dart';

enum UserReaction { none, liked, disliked }

class ReportCommentItem {
  final String id;
  final String author;
  final String comment;
  final String userLocality;
  final String time;

  ReportCommentItem({
    required this.id,
    required this.author,
    required this.comment,
    this.userLocality = 'Ahmedabad',
    this.time = 'Recent',
  });
}

class TransitReportItem {
  final String id;
  final String reporterName;
  final String reportType;
  final String severity; // 'critical', 'high', 'medium', 'low'
  final String title;
  final String description;
  final String locationName;
  final String routeTag;
  int upvotes;
  bool isUpvoted;
  final String status;
  final String time;
  bool isCommentsExpanded;
  final List<ReportCommentItem> comments;

  TransitReportItem({
    required this.id,
    required this.reporterName,
    required this.reportType,
    required this.severity,
    required this.title,
    required this.description,
    required this.locationName,
    this.routeTag = 'Corridor #9 BRTS',
    this.upvotes = 1,
    this.isUpvoted = false,
    this.status = 'ACTIVE',
    this.time = '15m ago',
    this.isCommentsExpanded = false,
    required this.comments,
  });
}

class AnswerItem {
  final String id;
  final String author;
  final String? roleBadge;
  final String time;
  final String content;
  final String avatarLetter;
  final Color avatarColor;
  int likes;
  int dislikes;
  UserReaction reaction;

  AnswerItem({
    required this.id,
    required this.author,
    this.roleBadge,
    required this.time,
    required this.content,
    required this.avatarLetter,
    required this.avatarColor,
    required this.likes,
    required this.dislikes,
    this.reaction = UserReaction.none,
  });
}

class QuestionItem {
  final String id;
  final String author;
  final String role;
  final String timeLocation;
  final String badgeText;
  final Color badgeColor;
  final String question;
  int upvotes;
  bool isUpvoted;
  final String routeTag;
  final String category; // 'all', 'airport', 'interchange', 'night', 'student'
  bool isThreadExpanded;
  final List<AnswerItem> answers;
  final AnswerItem? pinnedGuide;

  QuestionItem({
    required this.id,
    required this.author,
    required this.role,
    required this.timeLocation,
    required this.badgeText,
    required this.badgeColor,
    required this.question,
    required this.upvotes,
    this.isUpvoted = false,
    required this.routeTag,
    required this.category,
    this.isThreadExpanded = true,
    required this.answers,
    this.pinnedGuide,
  });
}

class StitchAskRouteScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final void Function(String location, String incident)? onNavigateToRouteWithFocus;

  const StitchAskRouteScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToPasses,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.onNavigateToRouteWithFocus,
  });

  @override
  State<StitchAskRouteScreen> createState() => _StitchAskRouteScreenState();
}

class _StitchAskRouteScreenState extends State<StitchAskRouteScreen> {
  String _selectedCategory = 'all';
  int _activeViewTab = 0; // 0: Community Q&A, 1: Live Reports & Hazards
  String _selectedReportFilter = 'all';

  // Input Controllers for "Ask Commuters" Card
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  // Reply Controllers per card
  final Map<String, TextEditingController> _replyControllers = {};

  // Report Submission Controllers
  final TextEditingController _reportTitleController = TextEditingController();
  final TextEditingController _reportDescController = TextEditingController();
  final TextEditingController _reportLocationController = TextEditingController();
  final TextEditingController _reportRouteController = TextEditingController();
  String _selectedReportType = 'waterlogging';
  String _selectedReportSeverity = 'high';
  final Map<String, TextEditingController> _reportCommentControllers = {};

  // AI Chatbot State (Static in-memory chat session persists across screen switches until app closes)
  final TextEditingController _geminiInputController = TextEditingController();
  static final List<Map<String, String>> _geminiChatMessages = [
    {
      'role': 'assistant',
      'text':
          'Hello! I am your AI Transit Assistant. I monitor live incident reports, waterlogging, metro delays, and detours across Ahmedabad. How can I help your commute today?'
    }
  ];
  bool _isGeminiThinking = false;

  final Set<String> _selectedTags = {'Fastest Leg'};
  String _posterType = 'Traveler';
  String? _toastMessage;
  Timer? _toastTimer;

  late List<QuestionItem> _questions;
  late List<TransitReportItem> _reports;
  bool _isLoadingCloud = false;
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _initDefaultQuestions();
    _initDefaultReports();
    _loadQuestionsFromSupabase();
    _loadReportsFromSupabase();
  }

  Future<void> _loadQuestionsFromSupabase() async {
    setState(() => _isLoadingCloud = true);
    try {
      final cloudQuestions = await SupabaseService.instance.fetchQuestions(
        category: _selectedCategory,
      );
      if (cloudQuestions != null && cloudQuestions.isNotEmpty && mounted) {
        final List<QuestionItem> parsed = [];
        for (final raw in cloudQuestions) {
          final List<AnswerItem> answers = [];
          final rawAnswers = raw['answers'] as List<dynamic>? ?? [];
          for (final a in rawAnswers) {
            answers.add(
              AnswerItem(
                id: a['id']?.toString() ??
                    'ans_${DateTime.now().millisecondsSinceEpoch}',
                author: a['author'] ?? 'Commuter',
                roleBadge: a['role_badge'],
                time: 'Recent',
                content: a['content'] ?? '',
                avatarLetter: (a['avatar_letter'] ?? 'C').toString(),
                avatarColor: const Color(0xFF06B6D4),
                likes: (a['likes'] as num?)?.toInt() ?? 0,
                dislikes: (a['dislikes'] as num?)?.toInt() ?? 0,
                reaction: UserReaction.none,
              ),
            );
          }

          parsed.add(
            QuestionItem(
              id: raw['id']?.toString() ??
                  'q_${DateTime.now().millisecondsSinceEpoch}',
              author: raw['author'] ?? 'Commuter',
              role: raw['role'] ?? 'Traveler',
              timeLocation: raw['origin'] != null
                  ? 'Live • ${raw['origin']}'
                  : 'Live inquiry',
              badgeText: raw['badge_text'] ?? 'LIVE INQUIRY',
              badgeColor: const Color(0xFF00E5FF),
              question: raw['question'] ?? '',
              upvotes: (raw['upvotes'] as num?)?.toInt() ?? 1,
              routeTag: raw['route_tag'] ?? 'Leg #LIVE',
              category: raw['category'] ?? 'all',
              isThreadExpanded: true,
              answers: answers,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _questions = parsed;
          });
        }
      }
    } catch (e) {
      debugPrint('[AskRouteScreen] cloud fetch notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCloud = false);
      }
    }
  }

  Future<void> _loadReportsFromSupabase() async {
    setState(() => _isLoadingReports = true);
    try {
      final cloudReports = await SupabaseService.instance.fetchReports();
      if (cloudReports != null && cloudReports.isNotEmpty && mounted) {
        final List<TransitReportItem> parsed = [];
        for (final r in cloudReports) {
          final List<ReportCommentItem> comments = [];
          final rawComments = r['comments'] as List<dynamic>? ?? [];
          for (final c in rawComments) {
            comments.add(
              ReportCommentItem(
                id: c['id']?.toString() ??
                    'c_${DateTime.now().millisecondsSinceEpoch}',
                author: c['author'] ?? 'Commuter',
                comment: c['comment'] ?? '',
                userLocality: c['user_locality'] ?? 'Ahmedabad',
                time: 'Recent',
              ),
            );
          }

          parsed.add(
            TransitReportItem(
              id: r['id']?.toString() ??
                  'rep_${DateTime.now().millisecondsSinceEpoch}',
              reporterName: r['reporter_name'] ?? 'Commuter',
              reportType: r['report_type'] ?? 'hazard',
              severity: r['severity'] ?? 'medium',
              title: r['title'] ?? 'Transit Incident',
              description: r['description'] ?? '',
              locationName: r['location_name'] ?? 'Transit Corridor',
              routeTag: r['route_tag'] ?? 'Corridor #9 BRTS',
              upvotes: (r['upvotes'] as num?)?.toInt() ?? 1,
              isUpvoted: false,
              status: r['status'] ?? 'ACTIVE',
              time: 'Recent',
              comments: comments,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _reports = parsed;
          });
        }
      }
    } catch (e) {
      debugPrint('[AskRouteScreen] cloud fetch reports notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
    }
  }

  void _initDefaultReports() {
    _reports = [
      TransitReportItem(
        id: 'rep_1',
        reporterName: 'Kavita S. (BRTS Marshal)',
        reportType: 'waterlogging',
        severity: 'critical',
        title: 'Severe Waterlogging Under Akhbarnagar Underpass',
        description:
            'Akhbarnagar underpass flooded up to 2.5 feet. BRTS buses #4D and #9 are rerouted via 132ft Ring Road. Avoid this route!',
        locationName: 'Akhbarnagar Underpass',
        routeTag: 'Corridor #9 BRTS',
        upvotes: 42,
        isUpvoted: false,
        status: 'ACTIVE',
        time: '12m ago',
        comments: [
          ReportCommentItem(
            id: 'rc_1_1',
            author: 'Ramesh (Traffic Volunteer)',
            comment:
                'Traffic police divert vehicles to Subhash Bridge circle. Metro Line 1 unaffected.',
            userLocality: 'Akhbarnagar',
            time: '8m ago',
          ),
          ReportCommentItem(
            id: 'rc_1_2',
            author: 'Sneha',
            comment: 'Water pump deployed by AMC, expect 45m delay.',
            userLocality: 'Nava Vadaj',
            time: '5m ago',
          ),
        ],
      ),
      TransitReportItem(
        id: 'rep_2',
        reporterName: 'Vikram Patel',
        reportType: 'metro_delay',
        severity: 'medium',
        title: 'Metro Line 1 Signaling Maintenance - 8m Delay',
        description:
            'Trains running at 15-minute headway between Old High Court and Apparel Park due to track signal calibration.',
        locationName: 'Old High Court Interchange',
        routeTag: 'Metro Line 1 (Red)',
        upvotes: 19,
        isUpvoted: false,
        status: 'ACTIVE',
        time: '25m ago',
        comments: [
          ReportCommentItem(
            id: 'rc_2_1',
            author: 'Amit B.',
            comment:
                'Ticket counter line at Old High Court is very long; use QR / UPI ticket from app.',
            userLocality: 'Navrangpura',
            time: '18m ago',
          ),
        ],
      ),
      TransitReportItem(
        id: 'rep_3',
        reporterName: 'Rhea Deshmukh',
        reportType: 'breakdown',
        severity: 'high',
        title: 'Electric Bus Breakdown on Nehru Bridge',
        description:
            'AMTS route 151 EV bus broken down near Nehru Bridge west ramp. Single lane bottleneck causing 20 min snarl.',
        locationName: 'Nehru Bridge Ramp',
        routeTag: 'AMTS Route 151',
        upvotes: 27,
        isUpvoted: false,
        status: 'ACTIVE',
        time: '40m ago',
        comments: [
          ReportCommentItem(
            id: 'rc_3_1',
            author: 'Mehul K.',
            comment:
                'Take Ellis Bridge or Sardar Bridge instead for smooth crossing.',
            userLocality: 'Paldi',
            time: '32m ago',
          ),
        ],
      ),
      TransitReportItem(
        id: 'rep_4',
        reporterName: 'Tarun Joshi',
        reportType: 'crowding',
        severity: 'medium',
        title: 'Massive Peak Rush at Kalupur Railway Metro Hub',
        description:
            'Concourse packed due to arrival of Vande Bharat express. Security frisking taking 10+ mins.',
        locationName: 'Kalupur Metro Station',
        routeTag: 'Interchange Hub',
        upvotes: 31,
        isUpvoted: false,
        status: 'ACTIVE',
        time: '55m ago',
        comments: [
          ReportCommentItem(
            id: 'rc_4_1',
            author: 'Deepak',
            comment: 'Gate 2 (side exit) has shorter security queue!',
            userLocality: 'Kalupur',
            time: '45m ago',
          ),
        ],
      ),
    ];
  }

  void _initDefaultQuestions() {
    _questions = [
      QuestionItem(
        id: 'q1',
        author: 'Nehal M.',
        role: 'Traveler',
        timeLocation: '12m ago • Kalupur Stn',
        badgeText: 'NEW TO CITY',
        badgeColor: const Color(0xFF10B981),
        question:
            'Just reached Kalupur with two trolley bags. Need to reach SG Highway (Prahlad Nagar). Should I take Metro Line 1 or direct BRTS? Which interchange has escalators/lifts?',
        upvotes: 15,
        routeTag: 'Leg #KAL-PRA',
        category: 'airport',
        isThreadExpanded: true,
        answers: [
          AnswerItem(
            id: 'a1_1',
            author: 'Dev',
            roleBadge: 'Top Contributor',
            time: '8m ago',
            content:
                'Take Metro Line 1 to Commerce Six Roads, then switch to BRTS corridor 9. Concourse is sheltered and has functioning lifts for luggage.',
            avatarLetter: 'D',
            avatarColor: const Color(0xFF06B6D4),
            likes: 24,
            dislikes: 1,
            reaction: UserReaction.none,
          ),
          AnswerItem(
            id: 'a1_2',
            author: 'Farhan',
            time: '5m ago',
            content:
                'Avoid changing at Geeta Mandir during peak 9 AM rush. Take the direct electric express bus 4U.',
            avatarLetter: 'F',
            avatarColor: const Color(0xFF10B981),
            likes: 18,
            dislikes: 0,
            reaction: UserReaction.none,
          ),
        ],
      ),
      QuestionItem(
        id: 'q2',
        author: 'Ananya K.',
        role: 'Student',
        timeLocation: '35m ago • Iskcon',
        badgeText: 'CAMPUS',
        badgeColor: const Color(0xFFF59E0B),
        question:
            'What is the best feeder bus connection from Iskcon Crossroad to PDPU Gandhinagar in morning peak hours?',
        upvotes: 9,
        routeTag: 'PDPU Feeder',
        category: 'student',
        isThreadExpanded: true,
        pinnedGuide: AnswerItem(
          id: 'pinned_1',
          author: 'AMTS Marshall',
          roleBadge: 'Verified Guide',
          time: 'Verified',
          content:
              'Catch Route 8D Feeder departing Bay 3 at 8:10 AM sharp. It bypasses SG highway jams directly to PDPU Bhaijipura point.',
          avatarLetter: 'M',
          avatarColor: const Color(0xFF10B981),
          likes: 31,
          dislikes: 0,
          reaction: UserReaction.none,
        ),
        answers: [
          AnswerItem(
            id: 'a2_1',
            author: 'Karan',
            time: '14m ago',
            content:
                'Transit AI student concession QR scanned instantly on reader 2 today without long ticket queues.',
            avatarLetter: 'K',
            avatarColor: const Color(0xFF38BDF8),
            likes: 7,
            dislikes: 0,
            reaction: UserReaction.none,
          ),
        ],
      ),
      QuestionItem(
        id: 'q3',
        author: 'Rohan V.',
        role: 'Commuter',
        timeLocation: '1h ago • Ranip',
        badgeText: 'NIGHT ROUTE',
        badgeColor: const Color(0xFFA855F7),
        question:
            'Does the Gandhinagar Metro connect to GIFT City after 10 PM on weekends, or should I take the GSRTC AC EV Bus?',
        upvotes: 21,
        routeTag: 'GIFT Express',
        category: 'night',
        isThreadExpanded: true,
        answers: [
          AnswerItem(
            id: 'a3_1',
            author: 'Pooja S.',
            roleBadge: 'GIFT City',
            time: '42m ago',
            content:
                'Metro closes service at 9:45 PM on Sundays. Best option is the GIFT City Shuttle EV bus from Ranip Bay 6 which runs till 11:30 PM.',
            avatarLetter: 'P',
            avatarColor: const Color(0xFFA855F7),
            likes: 14,
            dislikes: 0,
            reaction: UserReaction.none,
          ),
        ],
      ),
    ];
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  void _toggleReaction(AnswerItem answer, UserReaction targetReaction) {
    setState(() {
      if (answer.reaction == targetReaction) {
        // Untoggle reaction
        if (targetReaction == UserReaction.liked) {
          answer.likes = (answer.likes - 1).clamp(0, 99999);
        } else {
          answer.dislikes = (answer.dislikes - 1).clamp(0, 99999);
        }
        answer.reaction = UserReaction.none;
      } else {
        // Reversing previous reaction
        if (answer.reaction == UserReaction.liked) {
          answer.likes = (answer.likes - 1).clamp(0, 99999);
        } else if (answer.reaction == UserReaction.disliked) {
          answer.dislikes = (answer.dislikes - 1).clamp(0, 99999);
        }

        // Applying new reaction
        if (targetReaction == UserReaction.liked) {
          answer.likes++;
        } else {
          answer.dislikes++;
        }
        answer.reaction = targetReaction;
      }
    });

    // Sync reaction count to Supabase backend asynchronously
    SupabaseService.instance.syncAnswerReaction(
      answerId: answer.id,
      likes: answer.likes,
      dislikes: answer.dislikes,
    );
  }

  void _toggleUpvote(QuestionItem item) {
    setState(() {
      item.isUpvoted = !item.isUpvoted;
      item.upvotes += item.isUpvoted ? 1 : -1;
    });

    // Sync upvote count to Supabase backend asynchronously
    SupabaseService.instance.syncQuestionUpvote(
      questionId: item.id,
      upvotes: item.upvotes,
    );
  }

  void _submitQuestion() {
    final qText = _questionController.text.trim();
    if (qText.isEmpty) {
      _showToast('Please type your question before asking commuters');
      return;
    }

    final from = _originController.text.trim().isEmpty
        ? 'Current Hub'
        : _originController.text.trim();
    final to = _destController.text.trim().isEmpty
        ? 'Ahmedabad'
        : _destController.text.trim();

    final newQ = QuestionItem(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      author: 'You',
      role: _posterType,
      timeLocation: 'Just now • $from',
      badgeText: _selectedTags.isNotEmpty
          ? _selectedTags.first.toUpperCase()
          : 'LIVE INQUIRY',
      badgeColor: const Color(0xFF00E5FF),
      question: '$qText\n\nRoute: From $from to $to',
      upvotes: 1,
      isUpvoted: true,
      routeTag: 'Leg #AMD-LIVE',
      category: _selectedCategory,
      isThreadExpanded: true,
      answers: [],
    );

    setState(() {
      _questions.insert(0, newQ);
      _originController.clear();
      _destController.clear();
      _questionController.clear();
    });

    // Persist question to Supabase backend
    SupabaseService.instance.postQuestion(
      author: 'You',
      role: _posterType,
      question: '$qText\n\nRoute: From $from to $to',
      origin: from,
      destination: to,
      routeTag: 'Leg #AMD-LIVE',
      category: _selectedCategory,
      badgeText: _selectedTags.isNotEmpty
          ? _selectedTags.first.toUpperCase()
          : 'LIVE INQUIRY',
    );

    _showToast('Broadcasting question to 140+ active commuters!');
    _triggerGeminiAnswerForQuestion(newQ, from, to, qText);
  }

  void _addReply(QuestionItem item) {
    final controller = _replyControllers[item.id];
    final text = controller?.text.trim() ?? '';
    if (text.isEmpty) return;

    final newAnswer = AnswerItem(
      id: 'ans_${DateTime.now().millisecondsSinceEpoch}',
      author: 'You (Commuter)',
      roleBadge: 'Advice',
      time: 'Just now',
      content: text,
      avatarLetter: 'Y',
      avatarColor: const Color(0xFF00E5FF),
      likes: 1,
      dislikes: 0,
      reaction: UserReaction.liked,
    );

    setState(() {
      item.answers.add(newAnswer);
      item.isThreadExpanded = true;
      controller?.clear();
    });

    // Save reply to Supabase backend
    SupabaseService.instance.postAnswer(
      questionId: item.id,
      author: 'You (Commuter)',
      roleBadge: 'Advice',
      content: text,
      avatarLetter: 'Y',
    );

    _showToast('Your advice was shared with the commuter thread!');
  }

  void _toggleReportUpvote(TransitReportItem item) {
    setState(() {
      item.isUpvoted = !item.isUpvoted;
      item.upvotes += item.isUpvoted ? 1 : -1;
    });

    SupabaseService.instance.syncReportUpvote(
      reportId: item.id,
      upvotes: item.upvotes,
    );
  }

  void _submitReportComment(TransitReportItem report) {
    final controller = _reportCommentControllers[report.id];
    final text = controller?.text.trim() ?? '';
    if (text.isEmpty) return;

    final newComment = ReportCommentItem(
      id: 'rc_${DateTime.now().millisecondsSinceEpoch}',
      author: 'You (Commuter)',
      comment: text,
      userLocality: 'Local Commuter',
      time: 'Just now',
    );

    setState(() {
      report.comments.add(newComment);
      controller?.clear();
    });

    SupabaseService.instance.submitReportComment(
      reportId: report.id,
      author: 'You (Commuter)',
      comment: text,
      userLocality: 'Local Commuter',
    );

    _showToast('Comment added to live incident report!');
    _triggerGeminiReportInsight(report, text);
  }

  void _submitNewReport() {
    final title = _reportTitleController.text.trim();
    final desc = _reportDescController.text.trim();
    final loc = _reportLocationController.text.trim().isEmpty
        ? 'Ahmedabad Transit Hub'
        : _reportLocationController.text.trim();
    final route = _reportRouteController.text.trim().isEmpty
        ? 'City Corridor'
        : _reportRouteController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _showToast('Please enter both title and incident details');
      return;
    }

    final newReport = TransitReportItem(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      reporterName: 'You (Verified Commuter)',
      reportType: _selectedReportType,
      severity: _selectedReportSeverity,
      title: title,
      description: desc,
      locationName: loc,
      routeTag: route,
      upvotes: 1,
      isUpvoted: true,
      status: 'ACTIVE',
      time: 'Just now',
      comments: [],
    );

    setState(() {
      _reports.insert(0, newReport);
      _reportTitleController.clear();
      _reportDescController.clear();
      _reportLocationController.clear();
      _reportRouteController.clear();
    });

    SupabaseService.instance.submitReport(
      reporterName: 'You (Verified Commuter)',
      reportType: _selectedReportType,
      severity: _selectedReportSeverity,
      title: title,
      description: desc,
      locationName: loc,
      routeTag: route,
    );

    Navigator.of(context).pop();
    _showToast('🚨 Live incident report broadcasted to all commuters!');
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _questionController.dispose();
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    _reportTitleController.dispose();
    _reportDescController.dispose();
    _reportLocationController.dispose();
    _reportRouteController.dispose();
    _geminiInputController.dispose();
    for (final c in _reportCommentControllers.values) {
      c.dispose();
    }
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final brandPillBg =
        dark ? const Color(0xB30F172A) : const Color(0xE6FFFFFF);
    final brandPillBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0x40FFFFFF);
    final inputBg =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final inputBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0xFFCBD5E1);

    final filteredQuestions = _selectedCategory == 'all'
        ? _questions
        : _questions.where((q) => q.category == _selectedCategory).toList();

    final filteredReports = _selectedReportFilter == 'all'
        ? _reports
        : _reports.where((r) => r.reportType == _selectedReportFilter).toList();

    return StitchBackground(
      isDarkMode: dark,
      child: Stack(
        children: [
          // Main Scrollable Area
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 8,
                    bottom: 110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. TOP HEADER BAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Back button + Transit AI Brand Pill
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Back button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onNavigateToHome,
                                  borderRadius: BorderRadius.circular(19),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: brandPillBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: brandPillBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: primaryTextColor,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Brand Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: brandPillBg,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: brandPillBorder,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dark
                                          ? Colors.black.withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00E5FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus_rounded,
                                        color: Color(0xFF00354A),
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transit AI',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF10B981),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Right: Profile button (Linked to Auth/Login) + Theme Toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StitchProfileButton(
                                isDarkMode: dark,
                                onTap: widget.onNavigateToProfile,
                              ),
                              const SizedBox(width: 6),
                              StitchThemeToggleButton(
                                isDarkMode: dark,
                                onToggleTheme: widget.onToggleTheme,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 2. PAGE TITLE & OVERVIEW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF00E5FF),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Ask Locals & Route Q&A',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: primaryTextColor,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5FF)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: Color(0xFF00E5FF),
                                            size: 9,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Ahmedabad Hub',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF00E5FF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _isLoadingCloud
                                              ? const SizedBox(
                                                  width: 9,
                                                  height: 9,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.cloud_done_rounded,
                                                  color: Color(0xFF10B981),
                                                  size: 9,
                                                ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _isLoadingCloud
                                                ? 'Syncing...'
                                                : 'Supabase Synced',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ask local commuters for live BRTS/Metro connections & shortcuts.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: secondaryTextColor,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // SEGMENT SWITCHER: Community Q&A vs Live Reports & Hazards
                      _buildSegmentSwitcher(dark),

                      const SizedBox(height: 12),

                      if (_activeViewTab == 0) ...[
                        // 3. CATEGORY FILTER PILLS
                        SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildCategoryPill(
                              id: 'all',
                              label: 'All Questions',
                              badgeCount: '28',
                              icon: Icons.layers_rounded,
                              dark: dark,
                            ),
                            _buildCategoryPill(
                              id: 'airport',
                              label: 'New in City / Airport',
                              badgeCount: null,
                              icon: Icons.flight_land_rounded,
                              dark: dark,
                            ),
                            _buildCategoryPill(
                              id: 'interchange',
                              label: 'Best Interchange Hub',
                              badgeCount: null,
                              icon: Icons.alt_route_rounded,
                              dark: dark,
                            ),
                            _buildCategoryPill(
                              id: 'night',
                              label: 'Night Routes',
                              badgeCount: null,
                              icon: Icons.nightlight_round,
                              dark: dark,
                            ),
                            _buildCategoryPill(
                              id: 'student',
                              label: 'Student / Campus',
                              badgeCount: null,
                              icon: Icons.school_rounded,
                              dark: dark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4. "ASK LOCAL COMMUTERS" SUBMISSION CARD
                      StitchGlassCard(
                        isDarkMode: dark,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.explore_outlined,
                                    color: Color(0xFF00E5FF),
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ASK COMMUTERS FOR ROUTE ADVICE',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      Text(
                                        'Verified daily commuters respond in minutes',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Origin & Destination Inputs in 2 columns
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: inputBorder),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.radio_button_checked,
                                              color: Color(0xFF00E5FF),
                                              size: 10,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'FROM: ORIGIN',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextField(
                                          controller: _originController,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryTextColor,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.only(top: 3),
                                            border: InputBorder.none,
                                            hintText: 'e.g. Kalupur Stn',
                                            hintStyle:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              color: secondaryTextColor
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: inputBorder),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Color(0xFFFF5252),
                                              size: 10,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'TO: DESTINATION',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextField(
                                          controller: _destController,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryTextColor,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.only(top: 3),
                                            border: InputBorder.none,
                                            hintText: 'e.g. SG Hwy',
                                            hintStyle:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              color: secondaryTextColor
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Quick Preference Tags
                            Text(
                              'QUICK PREFERENCE TAGS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                _buildTagChip(
                                  tag: 'Fastest Leg',
                                  icon: Icons.bolt_rounded,
                                  color: const Color(0xFF00E5FF),
                                  dark: dark,
                                ),
                                _buildTagChip(
                                  tag: 'AC BRTS',
                                  icon: Icons.ac_unit_rounded,
                                  color: const Color(0xFF38BDF8),
                                  dark: dark,
                                ),
                                _buildTagChip(
                                  tag: 'Late Night',
                                  icon: Icons.nightlight_round,
                                  color: const Color(0xFFA855F7),
                                  dark: dark,
                                ),
                                _buildTagChip(
                                  tag: 'Luggage Friendly',
                                  icon: Icons.luggage_rounded,
                                  color: const Color(0xFF10B981),
                                  dark: dark,
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Question Textarea with Character Counter
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: inputBorder),
                              ),
                              padding: const EdgeInsets.all(9),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _questionController,
                                    maxLines: 3,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: primaryTextColor,
                                      height: 1.35,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText:
                                          'Ask your question (e.g. "What is fastest BRTS/Metro route to GIFT City after 8 PM?")...',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: secondaryTextColor
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Divider(
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _originController.text =
                                                    'Kalupur Stn';
                                              });
                                              _showToast(
                                                  'Pinned Kalupur Station GPS');
                                            },
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00E5FF)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: const Color(0xFF00E5FF)
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.my_location_rounded,
                                                    color: Color(0xFF00E5FF),
                                                    size: 9,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Pin Stop',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          const Color(0xFF00E5FF),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _posterType =
                                                    _posterType == 'Traveler'
                                                        ? 'Student'
                                                        : 'Traveler';
                                              });
                                            },
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2.5),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.shield_outlined,
                                                    color: secondaryTextColor,
                                                    size: 10,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'As $_posterType',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${_questionController.text.length}/220',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Submit Button: "Ask Local Commuters"
                            InkWell(
                              onTap: _submitQuestion,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF0284C7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.send_rounded,
                                      color: Color(0xFF002233),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ASK LOCAL COMMUTERS',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        color: const Color(0xFF002233),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.group_outlined,
                                    color: Color(0xFF00E5FF),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Notifies 140+ active commuters along route',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        color: secondaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 5. COMMUNITY Q&A FEED HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.forum_rounded,
                                color: Color(0xFF00E5FF),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'COMMUNITY Q&A',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live Answers',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 6. QUESTION CARDS LIST
                      ...filteredQuestions.map(
                        (q) => _buildQuestionCard(q, dark),
                      ),
                    ] else ...[
                      // LIVE REPORTS & HAZARDS SECTION
                      _buildLiveReportsSection(
                        dark: dark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        brandPillBg: brandPillBg,
                        brandPillBorder: brandPillBorder,
                        inputBg: inputBg,
                        inputBorder: inputBorder,
                        filteredReports: filteredReports,
                      ),
                    ],
                  ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Toast Notification
          if (_toastMessage != null)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF00E5FF),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _toastMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Ask Gemini AI Button (Cyan-Violet Gradient)
          Positioned(
            bottom: 96,
            right: 18,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openGeminiChatbotModal(dark),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        'Ask AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 7. BOTTOM DOCK (ASK tab active - Index 2)
          StitchBottomDock(
            activeIndex: 2,
            isDarkMode: dark,
            onTabSelected: (index) {
              if (index == 0) {
                widget.onNavigateToHome();
              } else if (index == 1) {
                widget.onNavigateToRouteDetails();
              } else if (index == 3) {
                widget.onNavigateToPasses();
              } else if (index == 4) {
                widget.onNavigateToWallet();
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper: Category Pill
  Widget _buildCategoryPill({
    required String id,
    required String label,
    required String? badgeCount,
    required IconData icon,
    required bool dark,
  }) {
    final isSelected = _selectedCategory == id;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = id),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                  : dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00E5FF)
                    : dark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFCBD5E1),
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: isSelected
                      ? const Color(0xFF00E5FF)
                      : dark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (dark ? Colors.white : const Color(0xFF0369A1))
                        : (dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ),
                if (badgeCount != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Tag Chip
  Widget _buildTagChip({
    required String tag,
    required IconData icon,
    required Color color,
    required bool dark,
  }) {
    final isSelected = _selectedTags.contains(tag);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTags.remove(tag);
          } else {
            _selectedTags.add(tag);
          }
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? color
                : dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFCBD5E1),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isSelected ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 3),
            Text(
              tag,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (dark ? Colors.white : const Color(0xFF0F172A))
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Question Card
  Widget _buildQuestionCard(QuestionItem q, bool dark) {
    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    if (!_replyControllers.containsKey(q.id)) {
      _replyControllers[q.id] = TextEditingController();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StitchGlassCard(
        isDarkMode: dark,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: Author Avatar + Name + Role + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF3B82F6)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          q.author.length >= 2
                              ? q.author.substring(0, 2).toUpperCase()
                              : q.author,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF002233),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    q.author,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '• ${q.role}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              q.timeLocation,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                color: secondaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Category/Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: q.badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: q.badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    q.badgeText,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: q.badgeColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Question Text
            Text(
              q.question,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w400,
                color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 8),

            // Middle Action Row: Upvote Button + Route Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Upvote Button
                InkWell(
                  onTap: () => _toggleUpvote(q),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: q.isUpvoted
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                          : dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: q.isUpvoted
                            ? const Color(0xFF00E5FF)
                            : dark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 12,
                          color: q.isUpvoted
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${q.upvotes} locals helped',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: q.isUpvoted
                                ? const Color(0xFF00E5FF)
                                : primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Route tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        color: Color(0xFF00E5FF),
                        size: 9,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        q.routeTag,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Pinned Verified Guide Banner (if present)
            if (q.pinnedGuide != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF10B981),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  q.pinnedGuide!.author,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  q.pinnedGuide!.roleBadge ?? 'Verified',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          q.pinnedGuide!.time,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.pinnedGuide!.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildReactionButtons(q.pinnedGuide!, dark),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Thread Toggle Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        q.isThreadExpanded = !q.isThreadExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_outlined,
                            color: Color(0xFF00E5FF),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Local Advice (${q.answers.length} answers)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00E5FF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            q.isThreadExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF00E5FF),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  'Verified',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),

            // Expanded Answers Thread
            if (q.isThreadExpanded) ...[
              const SizedBox(height: 6),
              ...q.answers.map(
                (ans) => _buildAnswerBubble(ans, dark),
              ),

              // In-thread reply input
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: _replyControllers[q.id],
                        onSubmitted: (_) => _addReply(q),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write advice or shortcut...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: secondaryTextColor.withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () => _addReply(q),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF00354A),
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper: Individual Answer Bubble
  Widget _buildAnswerBubble(AnswerItem ans, bool dark) {
    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: ans.avatarColor.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: ans.avatarColor.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              ans.avatarLetter,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: ans.avatarColor,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              ans.author,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ans.roleBadge != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                ans.roleBadge!,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      ans.time,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                StitchFormattedText(
                  text: ans.content,
                  baseStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    height: 1.25,
                    color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 5),
                _buildReactionButtons(ans, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Interactive Like and Dislike Buttons
  Widget _buildReactionButtons(AnswerItem ans, bool dark) {
    final isLiked = ans.reaction == UserReaction.liked;
    final isDisliked = ans.reaction == UserReaction.disliked;

    return Row(
      children: [
        // LIKE BUTTON
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleReaction(ans, UserReaction.liked),
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: isLiked
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                    : dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isLiked
                      ? const Color(0xFF00E5FF)
                      : dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFCBD5E1),
                  width: isLiked ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '👍',
                    style: TextStyle(
                      fontSize: 10,
                      color: isLiked ? const Color(0xFF00E5FF) : null,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${ans.likes}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight:
                          isLiked ? FontWeight.w800 : FontWeight.w600,
                      color: isLiked
                          ? const Color(0xFF00E5FF)
                          : (dark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 5),

        // DISLIKE BUTTON
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleReaction(ans, UserReaction.disliked),
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: isDisliked
                    ? const Color(0xFFFF5252).withValues(alpha: 0.22)
                    : dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isDisliked
                      ? const Color(0xFFFF5252)
                      : dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFCBD5E1),
                  width: isDisliked ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '👎',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDisliked ? const Color(0xFFFF5252) : null,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${ans.dislikes}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight:
                          isDisliked ? FontWeight.w800 : FontWeight.w600,
                      color: isDisliked
                          ? const Color(0xFFFF5252)
                          : (dark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper: Segment Switcher Tab Bar
  Widget _buildSegmentSwitcher(bool dark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Tab 0: Community Q&A
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewTab = 0),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeViewTab == 0
                      ? const Color(0xFF00E5FF).withValues(alpha: dark ? 0.22 : 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _activeViewTab == 0
                      ? Border.all(color: const Color(0xFF00E5FF), width: 1.2)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: _activeViewTab == 0
                          ? const Color(0xFF00E5FF)
                          : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Community Q&A',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: _activeViewTab == 0
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _activeViewTab == 0
                              ? (dark ? Colors.white : const Color(0xFF0284C7))
                              : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _activeViewTab == 0
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_questions.length}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: _activeViewTab == 0
                              ? const Color(0xFF00E5FF)
                              : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Tab 1: Live Reports & Hazards
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewTab = 1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeViewTab == 1
                      ? const Color(0xFFFF5252).withValues(alpha: dark ? 0.22 : 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _activeViewTab == 1
                      ? Border.all(color: const Color(0xFFFF5252), width: 1.2)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: _activeViewTab == 1
                          ? const Color(0xFFFF5252)
                          : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Live Reports',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: _activeViewTab == 1
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _activeViewTab == 1
                              ? (dark ? Colors.white : const Color(0xFFDC2626))
                              : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _activeViewTab == 1
                            ? const Color(0xFFFF5252).withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_reports.length}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: _activeViewTab == 1
                              ? const Color(0xFFFF5252)
                              : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Live Reports & Hazards Section
  Widget _buildLiveReportsSection({
    required bool dark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color brandPillBg,
    required Color brandPillBorder,
    required Color inputBg,
    required Color inputBorder,
    required List<TransitReportItem> filteredReports,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Bar: Broadcast Hazard + Ask Gemini AI
        Row(
          children: [
            // Button 1: Broadcast Incident
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openReportIncidentModal(dark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_alert_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '+ Report Incident',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Button 2: Ask Gemini AI
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openGeminiChatbotModal(dark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Ask AI',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Hazard Filter Pills
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildReportFilterPill(
                id: 'all',
                label: 'All Incidents',
                count: '${_reports.length}',
                icon: Icons.grid_view_rounded,
                dark: dark,
              ),
              _buildReportFilterPill(
                id: 'waterlogging',
                label: '🌊 Waterlogging',
                count: null,
                icon: Icons.water_drop_rounded,
                dark: dark,
              ),
              _buildReportFilterPill(
                id: 'metro_delay',
                label: '🚇 Metro Delays',
                count: null,
                icon: Icons.subway_rounded,
                dark: dark,
              ),
              _buildReportFilterPill(
                id: 'breakdown',
                label: '🚌 Breakdowns',
                count: null,
                icon: Icons.build_circle_outlined,
                dark: dark,
              ),
              _buildReportFilterPill(
                id: 'crowding',
                label: '👥 Heavy Crowds',
                count: null,
                icon: Icons.groups_rounded,
                dark: dark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Subheader: Live Feed count + Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Active Transit Hazards (${filteredReports.length})',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_isLoadingReports) ...[
                  const SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  _isLoadingReports ? 'Syncing...' : 'Verified by Commuters',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    color: _isLoadingReports
                        ? const Color(0xFF00E5FF)
                        : secondaryTextColor,
                    fontWeight: _isLoadingReports ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Reports List
        if (filteredReports.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Active Hazards in this Category',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Corridors and metro lines are operating smoothly.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredReports.map((r) => _buildReportCard(r, dark)),
      ],
    );
  }

  // Helper: Report Filter Pill
  Widget _buildReportFilterPill({
    required String id,
    required String label,
    required String? count,
    required IconData icon,
    required bool dark,
  }) {
    final isSelected = _selectedReportFilter == id;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedReportFilter = id),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF5252).withValues(alpha: 0.22)
                  : dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF5252)
                    : dark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFCBD5E1),
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: isSelected
                      ? const Color(0xFFFF5252)
                      : (dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (dark ? Colors.white : const Color(0xFFDC2626))
                        : (dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5252),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Report Card
  Widget _buildReportCard(TransitReportItem r, bool dark) {
    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    if (!_reportCommentControllers.containsKey(r.id)) {
      _reportCommentControllers[r.id] = TextEditingController();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StitchGlassCard(
        isDarkMode: dark,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Reporter Avatar + Name + Severity Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFF59E0B)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        r.reporterName.isNotEmpty
                            ? r.reporterName.substring(0, 1).toUpperCase()
                            : 'C',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.reporterName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          '${r.time} • Live Report',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildSeverityPill(r.severity),
              ],
            ),

            const SizedBox(height: 7),

            // Tag line: Type Badge + Route Tag
            Row(
              children: [
                _buildReportTypeBadge(r.reportType),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    r.routeTag,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // Title
            Text(
              r.title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 4),

            // Description
            Text(
              r.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.35,
                color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),

            const SizedBox(height: 7),

            // Location Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFFF5252),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      r.locationName,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Action Buttons: View on Map + Upvote + Comments Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // DIRECT MAP ROUTING: VIEW ON MAP BUTTON
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onNavigateToRouteWithFocus
                              ?.call(r.locationName, r.title);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00E5FF),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF00E5FF),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View on Map',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? Colors.white : const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // ONE-TAP GEMINI AI INTEL FOR REPORT
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _openGeminiChatbotModal(
                            dark,
                            initialQuery:
                                'Analyze the incident "${r.title}" at ${r.locationName} and recommend the best alternate transit route.',
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF7C3AED),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                'Ask AI',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? Colors.white : const Color(0xFF6D28D9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    // Upvote Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleReportUpvote(r),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: r.isUpvoted
                                ? const Color(0xFFFF5252).withValues(alpha: 0.22)
                                : dark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: r.isUpvoted
                                  ? const Color(0xFFFF5252)
                                  : dark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 12,
                                color: r.isUpvoted
                                    ? const Color(0xFFFF5252)
                                    : secondaryTextColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${r.upvotes}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: r.isUpvoted
                                      ? const Color(0xFFFF5252)
                                      : primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Comments Toggle Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            r.isCommentsExpanded = !r.isCommentsExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: r.isCommentsExpanded
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                : dark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: r.isCommentsExpanded
                                  ? const Color(0xFF00E5FF)
                                  : dark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 12,
                                color: r.isCommentsExpanded
                                    ? const Color(0xFF00E5FF)
                                    : secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${r.comments.length}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: r.isCommentsExpanded
                                      ? const Color(0xFF00E5FF)
                                      : primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Inline Comments Thread
            if (r.isCommentsExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Commuter Updates & Detours (${r.comments.length}):',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (r.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'No updates yet. Be the first to share traffic or detour advice!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: secondaryTextColor,
                          ),
                        ),
                      )
                    else
                      ...r.comments.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.author,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: primaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00E5FF)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              c.userLocality,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 8,
                                                color: const Color(0xFF00E5FF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        c.time,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 8,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  StitchFormattedText(
                                    text: c.comment,
                                    baseStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: dark
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                    const SizedBox(height: 4),

                    // Add comment input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reportCommentControllers[r.id],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: primaryTextColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Share live update or detour...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: secondaryTextColor,
                              ),
                              filled: true,
                              fillColor: dark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submitReportComment(r),
                          ),
                        ),
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: () => _submitReportComment(r),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.send_rounded,
                              color: Color(0xFF00354A),
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper: Severity Pill
  Widget _buildSeverityPill(String severity) {
    Color bg;
    Color border;
    Color textColor;
    String label;

    switch (severity.toLowerCase()) {
      case 'critical':
        bg = const Color(0xFFFF5252).withValues(alpha: 0.18);
        border = const Color(0xFFFF5252);
        textColor = const Color(0xFFFF5252);
        label = 'CRITICAL';
        break;
      case 'high':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        border = const Color(0xFFF59E0B);
        textColor = const Color(0xFFF59E0B);
        label = 'HIGH';
        break;
      case 'medium':
        bg = const Color(0xFFEAB308).withValues(alpha: 0.18);
        border = const Color(0xFFEAB308);
        textColor = const Color(0xFFEAB308);
        label = 'MEDIUM';
        break;
      default:
        bg = const Color(0xFF00E5FF).withValues(alpha: 0.18);
        border = const Color(0xFF00E5FF);
        textColor = const Color(0xFF00E5FF);
        label = 'LOW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Report Type Badge
  Widget _buildReportTypeBadge(String type) {
    String label;
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'waterlogging':
        label = 'Waterlogging';
        icon = Icons.water_drop_rounded;
        color = const Color(0xFF38BDF8);
        break;
      case 'metro_delay':
        label = 'Metro Delay';
        icon = Icons.subway_rounded;
        color = const Color(0xFFA78BFA);
        break;
      case 'breakdown':
        label = 'Breakdown';
        icon = Icons.build_circle_outlined;
        color = const Color(0xFFFB923C);
        break;
      case 'crowding':
        label = 'Heavy Crowd';
        icon = Icons.groups_rounded;
        color = const Color(0xFFF472B6);
        break;
      default:
        label = 'Road Hazard';
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFFBBF24);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Modal: Report Live Incident
  void _openReportIncidentModal(bool dark) {
    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final inputBg =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final inputBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0B132B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: dark ? Colors.white38 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🚨', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Report Live Incident',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor, size: 18),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    Text(
                      'Broadcast live delays, flooding, and detours to fellow commuters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Hazard Type Picker
                    Text(
                      'INCIDENT TYPE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _modalTypeChip('waterlogging', '🌊 Waterlogging', modalSetState, dark),
                        _modalTypeChip('metro_delay', '🚇 Metro Delay', modalSetState, dark),
                        _modalTypeChip('breakdown', '🚌 Breakdown', modalSetState, dark),
                        _modalTypeChip('crowding', '👥 Heavy Crowd', modalSetState, dark),
                        _modalTypeChip('hazard', '⚠️ Road Hazard', modalSetState, dark),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Severity Picker
                    Text(
                      'SEVERITY LEVEL',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _modalSeverityChip('critical', '🔴 Critical', const Color(0xFFFF5252), modalSetState),
                        const SizedBox(width: 6),
                        _modalSeverityChip('high', '🟠 High', const Color(0xFFF59E0B), modalSetState),
                        const SizedBox(width: 6),
                        _modalSeverityChip('medium', '🟡 Medium', const Color(0xFFEAB308), modalSetState),
                        const SizedBox(width: 6),
                        _modalSeverityChip('low', '🔵 Low', const Color(0xFF00E5FF), modalSetState),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title input
                    Text(
                      'INCIDENT HEADLINE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _reportTitleController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 2.5ft Waterlogging Under Akhbarnagar Underpass',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: inputBg,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Location & Route
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION NAME',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _reportLocationController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: primaryTextColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Akhbarnagar Underpass',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: secondaryTextColor,
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: inputBorder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ROUTE / CORRIDOR',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _reportRouteController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: primaryTextColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Corridor #9 BRTS',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: secondaryTextColor,
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: inputBorder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description & Detour details
                    Text(
                      'DETAILS & DETOUR ADVICE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _reportDescController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe conditions, alternate roads, or expected clearing times...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Broadcast button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitNewReport,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5252), Color(0xFFEA580C)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Broadcast Hazard to Commuters 🚨',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalTypeChip(String type, String label, StateSetter modalSetState, bool dark) {
    final isSelected = _selectedReportType == type;
    return InkWell(
      onTap: () {
        modalSetState(() => _selectedReportType = type);
        setState(() => _selectedReportType = type);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
              : dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF00E5FF) : (dark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _modalSeverityChip(String sev, String label, Color col, StateSetter modalSetState) {
    final isSelected = _selectedReportSeverity == sev;
    return Expanded(
      child: InkWell(
        onTap: () {
          modalSetState(() => _selectedReportSeverity = sev);
          setState(() => _selectedReportSeverity = sev);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? col.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? col : Colors.white24,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isSelected ? col : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // Modal: Gemini AI Transit Assistant Chatbot
  void _openGeminiChatbotModal(bool dark, {String? initialQuery}) {
    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final inputBg =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final inputBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0xFFCBD5E1);

    final ScrollController chatScrollController = ScrollController();
    bool hasTriggeredInitial = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, modalSetState) {
            if (initialQuery != null &&
                initialQuery.isNotEmpty &&
                !hasTriggeredInitial) {
              hasTriggeredInitial = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _sendQuickPrompt(
                    initialQuery, modalSetState, chatScrollController);
              });
            }

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.82,
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF090E1A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white38 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('✨', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Transit AI Assistant',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      '⚡ ACTIVE AI • ONLINE',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Real-time answers for Ahmedabad hazards & routes',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: secondaryTextColor, size: 18),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Quick prompt suggestion chips
                  SizedBox(
                    height: 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _chatPromptChip(
                          '🌊 Waterlogging reports?',
                          () => _sendQuickPrompt(
                              'Are there any waterlogging or flooding reports right now?',
                              modalSetState,
                              chatScrollController),
                          dark,
                        ),
                        _chatPromptChip(
                          '🚇 Metro Line 1 delay?',
                          () => _sendQuickPrompt(
                              'Is Metro Line 1 delayed today?',
                              modalSetState,
                              chatScrollController),
                          dark,
                        ),
                        _chatPromptChip(
                          '🚌 Nehru Bridge breakdown?',
                          () => _sendQuickPrompt(
                              'What is happening on Nehru Bridge and what detour should I take?',
                              modalSetState,
                              chatScrollController),
                          dark,
                        ),
                        _chatPromptChip(
                          '👥 Kalupur crowd?',
                          () => _sendQuickPrompt(
                              'Is Kalupur Metro Hub crowded right now?',
                              modalSetState,
                              chatScrollController),
                          dark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Message bubbles list
                  Expanded(
                    child: ListView.builder(
                      controller: chatScrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _geminiChatMessages.length,
                      itemBuilder: (c, idx) {
                        final msg = _geminiChatMessages[idx];
                        final isUser = msg['role'] == 'user';
                        final text = msg['text'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFF00E5FF)
                                    : dark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: isUser
                                      ? const Radius.circular(14)
                                      : const Radius.circular(2),
                                  bottomRight: isUser
                                      ? const Radius.circular(2)
                                      : const Radius.circular(14),
                                ),
                                border: isUser
                                    ? null
                                    : Border.all(
                                        color: dark
                                            ? Colors.white12
                                            : const Color(0xFFCBD5E1),
                                      ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isUser ? '👤 You' : '✨ AI Assistant',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isUser
                                              ? const Color(0xFF00354A)
                                              : const Color(0xFF00E5FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  StitchFormattedText(
                                    text: text,
                                    baseStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: isUser
                                          ? const Color(0xFF002233)
                                          : primaryTextColor,
                                    ),
                                    isUser: isUser,
                                  ),

                                  // If assistant message mentions a matching incident, provide interactive "View on Map" chip
                                  if (!isUser) ...[
                                    _buildIncidentMapChipInChat(
                                        text, sheetContext),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Typing indicator
                  if (_isGeminiThinking)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI is analyzing live reports & routes...',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Chat Input Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _geminiInputController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask about hazards, delays, detours...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                          ),
                          onSubmitted: (val) => _sendQuickPrompt(
                              val, modalSetState, chatScrollController),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendQuickPrompt(
                              _geminiInputController.text,
                              modalSetState,
                              chatScrollController),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chatPromptChip(String label, VoidCallback onTap, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white70 : const Color(0xFF0369A1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentMapChipInChat(String text, BuildContext modalContext) {
    // Check if text mentions any known report location
    TransitReportItem? matched;
    for (final r in _reports) {
      if (text.toLowerCase().contains(r.locationName.toLowerCase()) ||
          text.toLowerCase().contains(r.title.toLowerCase().split(' ').first)) {
        matched = r;
        break;
      }
    }

    if (matched == null) return const SizedBox.shrink();

    final item = matched;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(modalContext).pop(); // Close chat modal
          widget.onNavigateToRouteWithFocus
              ?.call(item.locationName, item.title);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_rounded, color: Color(0xFF00E5FF), size: 12),
              const SizedBox(width: 4),
              Text(
                'View ${item.locationName} on Map 🗺️',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00E5FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendQuickPrompt(
    String prompt,
    StateSetter modalSetState,
    ScrollController scrollCtrl,
  ) async {
    final query = prompt.trim();
    if (query.isEmpty) return;

    _geminiInputController.clear();
    modalSetState(() {
      _geminiChatMessages.add({'role': 'user', 'text': query});
      _isGeminiThinking = true;
    });

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    final activeReportsData = _reports
        .map((r) => {
              'id': r.id,
              'title': r.title,
              'report_type': r.reportType,
              'type': r.reportType,
              'severity': r.severity,
              'location_name': r.locationName,
              'location': r.locationName,
              'route_tag': r.routeTag,
              'route': r.routeTag,
              'description': r.description,
              'status': r.status,
              'time': r.time,
              'comments':
                  r.comments.map((c) => '${c.author}: ${c.comment}').toList(),
            })
        .toList();

    final aiReply = await GeminiService.askGeminiAboutReports(
      userQuery: query,
      activeReports: activeReportsData,
    );

    if (mounted) {
      modalSetState(() {
        _isGeminiThinking = false;
        _geminiChatMessages.add({'role': 'assistant', 'text': aiReply});
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Trigger Gemini AI answer when a commuter submits a question
  void _triggerGeminiAnswerForQuestion(
    QuestionItem item,
    String origin,
    String destination,
    String questionText,
  ) async {
    try {
      final activeReportsList = _reports
          .map((r) => {
                'title': r.title,
                'location_name': r.locationName,
                'description': r.description,
                'severity': r.severity,
                'report_type': r.reportType,
              })
          .toList();

      final aiReply =
          await GeminiService.instance.generateTransitAnswerForQuestion(
        question: questionText,
        origin: origin,
        destination: destination,
        activeReports: activeReportsList,
      );

      if (aiReply != null && aiReply.trim().isNotEmpty && mounted) {
        final aiAnswer = AnswerItem(
          id: 'ans_gemini_${DateTime.now().millisecondsSinceEpoch}',
          author: '✨ Gemini Transit AI',
          roleBadge: 'Verified AI Advice',
          time: 'Just now',
          content: aiReply.trim(),
          avatarLetter: '✦',
          avatarColor: const Color(0xFF00E5FF),
          likes: 5,
          dislikes: 0,
          reaction: UserReaction.none,
        );

        setState(() {
          item.answers.insert(0, aiAnswer);
          item.isThreadExpanded = true;
        });

        // Sync AI answer to Supabase backend
        SupabaseService.instance.postAnswer(
          questionId: item.id,
          author: '✨ Gemini Transit AI',
          roleBadge: 'Verified AI Advice',
          content: aiReply.trim(),
          avatarLetter: '✦',
        );
      }
    } catch (e) {
      debugPrint('[GeminiTrigger] Question answer error: $e');
    }
  }

  // Trigger Gemini AI guidance when someone comments on an incident report
  void _triggerGeminiReportInsight(
    TransitReportItem report,
    String userComment,
  ) async {
    try {
      final isQuery = userComment.contains('?') ||
          userComment.toLowerCase().contains('how') ||
          userComment.toLowerCase().contains('alternate') ||
          userComment.toLowerCase().contains('detour') ||
          userComment.toLowerCase().contains('metro') ||
          userComment.toLowerCase().contains('bus') ||
          userComment.toLowerCase().contains('route') ||
          userComment.toLowerCase().contains('safe') ||
          userComment.toLowerCase().contains('status') ||
          userComment.toLowerCase().contains('update');

      if (!isQuery) return;

      final activeReportsList = [
        {
          'title': report.title,
          'location_name': report.locationName,
          'description': report.description,
          'severity': report.severity,
          'report_type': report.reportType,
        }
      ];

      final aiReply = await GeminiService.instance.askTransitAssistant(
        userQuery:
            'A commuter commented on incident "${report.title}" at "${report.locationName}": "$userComment". Give a concise 1-2 sentence real-time transit guidance or alternate route.',
        activeReports: activeReportsList,
      );

      if (aiReply.isNotEmpty && mounted) {
        final aiComment = ReportCommentItem(
          id: 'rc_gemini_${DateTime.now().millisecondsSinceEpoch}',
          author: '✨ Gemini Transit AI',
          comment: aiReply.replaceAll('**', '').trim(),
          userLocality: 'AI Transit Dispatch',
          time: 'Just now',
        );

        setState(() {
          report.comments.add(aiComment);
        });

        SupabaseService.instance.submitReportComment(
          reportId: report.id,
          author: '✨ Gemini Transit AI',
          comment: aiReply.replaceAll('**', '').trim(),
          userLocality: 'AI Transit Dispatch',
        );
      }
    } catch (e) {
      debugPrint('[GeminiTrigger] Report comment insight error: $e');
    }
  }
}
