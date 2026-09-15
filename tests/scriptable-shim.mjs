// A Node mock of the Scriptable (iOS) API, strict where Scriptable is strict.
// Scriptable's bridge rejects wrong argument TYPES ("Expected value of type
// string but got value of type number") — the shim throws the same way, so a
// widget that would crash on the phone crashes here. Geometry made of NaN
// renders nothing on the phone; the shim records it as a warning.
export function makeScriptableEnv(opts) {
  const o = Object.assign({ family: 'small', parameter: '', runsInWidget: true, net: {} }, opts || {});
  const env = { warnings: [], widget: null, drawOps: 0, textDraws: 0, netCalls: [], logs: [] };
  const warn = m => env.warnings.push(m);
  const expect = (v, type, what) => {
    if (typeof v !== type) throw new TypeError('Expected value of type ' + type + ' but got value of type ' + typeof v + ' (' + what + ')');
  };
  const expectInstance = (v, cls, what) => {
    if (!(v instanceof cls)) throw new TypeError('Expected value of type ' + cls.name + ' but got ' + (v === null ? 'null' : typeof v) + ' (' + what + ')');
  };
  const numOk = (n, what) => { if (typeof n !== 'number') throw new TypeError('Expected number for ' + what + ' got ' + typeof n); if (!isFinite(n)) warn('non-finite ' + what); };

  class Color {
    constructor(hex, alpha) {
      expect(hex, 'string', 'Color hex');
      if (!/^#?[0-9a-fA-F]{3,8}$/.test(hex)) warn('odd color hex ' + hex);
      this.hex = hex; this.alpha = alpha == null ? 1 : alpha;
      if (alpha != null) numOk(alpha, 'Color alpha');
    }
    static white() { return new Color('#FFFFFF'); }
    static black() { return new Color('#000000'); }
    static clear() { return new Color('#000000', 0); }
    static gray() { return new Color('#888888'); }
    static red() { return new Color('#FF0000'); }
    static dynamic(a) { return a; }
  }
  class Font {
    constructor(name, size) { expect(name, 'string', 'Font name'); numOk(size, 'Font size'); this.name = name; this.size = size; }
  }
  for (const n of ['systemFont', 'boldSystemFont', 'mediumSystemFont', 'semiboldSystemFont', 'heavySystemFont', 'lightSystemFont',
    'italicSystemFont', 'blackSystemFont', 'thinSystemFont', 'ultraLightSystemFont', 'regularRoundedSystemFont',
    'boldRoundedSystemFont', 'semiboldRoundedSystemFont', 'blackRoundedSystemFont', 'mediumRoundedSystemFont',
    'regularMonospacedSystemFont', 'boldMonospacedSystemFont', 'semiboldMonospacedSystemFont']) {
    Font[n] = size => new Font(n, size);
  }
  for (const n of ['body', 'headline', 'title1', 'title2', 'title3', 'largeTitle', 'caption1', 'caption2', 'footnote', 'subheadline', 'callout']) {
    Font[n] = () => new Font(n, 15);
  }
  class Point { constructor(x, y) { numOk(x, 'Point.x'); numOk(y, 'Point.y'); this.x = x; this.y = y; } }
  class Size { constructor(w, h) { numOk(w, 'Size.width'); numOk(h, 'Size.height'); this.width = w; this.height = h; } }
  class Rect {
    constructor(x, y, w, h) {
      numOk(x, 'Rect.x'); numOk(y, 'Rect.y'); numOk(w, 'Rect.width'); numOk(h, 'Rect.height');
      this.x = x; this.y = y; this.width = w; this.height = h;
    }
    get minX() { return this.x; } get minY() { return this.y; }
    get maxX() { return this.x + this.width; } get maxY() { return this.y + this.height; }
    get origin() { return new Point(this.x, this.y); } get size() { return new Size(this.width, this.height); }
  }
  class Path {
    constructor() { this.ops = 0; }
    move(p) { expectInstance(p, Point, 'Path.move'); this.ops++; }
    addLine(p) { expectInstance(p, Point, 'Path.addLine'); this.ops++; }
    addLines(ps) { if (!Array.isArray(ps)) throw new TypeError('Path.addLines expects array'); ps.forEach(p => expectInstance(p, Point, 'Path.addLines')); this.ops++; }
    addRect(r) { expectInstance(r, Rect, 'Path.addRect'); this.ops++; }
    addRects(rs) { rs.forEach(r => expectInstance(r, Rect, 'Path.addRects')); this.ops++; }
    addEllipse(r) { expectInstance(r, Rect, 'Path.addEllipse'); this.ops++; }
    addRoundedRect(r, cw, ch) { expectInstance(r, Rect, 'Path.addRoundedRect'); numOk(cw, 'corner w'); numOk(ch, 'corner h'); this.ops++; }
    addCurve(p, c1, c2) { expectInstance(p, Point, 'Path.addCurve'); this.ops++; }
    addQuadCurve(p, c) { expectInstance(p, Point, 'Path.addQuadCurve'); this.ops++; }
    closeSubpath() { this.ops++; }
  }
  class Image {
    constructor(w, h) { this.size = new Size(w, h); }
    static fromData(d) { if (!(d instanceof Data)) throw new TypeError('Image.fromData expects Data'); return new Image(d.w || 512, d.h || 512); }
    static fromFile(p) { expect(p, 'string', 'Image.fromFile'); return fs.get(p) instanceof Image ? fs.get(p) : null; }
  }
  class Data {
    constructor(s, w, h) { this.s = s; this.w = w; this.h = h; }
    static fromString(s) { expect(s, 'string', 'Data.fromString'); return new Data(s); }
    static fromBase64String(s) { expect(s, 'string', 'Data.fromBase64String'); return new Data(s); }
    static fromFile(p) { return fs.has(p) ? new Data(String(fs.get(p))) : null; }
    static fromPNG(img) { return new Data('', img.size.width, img.size.height); }
    static fromJPEG(img) { return new Data('', img.size.width, img.size.height); }
    toRawString() { return this.s || ''; }
    toBase64String() { return Buffer.from(this.s || '').toString('base64'); }
  }
  class DrawContext {
    constructor() { this.size = new Size(0, 0); this.opaque = true; this.respectScreenScale = false; this._path = null; this._font = null; }
    setFillColor(c) { expectInstance(c, Color, 'setFillColor'); }
    setStrokeColor(c) { expectInstance(c, Color, 'setStrokeColor'); }
    setLineWidth(n) { numOk(n, 'setLineWidth'); }
    fill(r) { expectInstance(r, Rect, 'fill'); env.drawOps++; }
    fillRect(r) { expectInstance(r, Rect, 'fillRect'); env.drawOps++; }
    fillEllipse(r) { expectInstance(r, Rect, 'fillEllipse'); env.drawOps++; }
    stroke(r) { expectInstance(r, Rect, 'stroke'); env.drawOps++; }
    strokeRect(r) { expectInstance(r, Rect, 'strokeRect'); env.drawOps++; }
    strokeEllipse(r) { expectInstance(r, Rect, 'strokeEllipse'); env.drawOps++; }
    addPath(p) { expectInstance(p, Path, 'addPath'); this._path = p; }
    fillPath() { if (!this._path) warn('fillPath without addPath'); env.drawOps++; }
    strokePath() { if (!this._path) warn('strokePath without addPath'); env.drawOps++; }
    drawImageAtPoint(img, p) { expectInstance(img, Image, 'drawImageAtPoint image'); expectInstance(p, Point, 'drawImageAtPoint point'); env.drawOps++; }
    drawImageInRect(img, r) { expectInstance(img, Image, 'drawImageInRect image'); expectInstance(r, Rect, 'drawImageInRect rect'); env.drawOps++; }
    drawText(t, p) { expect(t, 'string', 'drawText text'); expectInstance(p, Point, 'drawText point'); env.drawOps++; env.textDraws++; }
    drawTextInRect(t, r) { expect(t, 'string', 'drawTextInRect text'); expectInstance(r, Rect, 'drawTextInRect rect'); if (!this._font) warn('drawTextInRect before setFont'); env.drawOps++; env.textDraws++; }
    setFont(f) { expectInstance(f, Font, 'setFont'); this._font = f; }
    setTextColor(c) { expectInstance(c, Color, 'setTextColor'); }
    setTextAlignedLeft() {} setTextAlignedCenter() {} setTextAlignedRight() {}
    getImage() { if (!(this.size.width > 0 && this.size.height > 0)) throw new Error('DrawContext.getImage with empty size'); return new Image(this.size.width, this.size.height); }
  }
  // widget tree nodes — permissive on props, strict on the typed setters
  class WidgetText {
    constructor(t) { expect(t, 'string', 'addText'); this.text = t; }
    leftAlignText() {} centerAlignText() {} rightAlignText() {}
  }
  class WidgetDate {
    constructor(d) { if (!(d instanceof Date)) throw new TypeError('addDate expects Date'); this.date = d; }
    applyTimeStyle() {} applyDateStyle() {} applyRelativeStyle() {} applyOffsetStyle() {} applyTimerStyle() {}
    leftAlignText() {} centerAlignText() {} rightAlignText() {}
  }
  class WidgetImage {
    constructor(img) { expectInstance(img, Image, 'addImage'); this.image = img; }
    centerAlignImage() {} leftAlignImage() {} rightAlignImage() {}
    applyFillingContentMode() {} applyFittingContentMode() {}
  }
  class WidgetSpacer { constructor(n) { if (n != null) numOk(n, 'addSpacer'); } }
  class WidgetStack {
    constructor() { this.children = []; }
    addText(t) { const n = new WidgetText(t); this.children.push(n); return n; }
    addDate(d) { const n = new WidgetDate(d); this.children.push(n); return n; }
    addImage(i) { const n = new WidgetImage(i); this.children.push(n); return n; }
    addSpacer(n) { const s = new WidgetSpacer(n); this.children.push(s); return s; }
    addStack() { const s = new WidgetStack(); this.children.push(s); return s; }
    setPadding(a, b, c, d) { [a, b, c, d].forEach(v => numOk(v, 'setPadding')); }
    useDefaultPadding() {}
    layoutHorizontally() {} layoutVertically() {}
    centerAlignContent() {} topAlignContent() {} bottomAlignContent() {}
  }
  class ListWidget extends WidgetStack {
    async presentSmall() { env.widget = this; } async presentMedium() { env.widget = this; } async presentLarge() { env.widget = this; }
  }
  class LinearGradient { constructor() { this.colors = []; this.locations = []; } }
  // in-memory file system shared by FileManager.local()/iCloud()
  const fs = new Map();
  const fm = {
    documentsDirectory: () => '/docs', cacheDirectory: () => '/cache', libraryDirectory: () => '/lib', temporaryDirectory: () => '/tmp',
    joinPath: (a, b) => { expect(a, 'string', 'joinPath'); expect(b, 'string', 'joinPath'); return a.replace(/\/$/, '') + '/' + b; },
    fileExists: p => fs.has(p),
    readString: p => { if (!fs.has(p)) throw new Error('readString: no file ' + p); return String(fs.get(p)); },
    writeString: (p, s) => { expect(s, 'string', 'writeString'); fs.set(p, s); },
    readImage: p => { const v = fs.get(p); return v instanceof Image ? v : null; },
    writeImage: (p, img) => { expectInstance(img, Image, 'writeImage'); fs.set(p, img); },
    read: p => fs.has(p) ? new Data(String(fs.get(p))) : null,
    write: (p, d) => fs.set(p, d.s || ''),
    remove: p => fs.delete(p), listContents: () => [...fs.keys()], modificationDate: () => new Date(),
    isDirectory: () => false, createDirectory: () => {}, fileName: p => p.split('/').pop(), fileExtension: p => p.split('.').pop(),
    isFileDownloaded: () => true, downloadFileFromiCloud: async () => {}
  };
  const FileManager = { local: () => fm, iCloud: () => fm };
  class Request {
    constructor(url) { expect(url, 'string', 'Request url'); this.url = url; this.headers = {}; this.method = 'GET'; env.netCalls.push(url); }
    _route() {
      for (const key of Object.keys(o.net)) if (this.url.indexOf(key) >= 0) return o.net[key];
      throw new Error('network unavailable: ' + this.url.slice(0, 60));
    }
    async loadJSON() { const r = this._route(); if (typeof r === 'function') return r(this.url); if (typeof r === 'string') return JSON.parse(r); return r; }
    async loadString() { const r = this._route(); return typeof r === 'string' ? r : JSON.stringify(r); }
    async loadImage() { const r = this._route(); return r instanceof Image ? r : new Image(512, 512); }
    async load() { const r = this._route(); return new Data(typeof r === 'string' ? r : JSON.stringify(r)); }
  }
  const Device = {
    batteryLevel: () => o.battery == null ? 0.82 : o.battery, isCharging: () => !!o.charging,
    screenScale: () => 3, screenSize: () => new Size(393, 852), screenResolution: () => new Size(1179, 2556),
    model: () => 'iPhone', systemVersion: () => '18.0', isPhone: () => true, isPad: () => false, locale: () => 'en_US', language: () => 'en',
    isUsingDarkAppearance: () => true, name: () => 'iPhone'
  };
  const Script = { setWidget: w => { expectInstance(w, ListWidget, 'Script.setWidget'); env.widget = w; }, complete: () => { env.completed = true; }, name: () => 'WidgetKing' };
  const args = { widgetParameter: o.parameter, queryParameters: o.query || {}, plainTexts: [], urls: [], images: [], fileURLs: [] };
  const config = { runsInWidget: o.runsInWidget, runsInApp: !o.runsInWidget, runsInActionExtension: false, runsWithSiri: false, widgetFamily: o.family };
  const Location = { current: async () => ({ latitude: 36.85, longitude: -76.0, altitude: 0 }), setAccuracyToKilometer() {}, setAccuracyToBest() {}, setAccuracyToHundredMeters() {}, setAccuracyToTenMeters() {}, setAccuracyToThreeKilometers() {} };
  const CalendarEvent = {
    today: async () => (o.events || []).slice(), tomorrow: async () => [], thisWeek: async () => [], nextWeek: async () => [], between: async () => []
  };
  const Reminder = { allIncomplete: async () => (o.reminders || []).slice(), all: async () => [] };
  const Calendar = { forEvents: async () => [], forReminders: async () => [], defaultForEvents: async () => ({}), defaultForReminders: async () => ({}) };
  class Alert {
    constructor() { this.actions = []; }
    addAction(t) { expect(t, 'string', 'Alert.addAction'); this.actions.push(t); } addCancelAction(t) { expect(t, 'string', 'Alert.addCancelAction'); }
    addDestructiveAction(t) { this.actions.push(t); } addTextField() {} textFieldValue() { return ''; }
    async presentAlert() { return -1; } async presentSheet() { return -1; } async present() { return -1; }
  }
  const Photos = { fromLibrary: async () => new Image(1179, 2556), fromCamera: async () => new Image(1179, 2556), latestPhoto: async () => new Image(1179, 2556) };
  const Pasteboard = { copy: s => { env.pasteboard = s; }, paste: () => o.pasteboard || '', copyString: s => { env.pasteboard = s; }, pasteString: () => o.pasteboard || '', copyImage() {}, pasteImage: () => null };
  const Safari = { open: u => { env.opened = u; }, openInApp: async u => { env.opened = u; } };
  class DateFormatter {
    constructor() { this.dateFormat = ''; this.locale = 'en'; }
    useShortTimeStyle() { this.dateFormat = 'h:mm a'; } useMediumTimeStyle() { this.dateFormat = 'h:mm:ss a'; } useLongTimeStyle() { this.dateFormat = 'h:mm:ss a z'; }
    useNoTimeStyle() {} useShortDateStyle() { this.dateFormat = 'M/d/yy'; } useMediumDateStyle() { this.dateFormat = 'MMM d, yyyy'; } useLongDateStyle() { this.dateFormat = 'MMMM d, yyyy'; } useNoDateStyle() {}
    useFullDateStyle() { this.dateFormat = 'EEEE, MMMM d, yyyy'; } useFullTimeStyle() {}
    string(d) {
      if (!(d instanceof Date)) throw new TypeError('DateFormatter.string expects Date');
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      const h12 = d.getHours() % 12 || 12;
      const pad = n => String(n).padStart(2, '0');
      return String(this.dateFormat)
        .replace(/EEEE/g, days[d.getDay()]).replace(/EEE/g, days[d.getDay()].slice(0, 3))
        .replace(/MMMM/g, months[d.getMonth()]).replace(/MMM/g, months[d.getMonth()].slice(0, 3))
        .replace(/yyyy/g, String(d.getFullYear())).replace(/yy/g, String(d.getFullYear()).slice(2))
        .replace(/MM/g, pad(d.getMonth() + 1)).replace(/\bM\b/g, String(d.getMonth() + 1))
        .replace(/dd/g, pad(d.getDate())).replace(/\bd\b/g, String(d.getDate()))
        .replace(/HH/g, pad(d.getHours())).replace(/hh/g, pad(h12)).replace(/\bh\b/g, String(h12))
        .replace(/mm/g, pad(d.getMinutes())).replace(/ss/g, pad(d.getSeconds()))
        .replace(/\ba\b/g, d.getHours() < 12 ? 'AM' : 'PM').replace(/\bz\b/g, 'ET');
    }
    date(s) { return new Date(s); }
  }
  const Keychain = { contains: () => false, get: () => '', set() {}, remove() {} };
  const Timer = { schedule: (ms, rep, fn) => setTimeout(fn, 0) };
  const Notification = class { schedule() {} };
  const log = m => env.logs.push(String(m));
  const consoleMock = { log, warn: log, error: log };
  return { env, globals: { Color, Font, Point, Size, Rect, Path, Image, Data, DrawContext, ListWidget, WidgetStack, WidgetText, WidgetDate, WidgetImage,
    LinearGradient, FileManager, Request, Device, Script, args, config, Location, CalendarEvent, Reminder, Calendar, Alert, Photos, Pasteboard,
    Safari, DateFormatter, Keychain, Timer, Notification, log, console: consoleMock, importModule: () => ({}), module: { exports: {} } } };
}
