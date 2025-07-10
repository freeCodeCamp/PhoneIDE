import 'package:flutter/material.dart';
import 'package:phone_ide/highlight_engine/highlight_engine.dart';

void main() {
  runApp(const HighlightDemoApp());
}

class HighlightDemoApp extends StatelessWidget {
  const HighlightDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTML Highlight Demo',
      theme: ThemeData.dark(),
      home: const HighlightDemoPage(),
    );
  }
}

class HighlightDemoPage extends StatefulWidget {
  const HighlightDemoPage({super.key});

  @override
  State<HighlightDemoPage> createState() => _HighlightDemoPageState();
}

class _HighlightDemoPageState extends State<HighlightDemoPage> {
  String html = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Highlight Test Page</title>
  <style>
    /* Basic layout */
    body {
      margin: 0;
      padding: 20px;
      background-color: #1e1e1e;
      color: #ffffff;
      font-family: Arial, sans-serif;
    }

    h1.title {
      color: #61dafb;
      font-size: 2rem;
    }

    .container {
      display: flex;
      gap: 1rem;
    }

    #main-content {
      flex: 2;
      padding: 1em;
      background-color: #2c2c2c;
    }

    .sidebar {
      flex: 1;
      background-color: #333;
      padding: 1em;
    }

    a:hover {
      color: #f0c674;
    }
  </style>
</head>
<body>
  <!-- Header -->
  <header>
    <h1 class="title">Syntax Highlight Demo</h1>
  </header>

  <div class="container">
    <section id="main-content">
      <p>Welcome to the <strong>highlight test</strong> page. Check out the syntax styling below!</p>
      <button onclick="toggleTheme()">Toggle Theme</button>
    </section>

    <aside class="sidebar">
      <ul>
        <li><a href="#">Nav Link 1</a></li>
        <li><a href="#">Nav Link 2</a></li>
      </ul>
    </aside>
  </div>

  <script>
    // Toggle light/dark theme
    function toggleTheme() {
      const body = document.body;
      const current = body.style.backgroundColor;
      if (current === "white") {
        body.style.backgroundColor = "#1e1e1e";
        body.style.color = "#ffffff";
      } else {
        body.style.backgroundColor = "white";
        body.style.color = "black";
      }
    }

    // Example variables
    let count = 0;
    const message = "Hello world!";
    console.log(message);

    for (let i = 0; i < 5; i++) {
      count += i;
      console.log("Count is now", count);
    }
  </script>
</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    final engine = HighlightEngine();
    final highlighted = engine.highlight(html);

    return Scaffold(
      appBar: AppBar(title: const Text('HTML Highlight Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(text: html),
              maxLines: 8,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'HTML Input',
              ),
              onChanged: (value) => setState(() => html = value),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Highlighted Output:',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  highlighted,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
