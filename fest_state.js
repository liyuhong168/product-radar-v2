const State = {
  data: null,
  load() {
    const raw = localStorage.getItem(CONFIG.storageKey);
    if (raw) {
      try { this.data = JSON.parse(raw); }
      catch (e) { console.warn("存储数据损坏，重置", e); this.init(); }
    } else { this.init(); }
    return this.data;
  },
  init() {
    this.data = { version: "1.0", lastUpdated: new Date().toISOString(), festivals: {} };
    this.save();
  },
  save() {
    this.data.lastUpdated = new Date().toISOString();
    try {
      localStorage.setItem(CONFIG.storageKey, JSON.stringify(this.data));
      this._saveError = false;
    } catch (e) {
      // 配额超限或隐私模式禁用存储：每会话仅提示一次，避免 oninput 高频写入时弹窗刷屏
      if (!this._saveError) {
        this._saveError = true;
        console.warn("保存失败", e);
        alert("⚠️ 浏览器存储已满或被禁用，进度无法保存。建议先导出备份，再清理浏览器存储。");
      }
    }
  },
  getFestival(id) {
    if (!this.data.festivals[id]) {
      this.data.festivals[id] = {
        status: "none", logistics: CONFIG.defaultLogistics,
        milestones: { selection: false, airArrival: false, truckShip: false, arrival: false, festival: false },
        notes: "", selectedSkus: []
      };
    }
    return this.data.festivals[id];
  },
  updateFestival(id, updates) {
    Object.assign(this.getFestival(id), updates);
    this.save();
  },
  toggleMilestone(id, mid) {
    const f = this.getFestival(id);
    f.milestones[mid] = !f.milestones[mid];
    this.save();
  },
  toggleSku(id, sku) {
    const f = this.getFestival(id);
    const i = f.selectedSkus.indexOf(sku);
    if (i >= 0) f.selectedSkus.splice(i, 1);
    else f.selectedSkus.push(sku);
    this.save();
  },
  export() { return JSON.stringify(this.data, null, 2); },
  import(str) {
    const p = JSON.parse(str);
    if (!p.version || !p.festivals) throw new Error("文件格式不正确");
    this.data = p; this.save();
  },
  reset() { localStorage.removeItem(CONFIG.storageKey); this.init(); }
};

// 当前筛选状态
const Filter = {
  category: "", month: "", urgency: "", status: "", search: "", statCardUrgency: ""
};

// ============================================
// Utils：工具函数