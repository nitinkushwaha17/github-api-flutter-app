import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GitHub API'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class LastCommit {
  String? author;
  String? message;

  LastCommit({this.author, this.message});
}

class RepoDetails {
  String? name;
  int? stars;

  RepoDetails({this.name, this.stars});
}

class User {
  String? username;
  String? avatarUrl;

  User({this.username, this.avatarUrl});
}

class _MyHomePageState extends State<MyHomePage> {
  List<RepoDetails> repoList = [];
  List<LastCommit> commitList = [];
  bool isLoading = true;
  String currentUsername = "freeCodeCamp";
  User user = User(
      username: "freeCodeCamp",
      avatarUrl: "https://avatars.githubusercontent.com/u/9892522?v=4");
  final inputController = TextEditingController();
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    getRepos();
    getUserInfo();
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void getRepos() async {
    final uri = Uri.https('api.github.com', '/users/$currentUsername/repos');

    final response = await http.get(uri);

    List<RepoDetails> list = [];

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      for (var repo in jsonResponse) {
        list.add(
            RepoDetails(name: repo["name"], stars: repo["stargazers_count"]));
      }
    }

    setState(() {
      repoList = list;
      isLoading = false;
    });
  }

  Future<LastCommit> getLastCommit(int index) async {
    var response = await http.get(
      Uri.https(
        'api.github.com',
        'repos/$currentUsername/${repoList[index].name}/commits',
      ),
    );

    LastCommit commit = LastCommit(author: '', message: '');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse.isNotEmpty) {
        commit.author = jsonResponse[0]['commit']['author']['name'];
        commit.message = jsonResponse[0]['commit']['message'];
      }
      return commit;
    } else {
      throw Exception("Error fetching commit");
    }
  }

  void getUserInfo() async {
    var response =
        await http.get(Uri.https('api.github.com', '/users/$currentUsername'));

    User usr = User(username: '', avatarUrl: '');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      if (jsonResponse.isNotEmpty) {
        usr.username = currentUsername;
        usr.avatarUrl = jsonResponse['avatar_url'];
      }
      setState(() {
        user = usr;
        errorMessage = "";
      });
    } else {
      errorMessage = "User not found";
    }
  }

  void handleSubmit(String username) {
    setState(() {
      currentUsername = username;
    });
    getRepos();
    getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: inputController,
                onSubmitted: (value) {
                  handleSubmit(value);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter github username',
                ),
              )),
          errorMessage != ""
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : Card(
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Image(image: NetworkImage(user.avatarUrl!)),
                        title: Text(currentUsername,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ))),
          const Text('Repositories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: repoList.length,
                      itemBuilder: (context, index) {
                        return Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: const Color.fromARGB(255, 255, 255, 255),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 1.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                                title: Column(children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      repoList[index].name!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.yellow,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(repoList[index].stars!.toString())
                                      ],
                                    )
                                  ]),
                              const Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Text(
                                    'Last commit -',
                                    style: TextStyle(fontSize: 14),
                                  )),
                              FutureBuilder<LastCommit?>(
                                future: getLastCommit(index),
                                builder: (context, commitSnapshot) {
                                  if (commitSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (commitSnapshot.hasError) {
                                    return Text(
                                      'Error: ${commitSnapshot.error}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                      ),
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        Text(
                                            'Author: ${commitSnapshot.data?.author}'),
                                        Text(
                                            'Commit message: ${commitSnapshot.data?.message}'),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ])));
                      }))
        ]));
  }
}
