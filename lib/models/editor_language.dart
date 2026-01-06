/// Supported programming languages for syntax highlighting in the editor.
///
/// This enum represents all languages supported by the highlight.js package
/// used in the phone_ide editor. Each enum value corresponds to a language
/// identifier that can be used for syntax highlighting.
enum EditorLanguage {
  // Web Development
  html('html'),
  css('css'),
  javascript('javascript'),
  typescript('typescript'),
  json('json'),
  xml('xml'),

  // Markup & Documentation
  markdown('markdown'),
  yaml('yaml'),

  // Mobile Development
  dart('dart'),
  kotlin('kotlin'),
  swift('swift'),

  // Systems Programming
  c('c'),
  cpp('cpp'),
  rust('rust'),
  go('go'),

  // JVM Languages
  java('java'),
  scala('scala'),
  groovy('groovy'),

  // Functional Programming
  haskell('haskell'),
  fsharp('fsharp'),
  clojure('clojure'),
  elixir('elixir'),
  erlang('erlang'),

  // Scripting Languages
  python('python'),
  ruby('ruby'),
  php('php'),
  perl('perl'),
  lua('lua'),

  // .NET Languages
  csharp('csharp'),

  // Shell & Config
  bash('bash'),
  shell('shell'),
  powershell('powershell'),
  dockerfile('dockerfile'),

  // Database
  sql('sql'),
  graphql('graphql'),

  // Other Popular Languages
  r('r'),
  coffeescript('coffeescript');

  const EditorLanguage(this.identifier);

  /// The language identifier string used by highlight.js
  final String identifier;

  @override
  String toString() => identifier;
}
