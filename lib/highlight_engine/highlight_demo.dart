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
     /* CSS Variables */
  :root {
    --main-color: #3498db;
    --spacing-unit: 1rem;
    --transition-speed: 0.3s;
  }

  /* Media Query */
  @media screen and (max-width: 768px) {
    .responsive-container {
      display: flex;
      flex-direction: column;
      gap: calc(var(--spacing-unit) * 2);
    }
  }

  /* Feature Query */
  @supports (display: grid) {
    .grid-layout {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: var(--spacing-unit);
    }
  }

  /* Complex Selectors, Pseudo-classes & Attribute Selectors */
  .button, button[type="submit"], [role="button"] {
    background: linear-gradient(45deg, var(--main-color), #2ecc71 70%);
    border: none;
    padding: calc(var(--spacing-unit) * 0.75) var(--spacing-unit);
    color: #fff;
    cursor: pointer;
    transition:
      background var(--transition-speed) ease-in-out,
      transform var(--transition-speed);
  }

  .button:hover:not(.disabled)::after {
    content: ' ↗';
  }

  .button:active {
    transform: scale(0.95);
  }

  /* @keyframes animation */
  @keyframes fadeIn {
    0%   { opacity: 0; transform: translateY(-10px); }
    50%  { opacity: 0.5; }
    100% { opacity: 1; transform: translateY(0); }
  }

  .alert {
    animation: fadeIn 1s ease forwards;
    box-shadow:
      0 2px 4px rgba(0,0,0,0.1),
      0 8px 16px rgba(0,0,0,0.1);
    filter: drop-shadow(0 0 0.25rem var(--main-color));
  }

  /* Pseudo-element on form input */
  input[type="text"]::placeholder {
    color: rgba(255,255,255,0.5);
  }

  /* Child combinator + nth-child */
  nav > ul li:nth-child(odd) a {
    background-color: hsl(200, 50%, 50%);
  }

  /* Attribute selectors */
  [data-theme="dark"] .modal {
    backdrop-filter: blur(10px);
  }
</style>
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
