import cors from 'cors';
import express from 'express';
import fs from 'fs/promises';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createClient } from '@supabase/supabase-js';
import axios from 'axios';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.join(__dirname, '..');

function loadDotEnv() {
  try {
    const raw = readFileSync(path.join(serverRoot, '.env'), 'utf8');
    for (const line of raw.split(/\r?\n/)) {
      const t = line.trim();
      if (!t || t.startsWith('#')) continue;
      const i = t.indexOf('=');
      if (i <= 0) continue;
      const k = t.slice(0, i).trim();
      let v = t.slice(i + 1).trim();
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1);
      }
      if (!process.env[k]) process.env[k] = v;
    }
  } catch {
    /* no .env */
  }
}

loadDotEnv();

const PORT = Number(process.env.PORT || 8787);
const ADMIN_TOKEN = (process.env.ADMIN_TOKEN || '').trim();

// Supabase configuration for token verification
const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || '';
const supabase = (SUPABASE_URL && SUPABASE_ANON_KEY) 
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;
const DATA_DIR = path.isAbsolute(process.env.DATA_DIR || '')
  ? process.env.DATA_DIR
  : path.join(serverRoot, process.env.DATA_DIR || 'data');

const MODULE_ID_RE = /^[a-z][a-z0-9_]{0,63}$/;
const ITEM_ID_RE = /^[a-z0-9_]{1,64}$/;

function catalogPath(lang) {
  return path.join(DATA_DIR, `catalog.${lang}.json`);
}

function itemsPath(lang, moduleId) {
  return path.join(DATA_DIR, 'items', lang, `${moduleId}.json`);
}

async function readJsonFile(filePath, fallback) {
  try {
    const raw = await fs.readFile(filePath, 'utf8');
    return JSON.parse(raw);
  } catch {
    return fallback;
  }
}

async function writeJsonAtomic(filePath, data) {
  const dir = path.dirname(filePath);
  await fs.mkdir(dir, { recursive: true });
  const tmp = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  await fs.writeFile(tmp, JSON.stringify(data, null, 2), 'utf8');
  await fs.rename(tmp, filePath);
}

async function readCatalog(lang) {
  let c = await readJsonFile(catalogPath(lang), null);
  if (!Array.isArray(c) || c.length === 0) {
    c = await readJsonFile(catalogPath('tr'), []);
  }
  return Array.isArray(c) ? c : [];
}

async function readItems(lang, moduleId) {
  let items = await readJsonFile(itemsPath(lang, moduleId), null);
  if (!Array.isArray(items) && lang !== 'tr') {
    items = await readJsonFile(itemsPath('tr', moduleId), []);
  }
  if (!Array.isArray(items)) return [];
  return items;
}

function normalizeItemsPayload(body) {
  if (Array.isArray(body)) return body;
  if (body && typeof body === 'object' && Array.isArray(body.items)) return body.items;
  return null;
}

function validateItem(it, strictId) {
  if (!it || typeof it !== 'object') return 'Invalid item';
  const id = String(it.id ?? '').trim();
  const title = String(it.title ?? '').trim();
  const content = String(it.content ?? '').trim();
  if (!ITEM_ID_RE.test(id)) return 'Invalid id';
  if (!title) return 'title required';
  if (!content) return 'content required';
  if (strictId && id !== strictId) return 'id mismatch';
  return {
    id,
    title,
    content,
    benefit: String(it.benefit ?? '').trim(),
  };
}

function validateItemLoose(it) {
  const r = validateItem(it, null);
  if (typeof r === 'string') return r;
  return r;
}

function adminAuth(req, res, next) {
  if (!ADMIN_TOKEN) {
    res.status(503).json({ error: 'ADMIN_TOKEN is not configured' });
    return;
  }
  const h = req.headers.authorization || '';
  const bearer = h.startsWith('Bearer ') ? h.slice(7).trim() : '';
  const headerToken = (req.headers['x-admin-token'] || '').toString().trim();
  const token = bearer || headerToken;
  if (token !== ADMIN_TOKEN) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  next();
}

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/knowledge/modules', async (req, res) => {
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const catalog = await readCatalog(lang);
  res.json(catalog);
});

