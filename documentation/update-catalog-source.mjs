import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { extname, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const documentationDirectory = resolve(fileURLToPath(new URL('.', import.meta.url)));
const repositoryRoot = resolve(documentationDirectory, '..');
const catalogDirectory = resolve(documentationDirectory, 'catalog');
const eventCatalogDocumentationDirectory = resolve(documentationDirectory, 'event-catalog');
const sourceRoots = [
  resolve(repositoryRoot, 'example-backend', 'src', 'main'),
  resolve(repositoryRoot, 'example-frontend', 'src')
];
const ignoredDirectories = new Set(['node_modules', 'target', 'dist', '.angular']);
const sourceExtensions = new Set(['.java', '.ts', '.html', '.css', '.scss']);

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (ignoredDirectories.has(entry.name)) continue;
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...await collectFiles(path));
    } else if (sourceExtensions.has(extname(entry.name))) {
      files.push(path);
    }
  }
  return files;
}

const sourceFiles = (await Promise.all(sourceRoots.map(collectFiles))).flat().sort();
const sourceText = await Promise.all(sourceFiles.map(async (path) => ({
  path,
  text: await readFile(path, 'utf8')
})));
const restEndpoints = new Set();
const websocketEndpoints = new Set();
for (const { text } of sourceText) {
  for (const match of text.matchAll(/@RequestMapping\("([^"]+)"\)/g)) restEndpoints.add(match[1]);
  for (const match of text.matchAll(/@GetMapping(?:\("([^"]*)"\))?/g)) restEndpoints.add(match[1] || '/');
  if (text.includes('/ws/clock') || text.includes('registerWebSocketHandlers')) websocketEndpoints.add('/ws/clock');
}

const generatedAt = new Date().toISOString().slice(0, 10);
const sourceInventory = sourceText.map(({ path }) => `- \`${relative(repositoryRoot, path).replaceAll('\\', '/')}\``).join('\n');
const restList = [...restEndpoints].sort().map((endpoint) => `- \`${endpoint}\``).join('\n') || '- None detected';
const websocketList = [...websocketEndpoints].sort().map((endpoint) => `- \`${endpoint}\``).join('\n') || '- None detected';

await mkdir(resolve(catalogDirectory, 'docs'), { recursive: true });
await mkdir(resolve(catalogDirectory, 'events'), { recursive: true });
await mkdir(eventCatalogDocumentationDirectory, { recursive: true });
await writeFile(resolve(catalogDirectory, 'docs', 'implementation-source.md'), `# Implementation source inventory\n\nGenerated from the github-example implementation on ${generatedAt}.\n\n## REST surfaces\n\n${restList}\n\n## WebSocket surfaces\n\n${websocketList}\n\n## Source files\n\n${sourceInventory}\n`, 'utf8');
await writeFile(resolve(catalogDirectory, 'events', 'clock-update.md'), `---\nname: Clock Update\nversion: 1.0.0\nsummary: The backend broadcasts the current clock payload to connected WebSocket clients.\nowners:\n  - example-backend\n---\n\n# Clock Update\n\nThis event is derived from the Spring Boot clock service and Angular WebSocket client. The backend sends an initial payload and approximately one update per second over the configured clock WebSocket endpoint.\n\nSee [the generated implementation source inventory](../docs/implementation-source.md).\n`, 'utf8');
const mermaid = `flowchart LR\n    Backend[Spring Boot backend] --> REST[GET /api/v1/clock]\n    Backend --> Event[Clock Update event]\n    Event --> WS[WebSocket /ws/clock]\n    REST --> Frontend[Angular frontend]\n    WS --> Frontend\n`;
await writeFile(resolve(eventCatalogDocumentationDirectory, 'architecture.mmd'), mermaid, 'utf8');
await writeFile(resolve(documentationDirectory, 'event-catalog.html'), `<!DOCTYPE html>\n<html lang="en">\n<head>\n    <meta charset="UTF-8">\n    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n    <title>Event catalog | Example Project</title>\n    <link rel="stylesheet" href="styles.css">\n    <script src="nav-loader.js" defer></script>\n    <script type="module">\n        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';\n        mermaid.initialize({ startOnLoad: true, securityLevel: 'strict' });\n    </script>\n</head>\n<body>\n<aside class="sidebar" data-generated-nav="true"></aside>\n<main class="main-content"><header class="header"><h2>Event catalog</h2></header><div class="content">\n<section class="content-section"><h3>Implementation-derived architecture</h3>\n<p>This page and its diagram are generated from the current EventCatalog entries and the Java/Angular implementation. Run the platform updater after source changes.</p>\n<pre class="mermaid">${mermaid}</pre>\n<p><a href="event-catalog/architecture.mmd">Open the generated Mermaid export</a> or <a href="catalog/docs/implementation-source.md">inspect the generated source inventory</a>.</p>\n</section></div></main>\n</body>\n</html>\n`, 'utf8');
console.log(`Updated EventCatalog source entries in ${catalogDirectory}`);
