import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/gestures.dart';

class PillarVotingPage extends StatefulWidget {
  final String title;
  final String solution;
  final String impact;
  final String username;
  final String file;

  const PillarVotingPage({
    super.key,
    required this.title,
    required this.solution,
    required this.impact,
    required this.username,
    required this.file,
  });

  @override
  State<PillarVotingPage> createState() => _PillarVotingPageState();
}

class _PillarVotingPageState extends State<PillarVotingPage> {
  static const primaryColor = Color(0xFF004667);

  final List<String> categories = [
    "Strategic & Business Impact",
    "Feasibility & Practicality",
    "Innovation & Originality",
    "Financial & Value",
    "Proof of Concept Readiness",
  ];

  final List<int> weights = [25, 20, 15, 20, 20];

  List<int> ratings = [0, 0, 0, 0, 0];
  List<TextEditingController> commentControllers =
    List.generate(5, (_) => TextEditingController());
  bool isSubmitting = false;
  bool alreadySubmitted = false;

  bool get isComplete => ratings.every((r) => r > 0);

  double calculatePercentage(int stars, int weight) {
    return (stars / 5) * weight;
  }

  double get totalPercentage {
    double total = 0;
    for (int i = 0; i < ratings.length; i++) {
      total += calculatePercentage(ratings[i], weights[i]);
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    checkIfSubmitted();
  }

  Future<void> checkIfSubmitted() async {
    final response = await http.get(
      Uri.parse(
          "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/check_final_vote/${widget.username}/${widget.title}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        alreadySubmitted = data["submitted"] == true;
      });
    }
  }

  Future<void> submitEvaluation() async {
    setState(() => isSubmitting = true);

    // Insert 5 pillar rows
    for (int i = 0; i < categories.length; i++) {
      await http.post(
        Uri.parse(
            "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/submit_vote"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idea_title": widget.title,
          "username": widget.username,
          "category": categories[i],
          "score": ratings[i],
          "comment": commentControllers[i].text.trim(),

        }),
      );
    }

    // Insert final summary row
    await http.post(
      Uri.parse(
          "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/submit_final_vote"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": widget.username,
        "idea_title": widget.title,
        "percentage": totalPercentage,
        "submit": true
      }),
    );

    setState(() {
      isSubmitting = false;
      alreadySubmitted = true;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          alreadySubmitted ? Colors.green.shade100 : Colors.white,
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
            // LEFT SIDE
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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

// TITLE
RichText(
  text: TextSpan(
    style: const TextStyle(fontSize: 18, color: Colors.black),
    children: [
      const TextSpan(
        text: "Al Initiative Title: ",
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

// SOLUTION
RichText(
  text: TextSpan(
    style: const TextStyle(fontSize: 18, color: Colors.black),
    children: [
      const TextSpan(
        text: "Summary of Al Solution:\n",
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

// IMPACT
RichText(
  text: TextSpan(
    style: const TextStyle(fontSize: 18, color: Colors.black),
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

// FILE
RichText(
  text: TextSpan(
    style: const TextStyle(fontSize: 18, color: Colors.black),
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
              recognizer: (TapGestureRecognizer()
                ..onTap = () {
                  html.window.open(widget.file, "_blank");
                }),
            ),
    ],
  ),
),
                            ],
                          ),
),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 40),

            // RIGHT SIDE
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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

                    ...List.generate(categories.length,
                        (index) =>
                            _buildStarRow(categories[index], index)),

                    const SizedBox(height: 20),

                    // Text(
                    //   "Total: ${totalPercentage.toStringAsFixed(1)}%",
                    //   style: const TextStyle(
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.bold,
                    //     color: primaryColor,
                    //   ),
                    // ),


                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        onPressed: isComplete &&
                                !isSubmitting &&
                                !alreadySubmitted
                            ? submitEvaluation
                            : null,
                        child: alreadySubmitted
                            ? const Text("Already Submitted")
                            : isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Submit Evaluation"),
                      ),
                    )
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
                    onPressed: alreadySubmitted
                        ? null
                        : () {
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
          enabled: !alreadySubmitted,
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





