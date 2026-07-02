import { createReadStream, existsSync } from 'node:fs';
import { mkdir, readdir, stat, appendFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import readline from 'node:readline/promises';
import { createRequire } from 'node:module';
import { stdin as input, stdout as output } from 'node:process';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const API_BASE = 'https://api.appmaq.com.br';
const APP_URL = 'https://appmaq.com.br/admin/maquinas/manuais';
const ROOT = 'E:\\MANUAIS_APPMAQ\\Trator Agricola\\VALTRA 3';
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const PROFILE = path.resolve('tmp', 'chrome-appmaq-upload');
const REPORT = path.resolve(
  'Inventario_APPMAQ',
  'Lotes_Usuario',
  `upload_appmaq_valtra3_api_${new Date().toISOString().slice(0, 10)}.csv`,
);

const TYPE_NAME = 'Trator Agrícola';
const BRAND_NAME = 'VALTRA';

const ALL_MODELS = [
  'A800P',
  'A800R',
  'A850',
  'A850C',
  'A850F',
  'A850R',
  'A950',
  'A950C',
  'A950R',
  'A990',
  'A990C',
  'A990R',
  'BM115',
  'BM115C',
  'BM135',
  'BM135C',
  'BT170',
  'BT190',
  'BT210',
];

function csv(value) {
  return `"${String(value ?? '').replaceAll('"', '""')}"`;
}

async function ensureReport() {
  await mkdir(path.dirname(REPORT), { recursive: true });
  if (!existsSync(REPORT)) {
    await writeFile(
      REPORT,
      [
        'data_hora',
        'modelo',
        'modelo_id',
        'arquivos',
        'status',
        'ok',
        'mensagem',
      ].map(csv).join(',') + '\n',
      'utf8',
    );
  }
}

async function writeReport(row) {
  await appendFile(
    REPORT,
    [
      new Date().toISOString(),
      row.modelo,
      row.modelo_id,
      row.arquivos,
      row.status,
      row.ok,
      row.mensagem,
    ].map(csv).join(',') + '\n',
    'utf8',
  );
}

async function getJson(url, token) {
  const headers = { accept: 'application/json' };
  if (token) headers.authorization = `Bearer ${token}`;
  const res = await fetch(url, { headers });
  const text = await res.text();
  if (!res.ok) throw new Error(`${res.status} ${text.slice(0, 250)}`);
  return text ? JSON.parse(text) : null;
}

async function discoverIds(token) {
  const types = await getJson(`${API_BASE}/vehicles/public/types/actives-with-children/?destination=2`, token);
  const type = types.find((item) => item.slug === 'trator-agricola' || item.description === TYPE_NAME);
  if (!type) throw new Error(`Tipo nao encontrado: ${TYPE_NAME}`);

  const brands = await getJson(`${API_BASE}/vehicles/public/brands/types/${type.id}/actives-with-children?destination=1`, token);
  const brand = brands.find((item) => String(item.name).toUpperCase() === BRAND_NAME);
  if (!brand) throw new Error(`Marca nao encontrada: ${BRAND_NAME}`);

  const models = await getJson(`${API_BASE}/vehicles/public/models/types/${type.id}/brands/${brand.id}/actives-with-children?destination=1`, token);
  const modelMap = new Map(models.map((item) => [String(item.model).toUpperCase(), item]));

  return { type, brand, modelMap };
}

async function pdfsForModel(model) {
  const dir = path.join(ROOT, model);
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.toLowerCase().endsWith('.pdf')) continue;
    const fullPath = path.join(dir, entry.name);
    const info = await stat(fullPath);
    if (info.size > 0) files.push(fullPath);
  }
  files.sort((a, b) => path.basename(a).localeCompare(path.basename(b), 'pt-BR'));
  return files;
}

