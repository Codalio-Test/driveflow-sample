/**
 * Mount probe: loads the built bundle in a DOM and asserts that #root actually
 * renders. "The build exited 0" does not prove the app mounts — a failed
 * provider/router/import chain leaves an empty #root with no console error.
 *
 * Run with: node scripts/mount-check.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { JSDOM } from 'jsdom';

const ROOT = path.resolve(import.meta.dirname, '..');
const args = process.argv.slice(2).filter((arg) => !arg.startsWith('--'));
const targetUrl = args[0] || 'http://localhost/';
const tokenArg = process.argv.find((arg) => arg.startsWith('--token='));
const orgArg = process.argv.find((arg) => arg.startsWith('--org='));
const token = tokenArg ? tokenArg.slice('--token='.length) : '';
const organization = orgArg ? orgArg.slice('--org='.length) : '';
const distIndex = fs.readFileSync(path.join(ROOT, 'dist/index.html'), 'utf8');
const entry = distIndex.match(/src="(\/assets\/index-[^"]+\.js)"/)?.[1];
if (!entry) throw new Error('no entry bundle found in dist/index.html');

const dom = new JSDOM('<!doctype html><html><body><div id="root"></div></body></html>', {
  url: targetUrl,
  pretendToBeVisual: true,
});

globalThis.window = dom.window;
globalThis.document = dom.window.document;
Object.defineProperty(globalThis, 'navigator', { value: dom.window.navigator, configurable: true });
globalThis.location = dom.window.location;
globalThis.HTMLElement = dom.window.HTMLElement;
globalThis.Element = dom.window.Element;
globalThis.Node = dom.window.Node;
globalThis.MutationObserver = dom.window.MutationObserver;
globalThis.Event = dom.window.Event;
globalThis.CustomEvent = dom.window.CustomEvent;
globalThis.DOMParser = dom.window.DOMParser;
globalThis.DocumentFragment = dom.window.DocumentFragment;
globalThis.HTMLInputElement = dom.window.HTMLInputElement;
globalThis.HTMLButtonElement = dom.window.HTMLButtonElement;
globalThis.HTMLAnchorElement = dom.window.HTMLAnchorElement;
globalThis.SVGElement = dom.window.SVGElement;
globalThis.Range = dom.window.Range;
globalThis.getSelection = dom.window.getSelection?.bind(dom.window);
globalThis.XMLHttpRequest = dom.window.XMLHttpRequest;
globalThis.localStorage = dom.window.localStorage;
globalThis.sessionStorage = dom.window.sessionStorage;
globalThis.getComputedStyle = dom.window.getComputedStyle;
globalThis.requestAnimationFrame = (cb) => setTimeout(cb, 0);
globalThis.cancelAnimationFrame = clearTimeout;
globalThis.IS_REACT_ACT_ENVIRONMENT = false;
window.matchMedia = window.matchMedia ?? (() => ({ matches: false, addEventListener() {}, removeEventListener() {} }));

// Optional authenticated mode: seed the session the way configureApi's storage
// adapter reads it, so guarded routes render their real page instead of
// bouncing to the login screen.
if (token) window.localStorage.setItem('token', token);
if (organization) window.localStorage.setItem('organization_slug', organization);

const bundlePath = path.join(ROOT, 'dist', entry.replace(/^\//, ''));
await import(`file://${bundlePath}`);

await new Promise((resolve) => setTimeout(resolve, token ? Number(process.env.PROBE_WAIT_MS || 6000) : 400));

const root = document.getElementById('root');
const text = (root?.textContent ?? '').replace(/\s+/g, ' ').trim();

if (!text) {
  console.error('FAIL: #root rendered nothing (blank screen)');
  process.exit(1);
}

if (/DriveFlow hit an unexpected error/.test(text)) {
  console.error('FAIL: the render error boundary caught a crash');
  console.error(text.slice(0, 400));
  process.exit(1);
}

console.log(`#root rendered ${text.length} chars`);
console.log('---');
console.log(text.slice(0, 400));
process.exit(0);
