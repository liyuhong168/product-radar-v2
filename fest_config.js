const CONFIG = {
  // transit=纯运输到FBA仓库；production=下单到出厂（固定3天）；leadTime=production+transit
  // arrivalBuffer=到仓后入仓2天+缓冲12天=14天（到仓到节日最小间隔）
  logisticsModes: {
    air:   { leadTime: 16, production: 3,  transit: 13, label: "空运" },
    truck: { leadTime: 33, production: 3, transit: 30, label: "卡航/快铁" },
    sea:   { leadTime: 63, production: 3, transit: 60, label: "海运" }
  },
  arrivalBuffer: 14, // 入仓2天 + 缓冲12天（到仓→节日）
  defaultLogistics: "truck",
  // 双段物流里程碑：daysBefore = 节日前X天（正数）
  // daysBeforeSource 引用物流方式属性 + 固定偏移；airArrival首批固定走空运
  milestones: [
    { id: "selection",  daysBeforeSource: "leadTime+14", name: "选品+下单",    actions: "定SKU；同时下空运首批50件+大货订单（出厂{production}天）" },
    { id: "airArrival", daysBeforeSource: "leadTime+1",  name: "空运首批到仓", actions: "空运13天到仓，开始测款观察" },
    { id: "truckShip",  daysBeforeSource: "transit+14",  name: "大货发运",      actions: "大货出厂发UK（{modeLabel}约{transit}天到FBA）" },
    { id: "arrival",    daysBefore: 14,                  name: "大货到仓",      actions: "到FBA仓库→入仓2天→缓冲12天后上架销售" },
    { id: "festival",   daysBefore: 0,                   name: "节日销售",      actions: "广告加投，促销启动" }
  ],
  urgencyThresholds: { urgent: 0, week: 7, month: 30, plan: Infinity },
  categories: {
    decor:   { label: "🎃装饰", color: "#fb923c" },
    gift:    { label: "🎁礼品", color: "#ec4899" },
    apparel: { label: "👕服饰", color: "#8b5cf6" },
    home:    { label: "🏠家居", color: "#14b8a6" }
  },
  months: [
    { num: 1, label: "1月" }, { num: 2, label: "2月" }, { num: 3, label: "3月" },
    { num: 4, label: "4月" }, { num: 5, label: "5月" }, { num: 6, label: "6月" },
    { num: 7, label: "7月" }, { num: 8, label: "8月" }, { num: 9, label: "9月" },
    { num: 10, label: "10月" }, { num: 11, label: "11月" }, { num: 12, label: "12月" }
  ],
  storageKey: "uk_festival_planner_v1"
};
const LOGISTICS_OPTIONS = [
  { id: "sea",   label: "海运60天", icon: "🚢" },
  { id: "truck", label: "卡航30天", icon: "🚆" },
  { id: "air",   label: "空运13天", icon: "✈️" }
];