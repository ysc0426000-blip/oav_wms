// 驗証準則自動測試：對照使用者提供的過帳機制與每日餘額公式
const BASE = 'http://localhost:3000/api';

async function post(table, values) {
  const r = await fetch(`${BASE}/data/${encodeURIComponent(table)}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ values }),
  });
  const text = await r.text();
  if (!r.ok) console.log('POST', table, 'FAILED', r.status, text);
  return text;
}

async function get(table, filters = {}) {
  const qs = new URLSearchParams(filters).toString();
  const r = await fetch(`${BASE}/data/${encodeURIComponent(table)}${qs ? '?' + qs : ''}`);
  const json = await r.json();
  if (!r.ok) console.log('GET', table, 'FAILED', json);
  return json;
}

async function proc(name, params = {}) {
  const qs = new URLSearchParams(params).toString();
  const r = await fetch(`${BASE}/proc/${encodeURIComponent(name)}${qs ? '?' + qs : ''}`);
  const json = await r.json();
  if (!r.ok) console.log('PROC', name, 'FAILED', json);
  return json;
}

(async () => {
  await post('銷售組織維護', { 銷售組織: 'S01', 備註說明: '台北業務組' });
  await post('客戶資料維護', { 客戶編號: 'C001', 備註說明: '測試客戶' });
  await post('採購組織維護', { 採購組織: 'P01', 備註說明: '採購一組' });
  await post('廠商資料維護', { 廠商編號: 'V001', 備註說明: '測試廠商' });
  await post('工廠代碼維護', { 工廠代碼: 'F01', 備註說明: '總廠' });
  await post('工廠倉庫維護', { 工廠代碼: 'F01', 倉庫代碼: 'W01', 備註說明: '成品倉' });
  await post('物料資料維護', { 物料編號: 'M001', 備註說明: '測試物料' });
  await post('物管資料維護', { 物管編號: 'MG01', 備註說明: '測試物管' });

  await post('客戶訂單主檔', { 訂單編號: 'SO001', 訂單日期: '2026-09-30', 銷售組織: 'S01', 客戶編號: 'C001' });
  await post('客戶訂單明細', { 訂單編號: 'SO001', 訂單項次: '0001', 物料編號: 'M001', 訂單數量: 100, 預定交期: '2026-10-15' });

  await post('訂單出貨主檔', { 出貨編號: 'DN001', 出貨日期: '2026-09-30', 銷售組織: 'S01', 客戶編號: 'C001' });
  await post('訂單出貨明細', { 出貨編號: 'DN001', 出貨項次: '0001', 訂單編號: 'SO001', 訂單項次: '0001', 物料編號: 'M001', 倉庫代碼: 'W01', 出貨數量: 40 });

  await post('出貨退回主檔', { 退回編號: 'RN001', 退回日期: '2026-09-30', 銷售組織: 'S01', 客戶編號: 'C001' });
  await post('出貨退回明細', { 退回編號: 'RN001', 退回項次: '0001', 訂單編號: 'SO001', 訂單項次: '0001', 物料編號: 'M001', 倉庫代碼: 'W01', 退回數量: 5 });

  console.log('== 客戶訂單明細 (出貨數量應=40, 退回數量應=5) ==');
  console.log((await get('客戶訂單明細', { 訂單編號: 'SO001' })).rows);

  await post('廠商採購主檔', { 採購編號: 'PO001', 採購日期: '2026-09-30', 採購組織: 'P01', 廠商編號: 'V001' });
  await post('廠商採購明細', { 採購編號: 'PO001', 採購項次: '0001', 物料編號: 'M001', 採購數量: 200, 預定交期: '2026-10-20' });
  await post('採購收貨主檔', { 收貨編號: 'GR001', 收貨日期: '2026-09-30', 採購組織: 'P01', 廠商編號: 'V001' });
  await post('採購收貨明細', { 收貨編號: 'GR001', 收貨項次: '0001', 採購編號: 'PO001', 採購項次: '0001', 物料編號: 'M001', 倉庫代碼: 'W01', 收貨數量: 80 });

  console.log('== 廠商採購明細 (收貨數量應=80) ==');
  console.log((await get('廠商採購明細', { 採購編號: 'PO001' })).rows);

  await post('生產工單主檔', { 工單編號: 'WO001', 工單日期: '2026-09-30', 工廠代碼: 'F01', 預定完工: '2026-10-05', 生產數量: 50, 物管編號: 'MG01' });
  await post('生產工單明細', { 工單編號: 'WO001', 工單項次: '0001', 物料編號: 'M001', 應領用量: 200, 預定領料: '2026-09-29' });
  await post('工單領料主檔', { 領料編號: 'MI001', 領料日期: '2026-09-30', 工廠代碼: 'F01', 物管編號: 'MG01' });
  await post('工單領料明細', { 領料編號: 'MI001', 領料項次: '0001', 工單編號: 'WO001', 物料編號: 'M001', 倉庫代碼: 'W01', 領料數量: 60 });

  console.log('== 生產工單明細 (已領用量應=60) ==');
  console.log((await get('生產工單明細', { 工單編號: 'WO001' })).rows);

  await post('工單入庫主檔', { 入庫編號: 'FI001', 入庫日期: '2026-10-01', 工廠代碼: 'F01', 物管編號: 'MG01' });
  await post('工單入庫明細', { 入庫編號: 'FI001', 入庫項次: '0001', 工單編號: 'WO001', 物料編號: 'MG01', 倉庫代碼: 'W01', 入庫數量: 30 });

  console.log('== 生產工單主檔 (入庫數量應=30) ==');
  console.log((await get('生產工單主檔', { 工單編號: 'WO001' })).rows);

  console.log('== 已訂未出明細 ==');
  console.log((await get('已訂未出明細', { 訂單編號: 'SO001' })).rows);

  console.log('== 訂單出退分析樞紐 2026 ==');
  console.log((await proc('usp_訂單出退分析樞紐', { 年度: 2026 })).rows);

  console.log('== 採購收退分析樞紐 2026 ==');
  console.log((await proc('usp_採購收退分析樞紐', { 年度: 2026 })).rows);

  console.log('== 每日庫存餘額 (期初+入-出=期末 應自動成立) ==');
  console.log((await get('每日庫存餘額', { 物料編號: 'M001' })).rows);

  console.log('== 每日供需餘額 (在手+供給-需求=可用 應自動成立) ==');
  console.log((await get('每日供需餘額', { 物料編號: 'M001' })).rows);
})();
