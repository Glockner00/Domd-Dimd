// main.dart
import 'package:flutter/material.dart';
import 'challonge_service.dart';

const tournamentID = 'api_test1337';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Challonge brackets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Challonge Brackets Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FinalStage()),
                );
              },
              child: const Text('Final Stage'),
            ),
          ],
        ),
      ),
    );
  }
}

class FinalStage extends StatefulWidget {
  const FinalStage({super.key});

  @override
  State<FinalStage> createState() => _FinalStageState();
}

class _FinalStageState extends State<FinalStage> {
  final ChallongeService _challongeService = ChallongeService();
  Map<int, List<dynamic>> _rounds = {};
  Map<int, String> _participantNames = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    try {
      // Fetch participant names
      final participantNames =
          await _challongeService.fetchParticipantNames("$tournamentID");

      // Fetch matches grouped by rounds
      final rounds =
          await _challongeService.fetchMatchesGroupedByRounds("$tournamentID");

      setState(() {
        _participantNames = participantNames;
        _rounds = rounds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
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
              : _buildBracket(),
    );
  }

  Widget _buildBracket() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _rounds.entries.map((entry) {
          int roundNumber = entry.key;
          List<dynamic> matches = entry.value;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Round $roundNumber',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...matches.map((match) => _buildMatchWidget(match)).toList(),
            ],
          );
        }).toList(),
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
    String winner = match['match']['winner_id'] != null &&
            _participantNames.containsKey(match['match']['winner_id'])
        ? 'Winner: ${_participantNames[match['match']['winner_id']]}'
        : 'Winner TBD';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('$team1 vs $team2', style: const TextStyle(fontSize: 16)),
            Text(winner,
                style: const TextStyle(fontSize: 14, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}