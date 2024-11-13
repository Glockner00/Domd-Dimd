// final_stage.dart
import 'package:challonge_basic/search_matches.dart';
import 'package:flutter/material.dart';
import 'challonge_service.dart';
import 'package:intl/intl.dart';
import 'package:challonge_basic/config.dart';

class FinalStage extends StatefulWidget {
  final int initialRound;
  final int highlightMatchId;

  const FinalStage({
    super.key,
    this.initialRound = 0,
    this.highlightMatchId = -1,
  });

  @override
  State<FinalStage> createState() => _FinalStageState();
}

class _FinalStageState extends State<FinalStage> {
  final ChallongeService _challongeService = ChallongeService();
  Map<int, List<dynamic>> _rounds = {};
  Map<int, String> _participantNames = {};
  Map<int, String> _roundTimes = {};
  bool _isLoading = true;
  String _errorMessage = '';
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialRound - 1; // Adjust for zero-based index
    _pageController = PageController(initialPage: _currentPage);
    _scrollController = ScrollController();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final participantNames =
          await _challongeService.fetchParticipantNames("$tournamentID");
      final rounds =
          await _challongeService.fetchMatchesGroupedByRounds("$tournamentID");

      Map<int, String> roundTimes = {};
      rounds.forEach((roundNumber, matches) {
        if (matches.isNotEmpty) {
          String? scheduledTime = matches[0]['match']['scheduled_time'];
          if (scheduledTime != null) {
            DateTime utcTime = DateTime.parse(scheduledTime);
            DateTime localTime = utcTime.toLocal();
            roundTimes[roundNumber] =
                DateFormat('EEE, MMM d – h:mm a').format(localTime);
          }
        }
      });

      setState(() {
        _participantNames = participantNames;
        _rounds = rounds;
        _roundTimes = roundTimes;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToHighlightedMatch());
    }
  }

  void _scrollToHighlightedMatch() {
    if (_currentPage == widget.initialRound - 1 &&
        widget.highlightMatchId != -1) {
      // Find the index of the highlighted match
      int? matchIndex = _rounds[_currentPage + 1]?.indexWhere(
          (match) => match['match']['id'] == widget.highlightMatchId);
      if (matchIndex != null && matchIndex >= 0) {
        // Scroll to the highlighted match with a small offset
        _scrollController.animateTo(
          matchIndex *
              100.0, // Assuming each match item height is approximately 100. Adjust if needed
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _refreshBracket() async {
    await _loadBracket();
    setState(() {
      _pageController = PageController(initialPage: _currentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Bracket'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildSwipeableRounds(),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshBracket,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSwipeableRounds() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index; // Track the current page
        });
        _scrollToHighlightedMatch(); // Trigger scroll to highlighted match on page change
      },
      itemCount: _rounds.keys.length,
      itemBuilder: (context, index) {
        int roundNumber = _rounds.keys.elementAt(index);
        List<dynamic> matches = _rounds[roundNumber]!;
        String roundTime = _roundTimes[roundNumber] ?? 'Time TBD';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Round $roundNumber - $roundTime',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: matches.length,
                  itemBuilder: (context, matchIndex) {
                    return _buildMatchWidget(matches[matchIndex], roundNumber);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchWidget(dynamic match, int roundNumber) {
    const boxWidth = 150.0;
    const boxHeight = 80.0;

    int? player1Id = match['match']['player1_id'];
    int? player2Id = match['match']['player2_id'];
    int? winnerId = match['match']['winner_id'];

    String team1 = player1Id != null && _participantNames.containsKey(player1Id)
        ? _participantNames[player1Id]!
        : 'TBD';
    String team2 = player2Id != null && _participantNames.containsKey(player2Id)
        ? _participantNames[player2Id]!
        : 'TBD';

    bool isTeam1Winner = player1Id == winnerId;
    bool isTeam2Winner = player2Id == winnerId;

    String? scores = match['match']['scores_csv'];
    String displayScore =
        scores != null && scores.isNotEmpty ? scores : 'Score TBD';

    // Highlight the selected match if its ID matches highlightMatchId
    bool isHighlighted = match['match']['id'] == widget.highlightMatchId;

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Card(
        color: isHighlighted ? Colors.grey[300] : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                team1,
                style: TextStyle(
                  fontSize: 16,
                  color: isTeam1Winner ? Colors.green : Colors.black,
                  fontWeight:
                      isTeam1Winner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                displayScore,
                style: const TextStyle(fontSize: 14, color: Colors.orange),
              ),
              Text(
                team2,
                style: TextStyle(
                  fontSize: 16,
                  color: isTeam2Winner ? Colors.green : Colors.black,
                  fontWeight:
                      isTeam2Winner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
