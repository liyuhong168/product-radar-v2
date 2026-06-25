const Utils = {
  parseDate(str) {
    // 兼容写法：拆分YYYY-MM-DD，避免旧引擎ISO解析问题
    const parts = str.split("-").map(Number);
    return new Date(parts[0], parts[1] - 1, parts[2]);
  },
  today() { const d = new Date(); d.setHours(0,0,0,0); return d; },
  diffDays(a, b) { return Math.round((a - b) / 86400000); },
  fmtMD(date) { return `${date.getMonth() + 1}/${date.getDate()}`; },
  fmtYMD(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2,"0")}-${String(date.getDate()).padStart(2,"0")}`;
  },
  // 选品截止日 = 节日 - (leadTime + 14)
  getSelectionDeadline(festivalDate, logistics) {
    const mode = CONFIG.logisticsModes[logistics];
    const d = new Date(this.parseDate(festivalDate));
    d.setDate(d.getDate() - (mode.leadTime + 14));
    return d;
  },
  // 5个里程碑日期：daysBefore = 节日前X天（正数）
  // daysBeforeSource 引用物流方式属性（如 "leadTime+14"），否则用固定 daysBefore
  getMilestoneDates(festival) {
    const logistics = State.getFestival(festival.id).logistics;
    const mode = CONFIG.logisticsModes[logistics];
    return CONFIG.milestones.map(ms => {
      // 解析 daysBeforeSource：如 "leadTime+14" → mode.leadTime + 14；"transit" → mode.transit
      let daysBefore;
      if (ms.daysBeforeSource) {
        const expr = ms.daysBeforeSource;
        if (expr.includes("+")) {
          const [base, add] = expr.split("+");
          daysBefore = mode[base] + parseInt(add);
        } else {
          daysBefore = mode[expr];
        }
      } else {
        daysBefore = ms.daysBefore;
      }
      const d = new Date(this.parseDate(festival.date));
      d.setDate(d.getDate() - daysBefore);
      // 渲染时按当前物流方式替换 actions 里的占位符（{modeLabel}/{transit}/{leadTime}/{production}）
      const actions = (ms.actions || "").replace(/\{modeLabel\}/g, mode.label)
        .replace(/\{transit\}/g, mode.transit).replace(/\{leadTime\}/g, mode.leadTime)
        .replace(/\{production\}/g, mode.production);
      return { ...ms, actions, date: d, dateStr: this.fmtMD(d) };
    });
  },
  getUrgency(festival) {
    const festState = State.getFestival(festival.id);
    const fDate = this.parseDate(festival.date);
    const today = this.today();
    if (fDate < today) return "past";
    const deadline = this.getSelectionDeadline(festival.date, festState.logistics);
    const days = this.diffDays(deadline, today);
    if (days < 0) {
      if (festState.milestones.selection) return "plan";
      return "urgent";
    } else if (days <= CONFIG.urgencyThresholds.week) return "week";
    else if (days <= CONFIG.urgencyThresholds.month) return "month";
    return "plan";
  },
  urgencyLabel(u) {
    return ({ urgent:"🔴紧急", week:"🟠本周启动", month:"🟡本月备货", plan:"🟢规划中", past:"⚫已过" })[u] || u;
  },
  stars(s) { return "★".repeat(s) + "☆".repeat(5 - s); },
  escape(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  },
  // 防抖：停止调用 ms 毫秒后才执行，用于搜索框避免每次键入都全量重渲染
  debounce(fn, ms) {
    let t;
    return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
  }
};

// ============================================
// Render：渲染函数