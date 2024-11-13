// main.dart
import 'package:flutter/material.dart';
import 'challonge_service.dart';
import 'package:intl/intl.dart';

const tournamentID = 'testDomd';

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
  Map<int, String> _roundTimes = {};
  bool _isLoading = true;
  String _errorMessage = '';
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
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
      // Ensure page position is maintained after loading
      setState(() {
        _isLoading = false;
      });
      _pageController = PageController(initialPage: _currentPage);
    }
  }

  void _refreshBracket() async {
    await _loadBracket();
    // After loading, set the PageController to the current page
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
                child: ListView(
                  children:
                      matches.map((match) => _buildMatchWidget(match)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchWidget(dynamic match) {
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

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Card(
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
