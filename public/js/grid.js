/* 通用資料表格 / 主檔明細元件。
   欄位、主鍵、外鍵下拉選單全部由 SQL Server metadata 驅動，
   沒有任何一張畫面是為特定資料表手刻的。 */
window.Grid = (function () {

  function fmtCell(v) {
    if (v === null || v === undefined) return '';
    if (typeof v === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(v)) return v.substring(0, 10);
    return String(v);
  }

  function dateInputValue(v) {
    if (!v) return '';
    return String(v).substring(0, 10);
  }

  function findParentRelation(table, columnName) {
    return null; // set by caller via meta.relations lookup helper below
  }

  function relationFor(meta, tableName, columnName) {
    return meta.relations.find(r => r.childTable === tableName && r.columns.some(c => c.child === columnName));
  }

  async function loadParentOptions(meta, relation) {
    // 單欄位外鍵時，把父表所有資料抓回來當下拉選單（父表通常是小型主檔，量不大）
    if (relation.columns.length !== 1) return null;
    const parentCol = relation.columns[0].parent;
    try {
      const res = await api.get(`/api/data/${encodeURIComponent(relation.parentTable)}?top=1000`);
      return res.rows.map(r => ({ value: r[parentCol], label: r[parentCol] + (r['備註說明'] ? ' - ' + r['備註說明'] : '') }));
    } catch (e) {
      return null;
    }
  }

  function columnInputType(col) {
    const t = col.type.toLowerCase();
    if (t === 'date') return 'date';
    if (t === 'int') return 'number';
    return 'text';
  }

  // 建立表單（新增/編輯共用）。excludeCols: 不顯示的欄位（例如明細中已由主檔帶入的關聯鍵）
  async function openForm({ title, table, meta, initial, isEdit = !!initial, excludeCols = [], lockedCols = {}, onSubmit }) {
    const overlay = document.createElement('div');
    overlay.className = 'form-overlay';
    const sheet = document.createElement('div');
    sheet.className = 'form-sheet';
    sheet.innerHTML = `<h3>${title}</h3>`;
    overlay.appendChild(sheet);
    document.body.appendChild(overlay);

    const fieldEls = {};
    for (const col of table.columns) {
      if (col.identity || col.systemMaintained || excludeCols.includes(col.name)) continue;
      const field = document.createElement('div');
      field.className = 'field';
      const label = document.createElement('label');
      label.textContent = col.name + (table.primaryKey.includes(col.name) ? ' (主鍵)' : '');
      field.appendChild(label);

      const relation = relationFor(meta, table.name, col.name);
      let input;
      if (relation) {
        input = document.createElement('select');
        input.innerHTML = '<option value="">請選擇...</option>';
        loadParentOptions(meta, relation).then((opts) => {
          if (!opts) return;
          opts.forEach((o) => {
            const opt = document.createElement('option');
            opt.value = o.value;
            opt.textContent = o.label;
            if (initial && initial[col.name] === o.value) opt.selected = true;
            input.appendChild(opt);
          });
        });
      } else {
        input = document.createElement('input');
        input.type = columnInputType(col);
        if (col.maxLength > 0 && input.type === 'text') input.maxLength = Math.floor(col.maxLength / 2);
        if (initial && initial[col.name] !== undefined) {
          input.value = input.type === 'date' ? dateInputValue(initial[col.name]) : fmtCell(initial[col.name]);
        }
      }
      if (Object.prototype.hasOwnProperty.call(lockedCols, col.name)) {
        input.value = lockedCols[col.name];
        input.disabled = true;
      }
      if (table.primaryKey.includes(col.name) && isEdit) {
        input.disabled = true; // 編輯時鍵值不可改
      }
      field.appendChild(input);
      fieldEls[col.name] = input;
      sheet.appendChild(field);
    }

    const actions = document.createElement('div');
    actions.className = 'form-actions';
    const cancelBtn = document.createElement('button');
    cancelBtn.className = 'secondary';
    cancelBtn.textContent = '取消';
    cancelBtn.onclick = () => overlay.remove();
    const saveBtn = document.createElement('button');
    saveBtn.className = 'primary';
    saveBtn.textContent = '儲存';
    saveBtn.onclick = async () => {
      const values = {};
      for (const [name, el] of Object.entries(fieldEls)) {
        if (el.disabled && !Object.prototype.hasOwnProperty.call(lockedCols, name)) continue;
        values[name] = el.value === '' ? null : el.value;
      }
      Object.assign(values, lockedCols);
      saveBtn.disabled = true;
      try {
        await onSubmit(values);
        overlay.remove();
      } catch (err) {
        alert('儲存失敗：' + err.message);
        saveBtn.disabled = false;
      }
    };
    actions.appendChild(cancelBtn);
    actions.appendChild(saveBtn);
    sheet.appendChild(actions);
  }

  function renderTable(container, table, rows, { onRowClick, onEdit, onDelete } = {}) {
    const wrap = document.createElement('div');
    wrap.className = 'grid-wrap';
    if (!rows.length) {
      wrap.innerHTML = '<div class="empty">目前沒有資料</div>';
      container.appendChild(wrap);
      return wrap;
    }
    const cols = table.columns.map(c => c.name);
    const t = document.createElement('table');
    t.className = 'grid';
    const thead = document.createElement('thead');
    const trh = document.createElement('tr');
    cols.forEach((c) => {
      const th = document.createElement('th');
      const colMeta = table.columns.find((x) => x.name === c);
      th.textContent = colMeta && colMeta.systemMaintained ? c + '（系統）' : c;
      trh.appendChild(th);
    });
    if (onEdit || onDelete) { const th = document.createElement('th'); th.textContent = '操作'; trh.appendChild(th); }
    thead.appendChild(trh);
    t.appendChild(thead);
    const tbody = document.createElement('tbody');
    rows.forEach((row) => {
      const tr = document.createElement('tr');
      if (onRowClick) { tr.style.cursor = 'pointer'; tr.addEventListener('click', () => onRowClick(row, tr)); }
      cols.forEach((c) => { const td = document.createElement('td'); td.textContent = fmtCell(row[c]); tr.appendChild(td); });
      if (onEdit || onDelete) {
        const td = document.createElement('td');
        if (onEdit) {
          const b = document.createElement('button');
          b.className = 'secondary'; b.textContent = '編輯'; b.style.marginRight = '6px';
          b.onclick = (e) => { e.stopPropagation(); onEdit(row); };
          td.appendChild(b);
        }
        if (onDelete) {
          const b = document.createElement('button');
          b.className = 'danger'; b.textContent = '刪除';
          b.onclick = (e) => { e.stopPropagation(); onDelete(row); };
          td.appendChild(b);
        }
        tr.appendChild(td);
      }
      tbody.appendChild(tr);
    });
    t.appendChild(tbody);
    wrap.appendChild(t);
    container.appendChild(wrap);
    return wrap;
  }

  function keysOf(table, row) {
    const keys = {};
    table.primaryKey.forEach(k => keys[k] = row[k]);
    return keys;
  }

  async function renderLookup(container, tableName, meta) {
    const table = meta.tables[tableName];
    if (!table) { container.innerHTML = `<div class="empty">找不到資料表 ${tableName}</div>`; return; }

    const toolbar = document.createElement('div');
    toolbar.className = 'toolbar';
    const addBtn = document.createElement('button');
    addBtn.className = 'primary';
    addBtn.textContent = '新增';
    toolbar.appendChild(addBtn);
    container.appendChild(toolbar);

    const listHolder = document.createElement('div');
    container.appendChild(listHolder);

    async function reload() {
      listHolder.innerHTML = '<div class="empty">載入中...</div>';
      const res = await api.get(`/api/data/${encodeURIComponent(tableName)}`);
      listHolder.innerHTML = '';
      renderTable(listHolder, table, res.rows, {
        onEdit: (row) => openForm({
          title: `編輯 - ${tableName}`, table, meta, initial: row,
          onSubmit: async (values) => { await api.put(`/api/data/${encodeURIComponent(tableName)}`, { keys: keysOf(table, row), values }); await reload(); },
        }),
        onDelete: async (row) => {
          if (!confirm('確定要刪除這筆資料嗎？')) return;
          await api.del(`/api/data/${encodeURIComponent(tableName)}`, { keys: keysOf(table, row) });
          await reload();
        },
      });
    }

    addBtn.onclick = () => openForm({
      title: `新增 - ${tableName}`, table, meta, initial: null,
      onSubmit: async (values) => { await api.post(`/api/data/${encodeURIComponent(tableName)}`, { values }); await reload(); },
    });

    await reload();
  }

  async function renderReport(container, viewName, meta) {
    const view = meta.views[viewName];
    if (!view) { container.innerHTML = `<div class="empty">找不到檢視 ${viewName}</div>`; return; }
    container.innerHTML = '<div class="empty">載入中...</div>';
    const res = await api.get(`/api/data/${encodeURIComponent(viewName)}?top=1000`);
    container.innerHTML = '';
    const hint = document.createElement('div');
    hint.className = 'hint';
    hint.textContent = '此為報表檢視（唯讀），資料由 SQL Server 檢視即時運算產生。';
    container.appendChild(hint);
    const pseudoTable = { name: viewName, columns: view.columns, primaryKey: [] };
    renderTable(container, pseudoTable, res.rows);
  }

  function nextItemNo(existingRows, itemCol) {
    let max = 0;
    existingRows.forEach(r => { const n = parseInt(r[itemCol], 10); if (!isNaN(n) && n > max) max = n; });
    return String(max + 1).padStart(4, '0');
  }

  async function renderDoc(container, headerTableName, detailTableName, meta) {
    const headerTable = meta.tables[headerTableName];
    const detailTable = meta.tables[detailTableName];
    if (!headerTable || !detailTable) { container.innerHTML = '<div class="empty">找不到主檔/明細資料表定義</div>'; return; }

    const relation = meta.relations.find(r => r.childTable === detailTableName && r.parentTable === headerTableName);
    if (!relation) { container.innerHTML = '<div class="empty">找不到主檔/明細的關聯定義</div>'; return; }

    const headerCard = document.createElement('div');
    headerCard.className = 'card';
    const headerToolbar = document.createElement('div');
    headerToolbar.className = 'toolbar';
    const addHeaderBtn = document.createElement('button');
    addHeaderBtn.className = 'primary';
    addHeaderBtn.textContent = '新增單頭';
    headerToolbar.appendChild(addHeaderBtn);
    headerCard.appendChild(headerToolbar);
    const headerListHolder = document.createElement('div');
    headerCard.appendChild(headerListHolder);
    container.appendChild(headerCard);

    const detailCard = document.createElement('div');
    detailCard.className = 'card';
    detailCard.innerHTML = '<div class="hint">請先在上方選擇一筆單頭，即可維護其明細</div>';
    container.appendChild(detailCard);

    let selectedHeaderRow = null;

    async function reloadHeader() {
      headerListHolder.innerHTML = '<div class="empty">載入中...</div>';
      const res = await api.get(`/api/data/${encodeURIComponent(headerTableName)}`);
      headerListHolder.innerHTML = '';
      renderTable(headerListHolder, headerTable, res.rows, {
        onRowClick: (row) => { selectedHeaderRow = row; reloadDetail(); },
        onEdit: (row) => openForm({
          title: `編輯 - ${headerTableName}`, table: headerTable, meta, initial: row,
          onSubmit: async (values) => { await api.put(`/api/data/${encodeURIComponent(headerTableName)}`, { keys: keysOf(headerTable, row), values }); await reloadHeader(); },
        }),
        onDelete: async (row) => {
          if (!confirm('確定要刪除此單頭嗎？（請先確認明細已清空）')) return;
          await api.del(`/api/data/${encodeURIComponent(headerTableName)}`, { keys: keysOf(headerTable, row) });
          if (selectedHeaderRow && relation.columns.every(c => selectedHeaderRow[c.parent] === row[c.parent])) {
            selectedHeaderRow = null;
            detailCard.innerHTML = '<div class="hint">請先在上方選擇一筆單頭，即可維護其明細</div>';
          }
          await reloadHeader();
        },
      });
    }

    addHeaderBtn.onclick = () => openForm({
      title: `新增 - ${headerTableName}`, table: headerTable, meta, initial: null,
      onSubmit: async (values) => { await api.post(`/api/data/${encodeURIComponent(headerTableName)}`, { values }); await reloadHeader(); },
    });

    async function reloadDetail() {
      detailCard.innerHTML = '';
      const title = document.createElement('div');
      title.className = 'section-title';
      title.textContent = `明細 - ${detailTableName}（單頭：${relation.columns.map(c => selectedHeaderRow[c.parent]).join(' / ')}）`;
      detailCard.appendChild(title);

      const toolbar = document.createElement('div');
      toolbar.className = 'toolbar';
      const addBtn = document.createElement('button');
      addBtn.className = 'primary';
      addBtn.textContent = '新增明細';
      toolbar.appendChild(addBtn);
      detailCard.appendChild(toolbar);

      const holder = document.createElement('div');
      detailCard.appendChild(holder);

      const qs = relation.columns.map(c => `${encodeURIComponent(c.child)}=${encodeURIComponent(selectedHeaderRow[c.parent])}`).join('&');

      async function reload() {
        holder.innerHTML = '<div class="empty">載入中...</div>';
        const res = await api.get(`/api/data/${encodeURIComponent(detailTableName)}?${qs}`);
        holder.innerHTML = '';
        renderTable(holder, detailTable, res.rows, {
          onEdit: (row) => openForm({
            title: `編輯 - ${detailTableName}`, table: detailTable, meta, initial: row,
            lockedCols: Object.fromEntries(relation.columns.map(c => [c.child, selectedHeaderRow[c.parent]])),
            onSubmit: async (values) => { await api.put(`/api/data/${encodeURIComponent(detailTableName)}`, { keys: keysOf(detailTable, row), values }); await reload(); },
          }),
          onDelete: async (row) => {
            if (!confirm('確定要刪除這筆明細嗎？')) return;
            await api.del(`/api/data/${encodeURIComponent(detailTableName)}`, { keys: keysOf(detailTable, row) });
            await reload();
          },
        });
      }

      addBtn.onclick = async () => {
        const currentRes = await api.get(`/api/data/${encodeURIComponent(detailTableName)}?${qs}`);
        const itemCol = detailTable.primaryKey.find(k => !relation.columns.some(c => c.child === k));
        const initial = itemCol ? { [itemCol]: nextItemNo(currentRes.rows, itemCol) } : null;
        openForm({
          title: `新增明細 - ${detailTableName}`, table: detailTable, meta, initial, isEdit: false,
          lockedCols: Object.fromEntries(relation.columns.map(c => [c.child, selectedHeaderRow[c.parent]])),
          onSubmit: async (values) => { await api.post(`/api/data/${encodeURIComponent(detailTableName)}`, { values }); await reload(); },
        });
      };

      await reload();
    }

    await reloadHeader();
  }

  function renderRawTable(container, rows) {
    if (!rows.length) { container.innerHTML = '<div class="empty">目前沒有資料</div>'; return; }
    const cols = Object.keys(rows[0]);
    const wrap = document.createElement('div');
    wrap.className = 'grid-wrap';
    const t = document.createElement('table');
    t.className = 'grid';
    const thead = document.createElement('thead');
    const trh = document.createElement('tr');
    cols.forEach(c => { const th = document.createElement('th'); th.textContent = c; trh.appendChild(th); });
    thead.appendChild(trh);
    t.appendChild(thead);
    const tbody = document.createElement('tbody');
    rows.forEach((row) => {
      const tr = document.createElement('tr');
      cols.forEach((c) => { const td = document.createElement('td'); td.textContent = fmtCell(row[c]); tr.appendChild(td); });
      tbody.appendChild(tr);
    });
    t.appendChild(tbody);
    wrap.appendChild(t);
    container.appendChild(wrap);
  }

  // 樞紐分析：欄位/參數完全由 sys.procedures + sys.parameters 產生，前端不寫死任何報表邏輯
  async function renderPivot(container, procName, meta) {
    const proc = meta.procs && meta.procs[procName];
    if (!proc) { container.innerHTML = `<div class="empty">找不到報表程序 ${procName}</div>`; return; }

    const toolbar = document.createElement('div');
    toolbar.className = 'toolbar';
    const inputs = {};
    proc.params.forEach((p) => {
      const input = document.createElement('input');
      input.type = p.type.toLowerCase() === 'int' ? 'number' : (p.type.toLowerCase() === 'date' ? 'date' : 'text');
      input.placeholder = p.name;
      if (input.type === 'number') input.value = new Date().getFullYear();
      inputs[p.name] = input;
      toolbar.appendChild(input);
    });
    const runBtn = document.createElement('button');
    runBtn.className = 'primary';
    runBtn.textContent = '查詢';
    toolbar.appendChild(runBtn);
    container.appendChild(toolbar);

    const holder = document.createElement('div');
    container.appendChild(holder);

    runBtn.onclick = async () => {
      holder.innerHTML = '<div class="empty">載入中...</div>';
      const qs = new URLSearchParams(Object.fromEntries(Object.entries(inputs).map(([k, el]) => [k, el.value]))).toString();
      try {
        const res = await api.get(`/api/proc/${encodeURIComponent(procName)}?${qs}`);
        holder.innerHTML = '';
        renderRawTable(holder, res.rows);
      } catch (err) {
        holder.innerHTML = `<div class="empty">查詢失敗：${err.message}</div>`;
      }
    };

    if (proc.params.length) runBtn.onclick();
  }

  return { renderLookup, renderDoc, renderReport, renderPivot };
})();
