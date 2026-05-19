import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Admin accounts
const Map<String, String> admins = {
  "Hossein_1997": "1234567",
  "AmirAli_1997": "1234567",
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

// ---------------- LOGIN ----------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();

  Future<void> login() async {
    String username = user.text.trim();
    String password = pass.text.trim();

    // ADMIN LOGIN
    if (admins.containsKey(username) &&
        admins[username] == password) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanel()),
      );
      return;
    }

    // STUDENT LOGIN
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: username,
      password: password,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentHome()),
    );
  }

  Future<void> register() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: user.text,
      password: pass.text,
    );

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "email": user.text,
      "role": "student",
      "score": 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mathverse School PRO")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: user),
            TextField(controller: pass),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: login, child: const Text("Login")),
            ElevatedButton(onPressed: register, child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}

// ---------------- STUDENT ----------------

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student 🎓")),
      body: Column(
        children: [

          ElevatedButton(
            child: const Text("👤 Profile"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),

          ElevatedButton(
            child: const Text("🏆 Leaderboard"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Leaderboard()),
            ),
          ),

          ElevatedButton(
            child: const Text("📚 Assignments"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignmentPage()),
            ),
          ),

          ElevatedButton(
            child: const Text("💬 Feedback"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackPage()),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- PROFILE ----------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile 👤")),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final data = snapshot.data!;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 80),
              Text("Email: ${data["email"]}"),
              Text("Score: ⭐ ${data["score"]}"),
            ],
          );
        },
      ),
    );
  }
}

// ---------------- LEADERBOARD ----------------

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  String medal(int i) {
    if (i == 0) return "🥇";
    if (i == 1) return "🥈";
    if (i == 2) return "🥉";
    return "🏅";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leaderboard 🏆")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .orderBy("score", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              return ListTile(
                leading: Text(medal(i)),
                title: Text(data[i]["email"]),
                trailing: Text("⭐ ${data[i]["score"]}"),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- ASSIGNMENTS ----------------

class AssignmentPage extends StatelessWidget {
  const AssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignments 📚")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("assignments").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final data = snapshot.data!.docs;

          return ListView(
            children: data.map((e) => ListTile(
              title: Text(e["title"]),
              subtitle: Text("Level ${e["level"]}"),
            )).toList(),
          );
        },
      ),
    );
  }
}

// ---------------- FEEDBACK ----------------

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final c = TextEditingController();

  void send() {
    FirebaseFirestore.instance.collection("feedback").add({
      "message": c.text,
      "reply": "",
      "createdAt": DateTime.now().toString(),
    });

    c.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feedback 💬")),
      body: Column(
        children: [
          TextField(controller: c),
          ElevatedButton(onPressed: send, child: const Text("Send")),
        ],
      ),
    );
  }
}

// ---------------- ADMIN ----------------

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin 👑")),
      body: const Center(
        child: Text("Admin Panel Ready"),
      ),
    );
  }
}
