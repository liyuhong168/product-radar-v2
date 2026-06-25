const Interact = {
  toggleCard(id) {
    const card = document.getElementById("card-" + id);
    if (card) {
      card.classList.toggle("expanded");
      const isExpanded = card.classList.contains("expanded");
      const header = card.querySelector(".card-header");
      if (header) header.setAttribute("aria-expanded", isExpanded ? "true" : "false");
      const arrow = card.querySelector(".card-arrow");
      if (arrow) arrow.textContent = isExpanded ? "▼" : "▶";
    }
  },
  applyFilter() { Render.main(); },
  resetFilter() {
    Filter.category = ""; Filter.month = ""; Filter.urgency = "";
    Filter.status = ""; Filter.search = ""; Filter.statCardUrgency = "";
    document.getElementById("filterCategory").value = "";
    document.getElementById("filterMonth").value = "";
    document.getElementById("filterUrgency").value = "";
    document.getElementById("filterStatus").value = "";
    document.getElementById("filterSearch").value = "";
    Render.main();
  },
  switchLogistics(id, logistics) {
    State.updateFestival(id, { logistics });
    // 只更新当前卡片内容，不重绘整个页面，避免卡片关闭
    const card = document.getElementById("card-" + id);
    if (card) {
      const wasExpanded = card.classList.contains("expanded");
      const festState = State.getFestival(id);
      const f = FESTIVALS.find(f => f.id === id);
      if (f) {
        card.outerHTML = Render.festivalCard(f);
        const newCard = document.getElementById("card-" + id);
        if (newCard && wasExpanded) newCard.classList.add("expanded");
      }
    }
    Render.dashboard();
  },
  toggleMilestone(id, mid) {
    State.toggleMilestone(id, mid);
    // 只更新当前卡片内容，不重绘整个页面，避免卡片关闭
    const card = document.getElementById("card-" + id);
    if (card) {
      const wasExpanded = card.classList.contains("expanded");
      const f = FESTIVALS.find(f => f.id === id);
      if (f) {
        card.outerHTML = Render.festivalCard(f);
        const newCard = document.getElementById("card-" + id);
        if (newCard && wasExpanded) newCard.classList.add("expanded");
      }
    }
    Render.dashboard();
  },
  toggleSku(id, sku) { State.toggleSku(id, sku); },
  setStatus(id, status) { State.updateFestival(id, { status }); Render.dashboard(); },
  setNotes(id, notes) { State.updateFestival(id, { notes }); },
  filterProductCat(id, cat, el) {
    const card = document.getElementById("card-" + id);
    if (!card) return;
    card.querySelectorAll(".product-cat-tab").forEach(t => t.classList.remove("active"));
    el.classList.add("active");
    card.querySelectorAll(".prod-row").forEach(row => {
      row.classList.toggle("hidden", cat && row.dataset.cat !== cat);
    });
  }
};

// ============================================
// 筛选栏事件绑定
// ============================================
function bindFilters() {
  document.getElementById("filterCategory").addEventListener("change", e => {
    Filter.category = e.target.value; Filter.statCardUrgency = ""; Render.main();
  });
  document.getElementById("filterMonth").addEventListener("change", e => {
    Filter.month = e.target.value; Render.main();
  });
  document.getElementById("filterUrgency").addEventListener("change", e => {
    Filter.urgency = e.target.value; Filter.statCardUrgency = ""; Render.main();
  });
  document.getElementById("filterStatus").addEventListener("change", e => {
    Filter.status = e.target.value; Render.main();
  });
  const debouncedSearch = Utils.debounce(v => { Filter.search = v; Render.main(); }, 180);
  document.getElementById("filterSearch").addEventListener("input", e => {
    debouncedSearch(e.target.value);
  });
  document.getElementById("resetFilter").addEventListener("click", () => Interact.resetFilter());
}

// ============================================
// 导入/导出/重置