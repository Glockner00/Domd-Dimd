// search_matches.dart
import 'package:flutter/material.dart';
import 'challonge_service.dart';
import 'package:intl/intl.dart';

const String tournamentID = "testDomd";

class SearchMatchesPage extends StatefulWidget {
  const SearchMatchesPage({super.key});

  @override
  _SearchMatchesPageState createState() => _SearchMatchesPageState();
}

class _SearchMatchesPageState extends State<SearchMatchesPage> {
  final ChallongeService _challongeService = ChallongeService();
  List<String> _playerNames = [];
  String _selectedPlayer = '';
  List<dynamic> _matchesForPlayer = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Map<int, String> _participantNames = {};

  @override
  void initState() {
    super.initState();
    _loadPlayerNames();
  }

  Future<void> _loadPlayerNames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _participantNames =
          await _challongeService.fetchParticipantNames("$tournamentID");
      setState(() {
        _playerNames = _participantNames.values.toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchMatches(String playerName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _matchesForPlayer = [];
    });
    try {
      final matches =
          await _challongeService.fetchMatchesGroupedByRounds("$tournamentID");
      final playerId = _participantNames.entries
          .firstWhere((entry) => entry.value == playerName)
          .key;

      List<dynamic> matchesForPlayer = [];
      matches.forEach((_, roundMatches) {
        matchesForPlayer.addAll(roundMatches.where((match) =>
            match['match']['player1_id'] == playerId ||
            match['match']['player2_id'] == playerId));
      });

      setState(() {
        _matchesForPlayer = matchesForPlayer;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Matches'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _playerNames.where((name) => name
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _selectedPlayer = selection;
                      });
                      _searchMatches(selection);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search for a player',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _matchesForPlayer.length,
                    itemBuilder: (context, index) {
                      final match = _matchesForPlayer[index];
                      return _buildMatchWidget(match);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMatchWidget(dynamic match) {
    int? player1Id = match['match']['player1_id'];
    int? player2Id = match['match']['player2_id'];

    String team1 = player1Id != null && _participantNames.containsKey(player1Id)
        ? _participantNames[player1Id]!
        : 'TBD';
    String team2 = player2Id != null && _participantNames.containsKey(player2Id)
        ? _participantNames[player2Id]!
        : 'TBD';

    DateTime? scheduledTime = match['match']['scheduled_time'] != null
        ? DateTime.parse(match['match']['scheduled_time']).toLocal()
        : null;
    String displayTime = scheduledTime != null
        ? DateFormat('EEE, MMM d – h:mm a').format(scheduledTime)
        : 'Time TBD';

    String? scores = match['match']['scores_csv'];
    String displayScore = scores != null && scores.isNotEmpty ? scores : 'TBD';

    return ListTile(
      title: Text('$team1 vs $team2'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time: $displayTime'),
          Text('Score: $displayScore'),
        ],
      ),
    );
  }
}
