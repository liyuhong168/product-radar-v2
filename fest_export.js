function exportData() {
  const blob = new Blob([State.export()], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `uk-festival-backup-${Utils.fmtYMD(new Date())}.json`;
  a.click();
  URL.revokeObjectURL(url);
}
function importData(event) {
  const file = event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    try {
      State.import(e.target.result);
      alert("✅ 导入成功！");
      Render.dashboard(); Render.main();
    } catch (err) { alert("❌ 导入失败：" + err.message); }
  };
  reader.readAsText(file);
  event.target.value = "";
}
function resetAllProgress() {
  if (!confirm("⚠️ 确定清除所有备货进度吗？此操作不可恢复！\n\n建议先点击\"导出备份\"保存当前数据。")) return;
  if (!confirm("再次确认：真的要清除所有进度？")) return;
  State.reset();
  Render.dashboard(); Render.main();
  alert("已清除所有进度。");
}

// ============================================
// GitHub Gist 同步
// ============================================
const SYNC_CONFIG_KEY = "uk_festival_sync_config";

function getSyncConfig() {
  try {
    return JSON.parse(localStorage.getItem(SYNC_CONFIG_KEY)) || {};
  } catch { return {}; }
}
function saveSyncConfig() {
  const token = document.getElementById("syncToken").value.trim();
  const gistId = document.getElementById("syncGistId").value.trim();
  localStorage.setItem(SYNC_CONFIG_KEY, JSON.stringify({ token, gistId }));
  showSyncStatus("✅ 配置已保存", "success");
}
function loadSyncConfig() {
  const cfg = getSyncConfig();
  if (cfg.token) document.getElementById("syncToken").value = cfg.token;
  if (cfg.gistId) document.getElementById("syncGistId").value = cfg.gistId;
}
function showSyncStatus(msg, type) {
  const el = document.getElementById("syncStatus");
  el.className = "sync-status " + type;
  el.textContent = msg;
}

async function gistAPI(method, path, body, token) {
  const resp = await fetch("https://api.github.com" + path, {
    method,
    headers: {
      "Authorization": "Bearer " + token,
      "Accept": "application/vnd.github+json",
      "Content-Type": "application/json"
    },
    body: body ? JSON.stringify(body) : undefined
  });
  if (!resp.ok) {
    const err = await resp.json().catch(() => ({}));
    throw new Error(err.message || "GitHub API 请求失败 (" + resp.status + ")");
  }
  return resp.json();
}

async function syncCreateGist() {
  const token = document.getElementById("syncToken").value.trim();
  if (!token) { showSyncStatus("❌ 请先填入 GitHub Token", "error"); return; }
  showSyncStatus("⏳ 正在创建 Gist...", "info");
  try {
    const data = State.export();
    const result = await gistAPI("POST", "/gists", {
      description: "UK Festival Planner - Team Sync Data",
      public: false,
      files: {
        "uk-festival-data.json": { content: data }
      }
    }, token);
    document.getElementById("syncGistId").value = result.id;
    saveSyncConfig();
    showSyncStatus("✅ Gist 创建成功！ID: " + result.id + "，请把这个 ID 发给你的搭档。", "success");
  } catch (err) {
    showSyncStatus("❌ 创建失败：" + err.message, "error");
  }
}

async function syncPush() {
  const cfg = getSyncConfig();
  if (!cfg.token || !cfg.gistId) { showSyncStatus("❌ 请先配置 Token 和 Gist ID", "error"); return; }
  showSyncStatus("⏳ 正在推送到云端...", "info");
  try {
    const data = State.export();
    await gistAPI("PATCH", "/gists/" + cfg.gistId, {
      files: {
        "uk-festival-data.json": { content: data }
      }
    }, cfg.token);
    const now = new Date().toLocaleString("zh-CN");
    showSyncStatus("✅ 推送成功！" + now, "success");
  } catch (err) {
    showSyncStatus("❌ 推送失败：" + err.message, "error");
  }
}

async function syncPull() {
  const cfg = getSyncConfig();
  if (!cfg.token || !cfg.gistId) { showSyncStatus("❌ 请先配置 Token 和 Gist ID", "error"); return; }
  showSyncStatus("⏳ 正在从云端拉取...", "info");
  try {
    const result = await gistAPI("GET", "/gists/" + cfg.gistId, null, cfg.token);
    const file = result.files["uk-festival-data.json"];
    if (!file) throw new Error("Gist 中未找到数据文件");
    State.import(file.content);
    Render.dashboard(); Render.main();
    const now = new Date().toLocaleString("zh-CN");
    showSyncStatus("✅ 拉取成功！数据已更新。" + now, "success");
  } catch (err) {
    showSyncStatus("❌ 拉取失败：" + err.message, "error");
  }
}

// ============================================
// 导出 Excel（CSV 格式）
// ============================================
function exportExcel() {
  const rows = [["月份","节日","日期","重要性","品类","紧急度","状态","SKU","英文SKU","品类","成本","售价","毛利率","匹配度","风险等级","风险说明","关键词"]];
  FESTIVALS.forEach(f => {
    const urgency = Utils.getUrgency(f);
    const festState = State.getFestival(f.id);
    const urgencyLabel = Utils.urgencyLabel(urgency);
    const statusLabel = ({none:"未启动",selection:"选品中",ordered:"已下单",arrived:"已到仓",listed:"已上架"})[festState.status] || festState.status;
    f.products.forEach(p => {
      rows.push([
        f.month + "月", f.name, f.date, f.importance, f.category,
        urgencyLabel, statusLabel,
        p.sku, p.skuEn, p.category, p.costRange, p.priceRange,
        p.margin, p.matchScore + "/5", p.riskLevel, p.riskNote,
        (p.keywords || []).join("; ")
      ]);
    });