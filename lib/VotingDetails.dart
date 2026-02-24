import 'package:flutter/material.dart';
import 'package:voting/AdminPage.dart';
import 'package:voting/main.dart';
import 'dart:html' as html;

class VotingDetailsPage extends StatelessWidget {
  final dynamic project;
  final Map<String, dynamic> fullReport;

  const VotingDetailsPage({
    super.key,
    required this.project,
    required this.fullReport,
  });

  static const primaryColor = Color(0xFF004667);

  @override
  Widget build(BuildContext context) {
    final List users = fullReport["users_summary"] ?? [];
    final List votedUsers = project["voted_users"] ?? [];

    final String title = project["project"] ?? "";
    final String solution = project["solution"] ?? "";
    final String impact = project["impact"] ?? "";
    final String filePath = project["file"] ?? "";

    bool allVoted = users.isNotEmpty && votedUsers.length == users.length;

    double average = 0;
    if (allVoted && project["average_percentage"] != null) {
      average = (project["average_percentage"] as num).toDouble();
    }

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
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPage(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "💻 Admin",
                style: TextStyle(color: Colors.white),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginIntroPage(),
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
        padding: const EdgeInsets.all(40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Initiative Details",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text("Title: $title",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      Text("Solution:\n$solution",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      Text("Impact:\n$impact",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            "File: ",
                            style: TextStyle(fontSize: 18),
                          ),
                          filePath.isEmpty
                              ? const Text("-",
                                  style: TextStyle(fontSize: 18))
                              : InkWell(
                                  onTap: () {
                                    html.window.open(filePath, "_blank");
                                  },
                                  child: const Text(
                                    "Open File",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allVoted
                          ? "Average: ${average.toStringAsFixed(1)}%"
                          : "Waiting for all votes",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          var userItem = users[index];
                          String userKey = userItem["username"] ?? "";
                          String displayName = userItem["name"] ?? "";

                          final Map percentages =
                              project["user_percentages"] ?? {};

                          double value =
                              (percentages[userKey] as num?)?.toDouble() ?? 0;

                          bool voted = value > 0;

                          return ListTile(
                            leading: Icon(
                              voted
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: voted
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(displayName),
                            trailing: Text(
                                "${value.toStringAsFixed(0)}%"),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

