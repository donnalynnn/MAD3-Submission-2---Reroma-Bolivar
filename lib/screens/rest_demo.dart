// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import '/models/post.model.dart';
import '/models/user.model.dart';

class RestDemoScreen extends StatefulWidget {
  const RestDemoScreen({super.key});

  @override
  State<RestDemoScreen> createState() => _RestDemoScreenState();
}

class _RestDemoScreenState extends State<RestDemoScreen> {
  PostController controller = PostController();

  @override
  void initState() {
    super.initState();
    controller.getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Posts"),
        leading: IconButton(
            onPressed: () {
              controller.getPosts();
            },
            icon: const Icon(Icons.refresh)),
        actions: [
          IconButton(
              onPressed: () {
                showNewPostFunction(context);
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.error != null) {
                return Center(
                  child: Text(controller.error.toString()),
                );
              }

              if (!controller.working) {
                return Center(
                    child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (Post post in controller.postList)
                      Container(
                          width: 500,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(16)),
                          child: GestureDetector(
                              onLongPress: () {
                                controller.deletePost(post.id.toString());
                              },
                              onTap: () {
                                showEditPostDialog(context, post);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: post.title.toUpperCase(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      post.body.length > 150
                                          ? "${post.body.substring(0, 150)}..."
                                          : post.body,
                                    ),
                                  ),
                                ],
                              )))
                  ]),
                ));
              }
              return const Center(
                child: SpinKitChasingDots(
                  size: 54,
                  color: Colors.black87,
                ),
              );
            }),
      ),
    );
  }

  showNewPostFunction(BuildContext context) {
    AddPostDialog.show(context, controller: controller);
  }

  showEditPostDialog(BuildContext context, Post post) {
    EditPostDialog.show(context, controller: controller, post: post);
  }
}

class AddPostDialog extends StatefulWidget {
  static show(BuildContext context, {required PostController controller}) =>
      showDialog(
          context: context, builder: (dContext) => AddPostDialog(controller));
  const AddPostDialog(this.controller, {super.key});

  final PostController controller;

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  late TextEditingController bodyC, titleC;

  @override
  void initState() {
    super.initState();
    bodyC = TextEditingController();
    titleC = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Add new post"),
      actions: [
        ElevatedButton(
          onPressed: () async {
            widget.controller.makePost(
                title: titleC.text.trim(), body: bodyC.text.trim(), userId: 1);
            Navigator.of(context).pop();
          },
          child: const Text("Add"),
        )
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Title"),
          Flexible(
            child: TextFormField(
              controller: titleC,
            ),
          ),
          const Text("Content"),
          Flexible(
            child: TextFormField(
              controller: bodyC,
            ),
          ),
        ],
      ),
    );
  }
}

class EditPostDialog extends StatefulWidget {
  static show(BuildContext context,
          {required PostController controller, required Post post}) =>
      showDialog(
          context: context,
          builder: (dContext) => EditPostDialog(controller, post));
  const EditPostDialog(this.controller, this.post, {super.key});

  final PostController controller;
  final Post post;

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  late TextEditingController bodyC, titleC;

  @override
  void initState() {
    super.initState();
    bodyC = TextEditingController(text: widget.post.body);
    titleC = TextEditingController(text: widget.post.title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Edit post"),
      actions: [
        ElevatedButton(
          onPressed: () {
            widget.controller.editPost(
                id: widget.post.id,
                title: titleC.text.trim(),
                body: bodyC.text.trim());
            Navigator.of(context).pop();
          },
          child: const Text("Save"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Title"),
          Flexible(
            child: TextFormField(
              controller: titleC,
            ),
          ),
          const Text("Content"),
          Flexible(
            child: TextFormField(
              controller: bodyC,
            ),
          ),
        ],
      ),
    );
  }
}

class PostController with ChangeNotifier {
  Map<String, dynamic> posts = {};
  bool working = true;
  Object? error;

  List<Post> get postList => posts.values.whereType<Post>().toList();

  clear() {
    error = null;
    posts = {};
    notifyListeners();
  }

  Future<Post> makePost(
      {required String title,
      required String body,
      required int userId}) async {
    try {
      working = true;
      if (error != null) error = null;
      print(title);
      print(body);
      print(userId);
      http.Response res = await HttpService.post(
          url: "https://jsonplaceholder.typicode.com/posts",
          body: {"title": title, "body": body, "userId": userId});
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }

      print(res.body);

      Map<String, dynamic> result = jsonDecode(res.body);

      Post output = Post.fromJson(result);
      posts[output.id.toString()] = output;
      working = false;
      notifyListeners();
      return output;
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
      return Post.empty;
    }
  }

  Future<void> getPosts() async {
    try {
      working = true;
      clear();
      List result = [];
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/posts");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      result = jsonDecode(res.body);

      List<Post> tmpPost = result.map((e) => Post.fromJson(e)).toList();
      posts = {for (Post p in tmpPost) "${p.id}": p};
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

  void deletePost(String postId) {
    posts.remove(postId);
    notifyListeners();
  }

  void editPost(
      {required int id, required String title, required String body}) {
    posts[id.toString()] = Post(id: id, title: title, body: body, userId: 1);
    notifyListeners();
  }
}

class UserController with ChangeNotifier {
  Map<String, dynamic> users = {};
  bool working = true;
  Object? error;

  List<User> get userList => users.values.whereType<User>().toList();

  getUsers() async {
    try {
      working = true;
      List result = [];
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/users");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      result = jsonDecode(res.body);

      List<User> tmpUser = result.map((e) => User.fromJson(e)).toList();
      users = {for (User u in tmpUser) "${u.id}": u};
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

  clear() {
    users = {};
    notifyListeners();
  }
}

class HttpService {
  static Future<http.Response> get(
      {required String url, Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }

  static Future<http.Response> post(
      {required String url,
      required Map<dynamic, dynamic> body,
      Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }
}
