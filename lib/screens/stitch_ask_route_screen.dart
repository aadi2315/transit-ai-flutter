import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';

enum UserReaction { none, liked, disliked }

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

  const StitchAskRouteScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToPasses,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<StitchAskRouteScreen> createState() => _StitchAskRouteScreenState();
}

class _StitchAskRouteScreenState extends State<StitchAskRouteScreen> {
  String _selectedCategory = 'all';

  // Input Controllers for "Ask Commuters" Card
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  // Reply Controllers per card
  final Map<String, TextEditingController> _replyControllers = {};

  final Set<String> _selectedTags = {'Fastest Leg'};
  String _posterType = 'Traveler';
  String? _toastMessage;
  Timer? _toastTimer;

  late List<QuestionItem> _questions;

  @override
  void initState() {
    super.initState();
    _initDefaultQuestions();
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
  }

  void _toggleUpvote(QuestionItem item) {
    setState(() {
      item.isUpvoted = !item.isUpvoted;
      item.upvotes += item.isUpvoted ? 1 : -1;
    });
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

    _showToast('Broadcasting question to 140+ active commuters!');
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

    _showToast('Your advice was shared with the commuter thread!');
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _questionController.dispose();
    for (final c in _replyControllers.values) {
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
                Text(
                  ans.content,
                  style: GoogleFonts.plusJakartaSans(
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
}