async function uploadBatch({ token, typeId, brandId, modelId, files }) {
  const form = new FormData();
  form.append('vehicleTypeId', typeId);
  form.append('vehicleBrandId', brandId);
  form.append('vehicleModelId', modelId);

  for (const file of files) {
    const name = path.basename(file, path.extname(file));
    const blob = await new Response(createReadStream(file)).blob();
    form.append('files', blob, path.basename(file));
    form.append('names', name);
    form.append('descriptions', '');
  }

  const res = await fetch(`${API_BASE}/vehicles/manuals/batch`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}` },
    body: form,
  });
  const text = await res.text();
  return { status: res.status, ok: res.ok, text: text.slice(0, 500) };
}

function parseArgs() {
  const args = process.argv.slice(2);
  const one = args.find((arg) => arg.startsWith('--model='));
  const from = args.find((arg) => arg.startsWith('--from='));
  const dryRun = args.includes('--dry-run');
  let models = [...ALL_MODELS];
  if (one) models = [one.split('=').slice(1).join('=').trim().toUpperCase()];
  if (from) {
    const start = from.split('=').slice(1).join('=').trim().toUpperCase();
    const idx = models.indexOf(start);
    if (idx >= 0) models = models.slice(idx);
  }
  return { models, dryRun };
}

async function main() {
  const { models, dryRun } = parseArgs();
  await ensureReport();

  if (dryRun) {
    for (const model of models) {
      const files = await pdfsForModel(model);
      console.log(`[${model}] ${files.length} PDF(s)`);
      for (const file of files) console.log(`  - ${path.basename(file)}`);
      await writeReport({ modelo: model, modelo_id: '', arquivos: files.length, status: 'DRY', ok: true, mensagem: files.map((f) => path.basename(f)).join(' | ') });
    }
    console.log(`Relatorio: ${REPORT}`);
    return;
  }

  if (!existsSync(CHROME)) {
    throw new Error(`Chrome nao encontrado em ${CHROME}`);
  }

  const context = await chromium.launchPersistentContext(PROFILE, {
    executablePath: CHROME,
    headless: false,
    viewport: { width: 1366, height: 900 },
  });

  const page = context.pages()[0] ?? await context.newPage();
  await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

  const rl = readline.createInterface({ input, output });
  console.log('Chrome aberto. Se aparecer login, entre no AppMaq nessa janela.');
  await rl.question('Quando a pagina admin de manuais estiver logada, pressione Enter aqui para continuar...');

  const cookies = await context.cookies(['https://appmaq.com.br']);
  const tokenCookie = cookies.find((cookie) => cookie.name === 'user_app_maq');
  if (!tokenCookie?.value) {
    throw new Error('Nao encontrei o cookie user_app_maq depois do login. Nao foi feito upload.');
  }
  const token = tokenCookie.value;

  const { type, brand, modelMap } = await discoverIds(token);
  console.log(`Tipo: ${type.description} (${type.id})`);
  console.log(`Marca: ${brand.name} (${brand.id})`);
  console.log(`Relatorio: ${REPORT}`);

  for (const model of models) {
    const item = modelMap.get(model.toUpperCase());
    if (!item) {
      console.log(`[${model}] modelo nao encontrado no AppMaq.`);
      await writeReport({ modelo: model, modelo_id: '', arquivos: 0, status: 'NA', ok: false, mensagem: 'modelo nao encontrado' });
      continue;
    }

    const files = await pdfsForModel(model);
    if (files.length === 0) {
      console.log(`[${model}] sem PDFs na pasta.`);
      await writeReport({ modelo: model, modelo_id: item.id, arquivos: 0, status: 'NA', ok: false, mensagem: 'sem PDFs na pasta' });
      continue;
    }

    console.log(`[${model}] ${files.length} PDF(s) -> upload`);

    const result = await uploadBatch({
      token,
      typeId: type.id,
      brandId: brand.id,
      modelId: item.id,
      files,
    });
    console.log(`[${model}] status ${result.status} ${result.ok ? 'OK' : 'FALHOU'}`);
    await writeReport({
      modelo: model,
      modelo_id: item.id,
      arquivos: files.length,
      status: result.status,
      ok: result.ok,
      mensagem: result.text,
    });

    if (!result.ok) {
      throw new Error(`Upload falhou em ${model}: ${result.status} ${result.text}`);
    }
  }

  await rl.close();
  console.log('Concluido.');
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
