import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReVotePage extends StatefulWidget {
  final String title;
  final String solution;
  final String impact;
  final String username;
  final String file;

  const ReVotePage({
    super.key,
    required this.title,
    required this.solution,
    required this.impact,
    required this.username,
    required this.file,
  });

  @override
  State<ReVotePage> createState() => _ReVotePageState();
}

class _ReVotePageState extends State<ReVotePage> {
  static const primaryColor = Color(0xFF004667);

  final List<String> categories = [
    "Strategic & Business Impact",
    "Feasibility & Practicality",
    "Innovation & Originality",
    "Financial & Value",
    "Proof of Concept Readiness",
  ];

  final List<int> weights = [25, 20, 15, 20, 20];

  final List<int> ratings = [0, 0, 0, 0, 0];
  late final List<TextEditingController> commentControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  bool isLoadingVotes = true;
  bool isSubmitting = false;

  bool get isComplete => ratings.every((rating) => rating > 0);

  double calculatePercentage(int stars, int weight) {
    return (stars / 5) * weight;
  }

  double get totalPercentage {
    double total = 0;
    for (int index = 0; index < ratings.length; index++) {
      total += calculatePercentage(ratings[index], weights[index]);
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    loadExistingEvaluation();
  }

  @override
  void dispose() {
    for (final controller in commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadExistingEvaluation() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/get_user_vote/${widget.username}/${widget.title}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List votes = data["votes"] ?? [];
        final Map<String, dynamic> votesByCategory = {};

        for (final vote in votes) {
          final category = vote["category"]?.toString() ?? "";
          if (category.isNotEmpty) {
            votesByCategory[category] = vote;
          }
        }

        for (int index = 0; index < categories.length; index++) {
          final existingVote = votesByCategory[categories[index]];
          if (existingVote != null) {
            ratings[index] = existingVote["score"] as int? ?? 0;
            commentControllers[index].text =
                existingVote["comment"]?.toString() ?? "";
          }
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load existing vote")),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingVotes = false;
    });
  }

  Future<void> updateEvaluation() async {
    setState(() => isSubmitting = true);

    try {
      for (int index = 0; index < categories.length; index++) {
        final response = await http.post(
          Uri.parse(
            "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/submit_vote",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "idea_title": widget.title,
            "username": widget.username,
            "category": categories[index],
            "score": ratings[index],
            "comment": commentControllers[index].text.trim(),
          }),
        );

        if (response.statusCode != 200) {
          throw Exception("Failed to update vote");
        }
      }

      final response = await http.post(
        Uri.parse(
          "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/submit_final_vote",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "idea_title": widget.title,
          "percentage": totalPercentage,
          "submit": true,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update final vote");
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update evaluation")),
      );
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingVotes) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Initiative Evaluation",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: "AI Initiative Title: ",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: widget.title),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: "Summary of AI Solution:\n",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: widget.solution),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: "Business Impact Explanation:\n",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: widget.impact),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: "File: ",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            widget.file.isEmpty
                                ? const TextSpan(text: "-")
                                : TextSpan(
                                    text: "Open File",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        html.window.open(widget.file, "_blank");
                                      },
                                  ),
                          ],
                        ),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Evaluation Criteria",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ...List.generate(
                        categories.length,
                        (index) => _buildStarRow(categories[index], index),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          onPressed: isComplete && !isSubmitting
                              ? updateEvaluation
                              : null,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Update Evaluation"),
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
  }

  Widget _buildStarRow(String title, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: List.generate(5, (starIndex) {
                    return IconButton(
                      icon: Icon(
                        starIndex < ratings[index]
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          ratings[index] = starIndex + 1;
                        });
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: commentControllers[index],
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: "Add comment...",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
