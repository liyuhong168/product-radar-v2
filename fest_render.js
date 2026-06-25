const Render = {
  monthNav() {
    document.getElementById("monthNav").innerHTML =
      CONFIG.months.map(m => `<a href="#month-${m.num}">${m.label}</a>`).join("");
  },

  dashboard() {
    const today = Utils.today();
    const stats = { urgent: 0, week: 0, month: 0, plan: 0, past: 0 };
    FESTIVALS.forEach(f => stats[Utils.getUrgency(f)]++);

    // 最近需备货节点
    const upcoming = FESTIVALS
      .filter(f => Utils.getUrgency(f) !== "past")
      .map(f => ({ fest: f, deadline: Utils.getSelectionDeadline(f.date, State.getFestival(f.id).logistics) }))
      .sort((a, b) => a.deadline - b.deadline)[0];

    const cd = document.getElementById("countdown");
    if (upcoming) {
      const days = Utils.diffDays(upcoming.deadline, today);
      const u = Utils.getUrgency(upcoming.fest);
      cd.innerHTML = `今日 <strong>${Utils.fmtYMD(today)}</strong> · 最近备货节点：
        <strong>${upcoming.fest.icon} ${upcoming.fest.name}</strong>（${upcoming.fest.date}）
        · 选品截止 <strong>${Utils.fmtYMD(upcoming.deadline)}</strong>
        · <span class="badge ${u}">${Utils.urgencyLabel(u)}</span>`;
    }

    const cards = [
      { key:"urgent", cls:"urgent", num:stats.urgent, label:"🔴 紧急（已过截止）" },
      { key:"week",   cls:"week",   num:stats.week,   label:"🟠 本周必须启动" },
      { key:"month",  cls:"month",  num:stats.month,  label:"🟡 本月需备货" },
      { key:"plan",   cls:"plan",   num:stats.plan,   label:"🟢 规划观察中" }
    ];
    document.getElementById("statCards").innerHTML = cards.map(c =>
      `<div class="stat-card ${c.cls} ${Filter.statCardUrgency === c.key ? "active" : ""}" onclick="Filter.statCardUrgency='${c.key}';Filter.search='';Filter.urgency='${c.key}';document.getElementById('filterSearch').value='';document.getElementById('filterUrgency').value='${c.key}';Interact.applyFilter();">
        <div class="num">${c.num}</div>
        <div class="label">${c.label}</div>
      </div>`
    ).join("");
  },

  main() {
    const filtered = FESTIVALS.filter(f => {
      const festState = State.getFestival(f.id);
      const urgency = Utils.getUrgency(f);
      if (Filter.category && !f.products.some(p => p.category === Filter.category)) return false;
      if (Filter.month && f.month !== parseInt(Filter.month)) return false;
      const effU = Filter.statCardUrgency || Filter.urgency;
      if (effU && urgency !== effU) return false;
      if (Filter.status && festState.status !== Filter.status) return false;
      if (Filter.search) {
        const q = Filter.search.toLowerCase();
        const hay = (f.name + f.nameEn + f.icon +
          f.products.map(p => p.sku + p.skuEn + p.keywords.join("")).join("")).toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });

    const mainEl = document.getElementById("main");
    if (filtered.length === 0) {
      mainEl.innerHTML = `<div class="empty-state">没有匹配的节日，试试调整筛选条件。🔍</div>`;
      return;
    }

    const byMonth = {};
    filtered.forEach(f => { (byMonth[f.month] = byMonth[f.month] || []).push(f); });

    let html = "";
    CONFIG.months.forEach(m => {
      if (!byMonth[m.num]) return;
      const fests = byMonth[m.num].sort((a, b) => new Date(a.date) - new Date(b.date));
      html += `<section class="month-section" id="month-${m.num}">
        <h2>${m.label} <span class="count">(${fests.length}个节点)</span></h2>
        <div class="cards-grid">${fests.map(f => this.festivalCard(f)).join("")}</div>
      </section>`;
    });
    mainEl.innerHTML = html;
  },

  festivalCard(f) {
    const festState = State.getFestival(f.id);
    const urgency = Utils.getUrgency(f);
    const deadline = Utils.getSelectionDeadline(f.date, festState.logistics);
    const days = Utils.diffDays(deadline, Utils.today());
    const expanded = f.importance === "S" ? "expanded" : "";
    const catLabel = ({ festival:"节日", activity:"活动", trend:"趋势" })[f.category] || f.category;

    const header = `
      <div class="card-header" tabindex="0" role="button" aria-expanded="${expanded ? "true" : "false"}" onclick="Interact.toggleCard('${f.id}')" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();Interact.toggleCard('${f.id}')}">
        <div>
          <div class="card-title">
            <span class="icon">${f.icon}</span>
            <span>${f.name}</span>
            <span class="name-en">${f.nameEn}</span>
            ${f.importance === "S" ? '<span class="badge importance-S">S级</span>' : ""}
            <span class="badge ${urgency}">${Utils.urgencyLabel(urgency)}</span>
          </div>
          <div class="card-meta">
            ${f.date} · ${catLabel} | 选品截止 ${Utils.fmtYMD(deadline)}（${days >= 0 ? "剩" + days + "天" : "已过" + (-days) + "天"}）
          </div>
        </div>
        <div class="card-arrow">${expanded ? "▼" : "▶"}</div>
      </div>`;

    const body = `<div class="card-body">
      ${this.logisticsToggle(f.id, festState.logistics)}
      ${this.timeline(f)}
      ${this.products(f)}
      ${this.validation(f)}
      ${this.controls(f)}
    </div>`;

    return `<div class="festival-card ${expanded}" id="card-${f.id}" style="border-left-color:${f.themeColor}">${header}${body}</div>`;
  },

  logisticsToggle(id, logistics) {
    const btns = LOGISTICS_OPTIONS.map(o =>
      `<button class="${o.id === logistics ? "active" : ""}"
        onclick="Interact.switchLogistics('${id}','${o.id}')">${o.icon} ${o.label}</button>`
    ).join("");
    return `<div class="card-controls"><label>物流方式：</label><div class="logistics-toggle">${btns}</div></div>`;
  },

  timeline(f) {
    const festState = State.getFestival(f.id);
    const ms = Utils.getMilestoneDates(f);
    const nodes = ms.map(m => {
      const done = festState.milestones[m.id];
      return `<div class="timeline-node">
        <div class="timeline-dot ${done ? "done" : ""}"
          tabindex="0" role="button"
          aria-label="${m.name} ${m.dateStr}${done ? '（已完成）' : '（未完成）'}"
          onclick="Interact.toggleMilestone('${f.id}','${m.id}')"
          onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();Interact.toggleMilestone('${f.id}','${m.id}')}"
          title="${m.actions}"></div>
        <div class="ms-name">${m.name}</div>
        <div class="ms-date">${m.dateStr}</div>
      </div>`;
    }).join("");
    const mode = CONFIG.logisticsModes[festState.logistics];
    return `<div class="timeline">
      <div style="font-size:12px;color:var(--text-muted)">
        📅 备货时间线（${mode.label}，总提前期${mode.leadTime + 14}天）
      </div>
      <div class="timeline-track">${nodes}</div>
      <div style="font-size:11px;color:var(--text-muted);margin-top:6px">
        💡 策略：空运首批50件测款 + ${mode.label}大货同时下单。点击圆点标记完成。
      </div>
    </div>`;
  },

  products(f) {
    const festState = State.getFestival(f.id);
    const cats = ["decor", "gift", "apparel", "home"];
    const tabs = `<div class="product-cat-tabs">
      <div class="product-cat-tab active" onclick="Interact.filterProductCat('${f.id}','',this)">${f.products.length} 全部</div>
      ${cats.filter(c => f.products.some(p => p.category === c)).map(c => {
        const cnt = f.products.filter(p => p.category === c).length;
        return `<div class="product-cat-tab" onclick="Interact.filterProductCat('${f.id}','${c}',this)">${CONFIG.categories[c].label} ${cnt}</div>`;
      }).join("")}
    </div>`;
    const rows = f.products.map(p => {
      const sel = festState.selectedSkus.includes(p.sku);
      const riskCls = p.riskLevel === "低" ? "risk-low" : p.riskLevel === "中" ? "risk-mid" : "risk-high";
      return `<tr class="prod-row" data-cat="${p.category}">
        <td><input type="checkbox" ${sel ? "checked" : ""} onchange="Interact.toggleSku('${f.id}','${Utils.escape(p.sku)}')" title="标记要做"></td>
        <td><strong>${p.sku}</strong><br><span style="color:var(--text-muted);font-size:11px">${p.skuEn}</span></td>
        <td>${p.costRange}</td>
        <td><strong>${p.priceRange}</strong></td>
        <td style="color:var(--text-muted)">${p.margin}</td>
        <td><span class="stars">${Utils.stars(p.matchScore)}</span></td>
        <td><span class="risk ${riskCls}" title="${Utils.escape(p.riskNote)}">${p.riskLevel}</span></td>
        <td class="kw-cell">${p.keywords.map(kw => `<a class="amazon-kw" href="https://www.amazon.co.uk/s?k=${encodeURIComponent(kw)}" target="_blank" rel="noopener" title="在亚马逊UK搜索: ${Utils.escape(kw)}"><span class="amz-icon">🔍</span>${Utils.escape(kw)}</a>`).join("")}</td>
      </tr>`;
    }).join("");
    return `<div class="products-section">
      <h4>🛒 选品清单（${f.products.length}个SKU建议）</h4>
      ${tabs}
      <div class="product-table-wrap"><table class="product-table">
        <thead><tr><th></th><th>SKU</th><th>1688拿货</th><th>建议售价</th><th>毛利率</th><th>匹配度</th><th>风险</th><th>关键词（点击搜亚马逊）</th></tr></thead>
        <tbody>${rows}</tbody>
      </table></div>
    </div>`;
  },

  validation(f) {
    const v = f.validation || {};
    const trendLinks = (v.googleTrends || []).map(kw =>
      `<a class="amazon-kw" href="https://www.amazon.co.uk/s?k=${encodeURIComponent(kw)}" target="_blank" rel="noopener" title="在亚马逊UK搜索: ${Utils.escape(kw)}"><span class="amz-icon">🔍</span>${Utils.escape(kw)}</a>`
    ).join(" ");
    return `<div class="validation-section">
      <h4>🔍 验证指引（数据依据）</h4>
      <ul>
        <li><strong>Google Trends：</strong>${trendLinks}</li>
        <li><strong>亚马逊验证：</strong>${Utils.escape(v.amazonCheck || "")}</li>
        <li><strong>1688拿货：</strong>${Utils.escape(v.sourcing || "")}</li>
      </ul>
      ${v.riskFlags && v.riskFlags.length ? `<div style="margin-top:6px;color:var(--urgent)"><strong>⚠️ 风险提示：</strong>${v.riskFlags.map(r => Utils.escape(r)).join("；")}</div>` : ""}
    </div>`;
  },

  controls(f) {
    const festState = State.getFestival(f.id);
    const opts = [
      { v:"none", l:"未启动" }, { v:"selection", l:"选品中" }, { v:"ordered", l:"已下单" },
      { v:"arrived", l:"已到仓" }, { v:"listed", l:"已上架" }
    ];
    return `<div class="card-controls" style="margin-top:8px">
      <label>状态：</label>
      <select onchange="Interact.setStatus('${f.id}',this.value)">
        ${opts.map(o => `<option value="${o.v}" ${festState.status === o.v ? "selected" : ""}>${o.l}</option>`).join("")}
      </select>
    </div>
    <div>
      <label style="font-size:12px;color:var(--text-muted)">📝 备注（店铺分布/供应商等）：</label>
      <textarea class="notes-area" placeholder="如：A店计划上架8款，B店5款；供应商：义乌XX"
        oninput="Interact.setNotes('${f.id}',this.value)">${Utils.escape(festState.notes)}</textarea>
    </div>`;
  }
};

// ============================================
// Interact：交互绑定