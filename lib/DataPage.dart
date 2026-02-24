import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:voting/AdminPage.dart';
import 'package:voting/main.dart';
import 'dart:convert';
import 'PillarVotingPage.dart';

import 'dart:html' as html;


class DataPage extends StatefulWidget {
  final String username;
  const DataPage({super.key, required this.username});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<Map<String, dynamic>> initiatives = [];
  bool isLoading = true;

  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchInitiatives();
  }

  Future<void> fetchInitiatives() async {
    final response = await http.get(
      Uri.parse(
          "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/get_initiatives"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      List<Map<String, dynamic>> temp = [];

      for (var item in data) {
        final checkResponse = await http.get(
          Uri.parse(
              "https://voting-c6gqfjhxffbucyfy.westeurope-01.azurewebsites.net/check_final_vote/${widget.username}/${item["title"]}"),
        );

        bool submitted = false;

        if (checkResponse.statusCode == 200) {
          final checkData = jsonDecode(checkResponse.body);
          submitted = checkData["submitted"] == true;
        }

        temp.add({
          "title": item["title"],
          "solution": item["solution"],
          "impact": item["impact"],
          "file": item["file"],
          "submitted": submitted,
        });
      }

      setState(() {
        initiatives = temp;
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
           if (widget.username == "Admin")
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
        padding: const EdgeInsets.all(20),
        child: Scrollbar(
          controller: _vertical,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _vertical,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (notif) =>
                  notif.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    Row(
                      children: const [
                        _HeaderCell("ID", 100),
                        _HeaderCell("AI Initiative Title", 200),
                        _HeaderCell("Summary of AI Solution", 400),
                        _HeaderCell("Business Impact Explanation", 400),
                        _HeaderCell("File Path", 200),
                        _HeaderCell("Action", 150),
                      ],
                    ),
                    Column(
                      children:
                          initiatives.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;

                        return Container(
                          color: item["submitted"] == true
                              ? Colors.green.shade200
                              : Colors.white,
                          child: Row(
                            children: [
                              _IndexCell("${index + 1}", 100),
                              _DataCell(item["title"], 200),
                              _DataCell(item["solution"], 400),
                              _DataCell(item["impact"], 400),
                              _FileLinkCell(item["file"], 200),                              _ActionCell(
                                width: 150,
                                onPressed: item["submitted"] == true
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PillarVotingPage(
                                              title: item["title"],
                                              solution:
                                                  item["solution"],
                                              impact:
                                                  item["impact"],
                                              username:
                                                  widget.username,
                                              file:
                                                  item["file"] ??
                                                      "-",
                                            ),
                                          ),
                                        ).then((_) {
                                          fetchInitiatives();
                                        });
                                      },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _IndexCell extends StatelessWidget {
  final String text;
  final double width;

  const _IndexCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String? text;
  final double width;

  const _DataCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: SingleChildScrollView(
        child: Text(text ?? ""),
      ),
    );
  }
}

class _FileLinkCell extends StatelessWidget {
  final String? url;
  final double width;

  const _FileLinkCell(this.url, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: url == null || url!.isEmpty
          ? const Text("-")
          : InkWell(
              onTap: () {
  html.window.open(url!, "_blank");
},

              child: const Text(
                "Open File",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
    );
  }
}


class _ActionCell extends StatelessWidget {
  final double width;
  final VoidCallback? onPressed;

  const _ActionCell({required this.width, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              onPressed == null ? Colors.grey : const Color.fromARGB(255, 255, 255, 255),
        ),
        child: Text(onPressed == null ? "Submitted" : "Vote"),
      ),
    );
  }
}