app.get('/knowledge/:moduleId', async (req, res) => {
  const { moduleId } = req.params;
  if (moduleId === 'modules') {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  if (!MODULE_ID_RE.test(moduleId)) {
    res.status(400).json({ error: 'Invalid moduleId' });
    return;
  }
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const items = await readItems(lang, moduleId);
  res.json(items);
});

app.get('/admin/knowledge/modules', adminAuth, async (req, res) => {
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const catalog = await readCatalog(lang);
  const enriched = await Promise.all(
    catalog.map(async (m) => {
      const items = await readItems(lang, m.id);
      return { ...m, itemCount: items.length };
    }),
  );
  res.json(enriched);
});

app.get('/admin/knowledge/:moduleId', adminAuth, async (req, res) => {
  const { moduleId } = req.params;
  if (!MODULE_ID_RE.test(moduleId)) {
    res.status(400).json({ error: 'Invalid moduleId' });
    return;
  }
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const items = await readItems(lang, moduleId);
  res.json(items);
});

app.put('/admin/knowledge/:moduleId', adminAuth, async (req, res) => {
  const { moduleId } = req.params;
  if (!MODULE_ID_RE.test(moduleId)) {
    res.status(400).json({ error: 'Invalid moduleId' });
    return;
  }
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const arr = normalizeItemsPayload(req.body);
  if (!arr) {
    res.status(400).json({ error: 'Body must be a JSON array or { items: [] }' });
    return;
  }
  const out = [];
  const seen = new Set();
  for (const raw of arr) {
    const v = validateItemLoose(raw);
    if (typeof v === 'string') {
      res.status(400).json({ error: v });
      return;
    }
    if (seen.has(v.id)) {
      res.status(400).json({ error: `Duplicate id: ${v.id}` });
      return;
    }
    seen.add(v.id);
    out.push(v);
  }
  await writeJsonAtomic(itemsPath(lang, moduleId), out);
  res.json({ ok: true, count: out.length });
});

app.post('/admin/knowledge/:moduleId/items', adminAuth, async (req, res) => {
  const { moduleId } = req.params;
  if (!MODULE_ID_RE.test(moduleId)) {
    res.status(400).json({ error: 'Invalid moduleId' });
    return;
  }
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const v = validateItemLoose(req.body);
  if (typeof v === 'string') {
    res.status(400).json({ error: v });
    return;
  }
  const items = await readItems(lang, moduleId);
  if (items.some((x) => x.id === v.id)) {
    res.status(409).json({ error: 'id already exists' });
    return;
  }
  items.push(v);
  await writeJsonAtomic(itemsPath(lang, moduleId), items);
  res.status(201).json(v);
});

app.put('/admin/knowledge/:moduleId/items/:itemId', adminAuth, async (req, res) => {
  const { moduleId, itemId } = req.params;
  if (!MODULE_ID_RE.test(moduleId) || !ITEM_ID_RE.test(itemId)) {
    res.status(400).json({ error: 'Invalid id' });
    return;
  }
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const v = validateItem({ ...req.body, id: itemId }, itemId);
  if (typeof v === 'string') {
    res.status(400).json({ error: v });
    return;
  }
  const items = await readItems(lang, moduleId);
  const idx = items.findIndex((x) => x.id === itemId);
  if (idx < 0) {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  items[idx] = v;
  await writeJsonAtomic(itemsPath(lang, moduleId), items);
  res.json(v);
});

app.delete('/admin/knowledge/:moduleId/items/:itemId', adminAuth, async (req, res) => {
  const { moduleId, itemId } = req.params;
  if (!MODULE_ID_RE.test(moduleId) || !ITEM_ID_RE.test(itemId)) {
    res.status(400).json({ error: 'Invalid id' });
    return;
  }
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const items = await readItems(lang, moduleId);
  const next = items.filter((x) => x.id !== itemId);
  if (next.length === items.length) {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  await writeJsonAtomic(itemsPath(lang, moduleId), next);
  res.json({ ok: true });
});

app.put('/admin/knowledge/catalog', adminAuth, async (req, res) => {
  const lang = String(req.query.lang || 'tr').slice(0, 8);
  const arr = Array.isArray(req.body) ? req.body : null;
  if (!arr) {
    res.status(400).json({ error: 'Body must be a JSON array' });
    return;
  }
  for (const m of arr) {
    if (!m || typeof m !== 'object') {
      res.status(400).json({ error: 'Invalid catalog entry' });
      return;
    }
    const id = String(m.id ?? '').trim();
    if (!MODULE_ID_RE.test(id)) {
      res.status(400).json({ error: `Invalid module id: ${id}` });
      return;
    }
    if (!String(m.title ?? '').trim()) {
      res.status(400).json({ error: 'title required' });
      return;
    }
  }
  await writeJsonAtomic(
    catalogPath(lang),
    arr.map((m) => ({
      id: String(m.id).trim(),
      title: String(m.title).trim(),
      subtitle: String(m.subtitle ?? '').trim(),
    })),
  );
  res.json({ ok: true, count: arr.length });
});

// Quran API endpoints - proxy to alquran.cloud (like old Python code)
const ALQURAN_BASE = 'https://api.alquran.cloud/v1';

const EDITIONS = {
  'ar': 'quran-uthmani',
  'tr': 'tr.diyanet',
  'en': 'en.asad',
  'de': 'de.aburida',
  'fr': 'fr.hamidullah',
  'ru': 'ru.kuliev',
  'id': 'id.indonesian',
};

// Get all surahs list
app.get('/surah', async (_req, res) => {
  try {
    const response = await axios.get(`${ALQURAN_BASE}/surah`);
    const data = response.data;
    if (data.code !== 200) {
      res.status(500).json({ error: 'Failed to load surahs' });
      return;
    }
    res.json(data);
  } catch (error) {
    console.error('Error fetching surahs:', error.message);
    res.status(500).json({ error: 'Failed to load surahs' });
  }
});

// Get specific surah
app.get('/surah/:id', async (req, res) => {
  try {
    const surahId = parseInt(req.params.id, 10);
    const lang = req.query.lang || 'ar';
    const edition = EDITIONS[lang] || 'quran-uthmani';
    
    const response = await axios.get(`${ALQURAN_BASE}/surah/${surahId}/${edition}`);
    const data = response.data;
    if (data.code !== 200) {
      res.status(500).json({ error: 'Failed to load surah' });
      return;
    }
    res.json(data);
  } catch (error) {
    console.error('Error fetching surah:', error.message);
    res.status(500).json({ error: 'Failed to load surah' });
  }
});

// Get surah translations
app.get('/surah/:id/translations', async (req, res) => {
  try {
    const surahId = parseInt(req.params.id, 10);
    const lang = req.query.lang || 'en';
    const edition = EDITIONS[lang] || 'en.asad';
    
    const response = await axios.get(`${ALQURAN_BASE}/surah/${surahId}/${edition}`);
    const data = response.data;
    if (data.code !== 200) {
      res.status(500).json({ error: 'Failed to load translation' });
      return;
    }
    res.json(data);
  } catch (error) {
    console.error('Error fetching translation:', error.message);
    res.status(500).json({ error: 'Failed to load translation' });
  }
});

// Audio proxy
app.get('/audio/:reciter/:surah/:ayah.mp3', async (req, res) => {
  try {
    const { reciter, surah, ayah } = req.params;
    // Proxy to everyayah.com or similar
    const audioUrl = `https://everyayah.com/data/${reciter}/${surah.toString().padStart(3, '0')}${ayah.toString().padStart(3, '0')}.mp3`;
    
    const response = await axios.get(audioUrl, { 
      responseType: 'stream',
      timeout: 10000 
    });
    
    res.setHeader('Content-Type', 'audio/mpeg');
    response.data.pipe(res);
  } catch (error) {
    console.error('Error fetching audio:', error.message);
    res.status(404).json({ error: 'Audio not found' });
  }
});

// Premium activation endpoint with Supabase token verification
app.post('/api/v1/auth/premium/activate', express.json(), async (req, res) => {
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized - Bearer token required' });
    return;
  }

  const { plan, userId } = req.body;
  if (!plan || !userId) {
    res.status(400).json({ error: 'plan and userId are required' });
    return;
  }

  // Verify Supabase is configured
  if (!supabase) {
    res.status(503).json({ error: 'Supabase not configured on server' });
    return;
  }

  try {
    // Verify the Supabase token
    const token = authHeader.split(' ')[1];
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    // Verify the userId matches the token
    if (user.id !== userId) {
      res.status(403).json({ error: 'User ID mismatch' });
      return;
    }

    // In production: Update user record in database to mark as premium
    // For now, return success response
    res.json({
      message: 'Premium activated successfully',
      is_premium: true,
      plan: plan,
      userId: userId,
      email: user.email,
      activatedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Premium activation error:', error);
    res.status(500).json({ error: 'Internal server error during activation' });
  }
});

app.use(express.static(path.join(serverRoot, 'public')));

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Knowledge API listening on http://0.0.0.0:${PORT}`);
  console.log(`VPS External URL: http://YOUR_VPS_IP:${PORT}`);
  if (!ADMIN_TOKEN) {
    console.warn('ADMIN_TOKEN unset: admin write routes return 503');
  }
});
