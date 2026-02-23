import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'VotingDetails.dart';
import 'main.dart';
import 'DataPage.dart';
import 'dart:async';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Map<String, dynamic> fullReport = {};
  bool isLoading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    loadData();

    refreshTimer = Timer.periodic(
    const Duration(seconds: 10),
    (_) => loadData(),
  );
  }
  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
  Future<void> loadData() async {
    final response = await http.get(
      Uri.parse(
          "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/admin/full_report"),
    );

    if (response.statusCode == 200) {
      setState(() {
        fullReport = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF004667);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int totalProjects = fullReport["total_projects"] ?? 0;
    int totalTeams = fullReport["total_teams"] ?? 0;
    int individualIdeas = fullReport["individual_ideas"] ?? 0;

    List projects = fullReport["projects"] ?? [];
    List users = fullReport["users_summary"] ?? [];
    List countryData = fullReport["country_distribution"] ?? [];

    return Scaffold(
      
            appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
     
            Image.asset("assets/JulpharAI_Logo_white.png", height: 40),
            const SizedBox(width: 15),
            const Text(
              "Voting Portal",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
       actions: [
        TextButton(
  onPressed: _exportToExcel,
  child: const Text(
    "📊 Export",
    style: TextStyle(color: Colors.white),
  ),
),
  TextButton(
    onPressed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DataPage(username: "Admin"),
        ),
        (route) => false,
      );
    },
    child: const Text(
      "📋 Data Page",
      style: TextStyle(color: Colors.white),
    ),
  ),
  TextButton(
    onPressed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginIntroPage(),
        ),
        (route) => false,
      );
    },
    child: const Text(
      "➜] Logout",
      style: TextStyle(color: Colors.white),
    ),
  ),
  const SizedBox(width: 15),
],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [

            /// ===== SUMMARY CARDS =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryCard("Total Projects",
                      totalProjects.toString(),
                      Icons.folder,
                      Colors.blue),

                  _summaryCard("Total Teams",
                      totalTeams.toString(),
                      Icons.groups,
                      Colors.deepPurple),

                  _summaryCard("Individual Ideas",
                      individualIdeas.toString(),
                      Icons.person_outline,
                      Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// ===== TWO SECTION LAYOUT =====
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// LEFT SIDE → PROJECT STATUS
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _projectSection(projects, users),
                    ),
                  ),

                  const SizedBox(width: 20),

                  /// RIGHT SIDE → PIE + USERS
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [

                        /// PIE CHART
                        Container(
                          height: 300,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _pieChart(countryData),
                        ),

                        const SizedBox(height: 20),

                        /// USERS ACTIVITY
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                _usersSection(users, totalProjects),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectSection(List projects, List users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Projects Status",
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Expanded(
          child: projects.isEmpty
              ? const Center(child: Text("No Data"))
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    var project = projects[index];
                   return Card(
  color: project["total_voters"] == users.length
      ? Colors.green.shade100
      : Colors.white,
  child: ListTile(
    title: Text("${project["rank"]} - ${project["project"]}"),
    subtitle: Text(
      "Votes: ${project["total_voters"]} / ${users.length}   |   Avg: ${project["average_percentage"]}%",
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VotingDetailsPage(
            project: project,
            fullReport: fullReport,
            //username: username, // ✅ ADD THIS
          ),
        ),
      );
    },
  ),
);
                  },
                ),
        )
      ],
    );
  }


  Widget _pieChart(List countryData) {
  final customColors = [
    const Color(0xFF6A1B9A),
    const Color(0xFFD32F2F),
    const Color(0xFF004667),
    const Color(0xFF2E7D32),
    const Color(0xFFFF8F00),
    const Color(0xFF00838F),
  ];

  // DO NOT modify original list directly
  List sortedData = List.from(countryData);

  sortedData.sort((a, b) =>
      (b["count"] as int).compareTo(a["count"] as int));

  double total = sortedData.fold(
      0, (sum, item) => sum + (item["count"] as int));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Ideas by Country",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 15),
      Expanded(
        child: Row(
          children: [

            /// PIE
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  sections:
                      sortedData.asMap().entries.map((entry) {
                    int index = entry.key;
                    var data = entry.value;

                    double percentage =
                        (data["count"] / total) * 100;

                    return PieChartSectionData(
                      color: customColors[
                          index % customColors.length],
                      value:
                          (data["count"] as int).toDouble(),
                      title:
                          "${percentage.toStringAsFixed(1)}%",
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(width: 15),

            /// LEGEND
            Expanded(
              flex: 2,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedData.length,
                itemBuilder: (context, index) {
                  var data = sortedData[index];

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: customColors[
                                index %
                                    customColors.length],
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${data["country"]} (${data["count"]})",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}



  Widget _usersSection(List users, int totalProjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Users Activity",
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text("No Data"))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    // 1) Replace your user Card in _usersSection with this:
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user["name"]),
                        subtitle: Text("Remaining: ${user["remaining"]}"),
                        trailing: Text(
                          "${user["finished"]} / $totalProjects",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _showUserVotes(
  context,
  user["username"],   // pass username NOT name
),
                      ),
                    );

// 2) Add this method inside _AdminPageState:


                  },
                ),
        )
      ],
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title),
      ],
    );
  }

  void _showUserVotes(BuildContext context, String username) {
    final List projects = List.from(fullReport["projects"] ?? []);
    final List users = fullReport["users_summary"] ?? [];

  final userObj = users.firstWhere(
    (u) => u["username"] == username,
    orElse: () => {"name": username},
  );
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text("Votes: ${userObj["name"]}"),
        content: SizedBox(
          width: 450,
          child: projects.isEmpty
              ? const Text("No projects")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final p = projects[index];
                    final String title = (p["project"] ?? "").toString();

                    final Map percentages = (p["user_percentages"] ?? {}) as Map;
                    final double value = (percentages[username] ?? 0).toDouble();
                    final bool didVote = value > 0;

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        didVote ? Icons.check_circle : Icons.cancel,
                        color: didVote ? Colors.green : Colors.red,
                      ),
                      title: Text(title),
                       trailing: Text("${value.toStringAsFixed(0)}%"),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

void _exportToExcel() {
  final excel = Excel.createExcel();

  excel.delete('Sheet1');
  excel.delete('FlutterExcel');

  List projects = fullReport["projects"] ?? [];
  List users = fullReport["users_summary"] ?? [];

  /// ===============================
  /// SHEET 1 → PROJECT SUMMARY
  /// ===============================
  final Sheet summarySheet = excel['Projects Summary'];

  List summaryHeader = ["Project", "Rank", "Total Voters", "Average %"];
  summarySheet.appendRow(summaryHeader);

  // Bold header
  for (int i = 0; i < summaryHeader.length; i++) {
    final cell = summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.cellStyle = CellStyle(bold: true);
  }

  for (int r = 0; r < projects.length; r++) {
    var p = projects[r];
    summarySheet.appendRow([
      p["project"],
      p["rank"],
      p["total_voters"],
      p["average_percentage"],
    ]);
  }

  /// ===============================
  /// SHEET 2 → USERS VOTES
  /// ===============================
  final Sheet usersSheet = excel['Users Votes'];

  List header = ["Project / Usernames"];
  for (var user in users) {
    header.add(user["name"]);
  }

  usersSheet.appendRow(header);

  // Bold header
  for (int i = 0; i < header.length; i++) {
    final cell = usersSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.cellStyle = CellStyle(bold: true);
  }

  for (int r = 0; r < projects.length; r++) {
    var p = projects[r];
    Map percentages = (p["user_percentages"] ?? {}) as Map;

    List row = [p["project"]];
    usersSheet.appendRow(row);

    int currentRow = r + 1;

    for (int c = 0; c < users.length; c++) {
      String username = users[c]["username"];
      double value = (percentages[username] ?? 0).toDouble();

      final cell = usersSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: currentRow));

      if (value > 0) {
        cell.value = "Voted (${value.toStringAsFixed(0)}%)";
        cell.cellStyle = CellStyle(
          backgroundColorHex: "#C6EFCE",
        );
      } else {
        cell.value = "Not Voted";
        cell.cellStyle = CellStyle(
          backgroundColorHex: "#FFC7CE",
        );
      }
    }
  }

  final bytes = excel.encode();
  if (bytes == null) return;

  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = "Voting_Report.xlsx"
    ..click();

  html.Url.revokeObjectUrl(url);
}


}
