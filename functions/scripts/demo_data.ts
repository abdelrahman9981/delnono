/**
 * Researched demo data for the emulator seed (and later the D-43 demo). Sources and dates are in
 * docs/demo-data-sources.md. Every medical item is `reviewStatus: "proposed"` with its source URL:
 * the doctor approves each one before launch, and none of it may reach production
 * (docs/launch-checklist.md; guarded by seed_guard.ts and test/lib/demoData.test.ts).
 * No medicine names with doses, no diagnoses, no "normal/abnormal" judgments.
 */

export const PROPOSED = "proposed" as const;

export const SRC = {
  holidays: "https://holidaydb.com/guides/public-holidays/egypt/2027",
  visitPrices: "https://www.vezeeta.com/ar/دكتور/اطفال-وحديثي-الولادة/المقطم",
  mohp2022: "https://gate.ahram.org.eg/News/3524751.aspx",
  mohp2025: "https://www.youm7.com/story/2025/5/26/جدول-تطعيمات-الأطفال-منذ-الولادة-وحتى-18-شهرًا-تفاصيل/6995920",
  mohpSalk2025: "https://www.youm7.com/story/2025/11/16/الصحة-توضح-جداول-التطعيمات-الإجبارية-والإضافية-لحديثى-الميلاد-صور/7199401",
  optionalPrices2026: "https://manassa.news/stories/31652",
  rotaPrice2025: "https://www.vetogate.com/5333728",
  meningoPrice2024: "https://www.youm7.com/story/2024/6/7/وزارة-الصحة-تكشف-سعر-لقاح-الالتهاب-السحائى-وموعد-الحصول-عليه/6601191",
  fluPrice2026: "https://www.elbalad.news/7127226",
  cdc: (age: string) => `https://www.cdc.gov/act-early/milestones/${age}.html`,
  imci: "https://www.afro.who.int/sites/default/files/2017-06/chartbooklet.pdf",
  imciEgypt: "https://platform.who.int/docs/default-source/mca-documents/policy-documents/operational-guidance/EGY-CH-59-01-OPERATIONALGUIDANCE-eng-IMCI-Assessment-Booklet-2m-5yrs.pdf",
  aapFever: "https://www.healthychildren.org/English/health-issues/conditions/fever/pages/When-to-Call-the-Pediatrician.aspx",
  aapTemperature: "https://www.healthychildren.org/English/health-issues/conditions/fever/Pages/How-to-Take-a-Childs-Temperature.aspx",
  aapSafeSleep: "https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/A-Parents-Guide-to-Safe-Sleep.aspx",
  aapBedtime: "https://www.healthychildren.org/English/healthy-living/sleep/Pages/Bedtime-Trouble.aspx",
  aapSolids: "https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/starting-solid-foods.aspx",
  aapSalt: "https://www.healthychildren.org/English/healthy-living/nutrition/Pages/We-Dont-Need-to-Add-Salt-to-Food.aspx",
  aapAllergens: "https://www.healthychildren.org/English/healthy-living/nutrition/Pages/when-to-introduce-egg-peanut-butter-and-other-common-food-allergens-to-your-baby-food-allergy-prevention-tips.aspx",
  aapAnaphylaxis: "https://www.healthychildren.org/English/health-issues/injuries-emergencies/pages/Anaphylaxis.aspx",
  aapVaccineReactions: "https://www.healthychildren.org/English/tips-tools/symptom-checker/Pages/symptomviewer.aspx?symptom=Immunization+Reactions",
  aapCord: "https://www.healthychildren.org/English/ages-stages/baby/bathing-skin-care/Pages/Umbilical-Cord-Care.aspx",
  whoNewborn: "https://www.who.int/news-room/fact-sheets/detail/newborn-mortality",
  whoFeeding: "https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding",
  whoGrowth: "https://www.who.int/tools/child-growth-standards/standards",
};

/** Egyptian public holidays, Nov 2026 – Dec 2027 (none fall in Nov–Dec 2026). Lunar dates may move a day. */
export const HOLIDAYS = [
  "2027-01-07", "2027-01-25", "2027-01-28", "2027-03-10", "2027-03-11", "2027-03-12", "2027-04-25", "2027-05-01",
  "2027-05-03", "2027-05-16", "2027-05-17", "2027-05-18", "2027-05-19", "2027-06-07", "2027-06-30", "2027-07-01",
  "2027-07-23", "2027-08-15", "2027-10-06", "2027-10-07",
];

/**
 * Vaccine list. v1, v2 (basic) and v3, v4 (additional) keep their ids from the earlier seed.
 * `price` is EGP per dose at clinic 1 (approximate; clinic 2 adds 10%); basic vaccines are free at
 * MOHP units, so the clinic price is 0 and shown as free.
 */
export interface DemoVaccine {
  id: string;
  name: string;
  kind: "basic" | "additional";
  price: number;
  sourceUrl: string;
  suggestedAge?: { months: number; days: number };
  doses?: number;
  intervalWeeks?: number;
  note?: string;
}

export const VACCINES: DemoVaccine[] = [
  { id: "v1", name: "شلل الأطفال بالفم (سابين)", kind: "basic", price: 0, sourceUrl: SRC.mohp2025 },
  { id: "v2", name: "الخماسي (دفتيريا، تيتانوس، سعال ديكي، التهاب كبدي ب، هيموفيلس)", kind: "basic", price: 0, sourceUrl: SRC.mohp2025 },
  { id: "v5", name: "الالتهاب الكبدي ب (جرعة الولادة)", kind: "basic", price: 0, sourceUrl: SRC.mohp2025 },
  { id: "v6", name: "الدرن (BCG)", kind: "basic", price: 0, sourceUrl: SRC.mohp2022 },
  { id: "v7", name: "شلل الأطفال بالحقن (سولك)", kind: "basic", price: 0, sourceUrl: SRC.mohpSalk2025 },
  { id: "v8", name: "الحصبة والحصبة الألمانية والنكاف (MMR)", kind: "basic", price: 0, sourceUrl: SRC.mohp2022 },
  { id: "v9", name: "الثلاثي البكتيري (جرعة منشطة)", kind: "basic", price: 0, sourceUrl: SRC.mohp2022 },
  {
    id: "v3", name: "الروتا (بالفم)", kind: "additional", price: 650, sourceUrl: SRC.rotaPrice2025,
    suggestedAge: { months: 2, days: 0 }, doses: 2, intervalWeeks: 8, note: "جرعتين؛ الدكتور بيحدد المواعيد",
  },
  {
    id: "v4", name: "المكورات الرئوية", kind: "additional", price: 700, sourceUrl: SRC.optionalPrices2026,
    suggestedAge: { months: 2, days: 0 }, doses: 3, intervalWeeks: 8, note: "الدكتور بيحدد عدد الجرعات حسب السن",
  },
  {
    id: "v10", name: "الجديري المائي", kind: "additional", price: 1500, sourceUrl: SRC.optionalPrices2026,
    suggestedAge: { months: 12, days: 0 }, doses: 1, intervalWeeks: 0,
  },
  {
    id: "v11", name: "الالتهاب الكبدي أ", kind: "additional", price: 750, sourceUrl: SRC.optionalPrices2026,
    suggestedAge: { months: 12, days: 0 }, doses: 2, intervalWeeks: 26, note: "سعر تقديري",
  },
  {
    id: "v12", name: "الحمى الشوكية (المكورات السحائية)", kind: "additional", price: 1275, sourceUrl: SRC.meningoPrice2024,
    suggestedAge: { months: 24, days: 0 }, doses: 1, intervalWeeks: 0,
  },
  {
    id: "v13", name: "الإنفلونزا الموسمية", kind: "additional", price: 322, sourceUrl: SRC.fluPrice2026,
    suggestedAge: { months: 6, days: 0 }, doses: 1, intervalWeeks: 0, note: "كل سنة قبل الشتا",
  },
];

/** MOHP basic schedule (free). Ages in months; `lastMonths` is the end of the window. */
export interface DemoScheduleEntry {
  id: string;
  vaccineId: string;
  dose: number;
  months: number;
  ageLabel: string;
  lastMonths?: number;
  sourceUrl: string;
}

const birth = "عند الولادة";
export const SCHEDULE: DemoScheduleEntry[] = [
  { id: "s01", vaccineId: "v5", dose: 1, months: 0, ageLabel: `${birth} (أول ٢٤ ساعة)`, sourceUrl: SRC.mohp2025 },
  { id: "s02", vaccineId: "v1", dose: 1, months: 0, ageLabel: `${birth} (الجرعة الصفرية)`, sourceUrl: SRC.mohp2025 },
  { id: "s03", vaccineId: "v6", dose: 1, months: 0, ageLabel: `${birth} (أول ١٥ يوم)`, lastMonths: 3, sourceUrl: SRC.mohp2022 },
  { id: "s04", vaccineId: "v1", dose: 2, months: 2, ageLabel: "الشهر التاني", sourceUrl: SRC.mohp2025 },
  { id: "s05", vaccineId: "v2", dose: 1, months: 2, ageLabel: "الشهر التاني", sourceUrl: SRC.mohp2025 },
  { id: "s06", vaccineId: "v7", dose: 1, months: 2, ageLabel: "الشهر التاني", sourceUrl: SRC.mohpSalk2025 },
  { id: "s07", vaccineId: "v1", dose: 3, months: 4, ageLabel: "الشهر الرابع", sourceUrl: SRC.mohp2025 },
  { id: "s08", vaccineId: "v2", dose: 2, months: 4, ageLabel: "الشهر الرابع", sourceUrl: SRC.mohp2025 },
  { id: "s09", vaccineId: "v7", dose: 2, months: 4, ageLabel: "الشهر الرابع", sourceUrl: SRC.mohpSalk2025 },
  { id: "s10", vaccineId: "v1", dose: 4, months: 6, ageLabel: "الشهر السادس", sourceUrl: SRC.mohp2025 },
  { id: "s11", vaccineId: "v2", dose: 3, months: 6, ageLabel: "الشهر السادس", sourceUrl: SRC.mohp2025 },
  { id: "s12", vaccineId: "v7", dose: 3, months: 6, ageLabel: "الشهر السادس", sourceUrl: SRC.mohpSalk2025 },
  { id: "s13", vaccineId: "v1", dose: 5, months: 9, ageLabel: "الشهر التاسع", sourceUrl: SRC.mohp2022 },
  { id: "s14", vaccineId: "v1", dose: 6, months: 12, ageLabel: "السنة الأولى", sourceUrl: SRC.mohp2022 },
  { id: "s15", vaccineId: "v8", dose: 1, months: 12, ageLabel: "السنة الأولى", sourceUrl: SRC.mohp2022 },
  { id: "s16", vaccineId: "v1", dose: 7, months: 18, ageLabel: "سنة ونص", sourceUrl: SRC.mohp2022 },
  { id: "s17", vaccineId: "v9", dose: 1, months: 18, ageLabel: "سنة ونص", lastMonths: 24, sourceUrl: SRC.mohp2022 },
  { id: "s18", vaccineId: "v8", dose: 2, months: 18, ageLabel: "سنة ونص", lastMonths: 24, sourceUrl: SRC.mohp2022 },
];

/**
 * Follow-up by age: things most children do by that age (CDC "Learn the Signs. Act Early."), as a
 * checklist the doctor reviews; band ids and titles as before. `dangerSigns` are the band's own
 * «إمتى تتصلي بالدكتور» items, shown with the general ones.
 */
export interface DemoBand {
  fromMonths: number;
  toMonths: number;
  title: string;
  items: string[];
  dangerSigns: string[];
  sourceUrl: string;
}

export const YOUNG_INFANT_SIGNS = [
  "مش بيرضع كويس أو بطّل يرضع",
  "جاله تشنجات (رعشة أو تخشب في الجسم)",
  "بيتنفس بسرعة، أو صدره بيدخل لجوه مع النفس",
  "حرارته ٣٧٫٥ أو أكتر، أو جسمه بارد",
  "مش بيتحرك غير لما حد يلمسه",
  "الصفار وصل لكف إيده أو رجله",
];

export const BANDS: DemoBand[] = [
  {
    fromMonths: 0, toMonths: 2, title: "متابعة أول شهرين", sourceUrl: SRC.cdc("2-months"),
    items: ["بيهدى لما تكلميه أو تشيليه", "بيبص في وشك", "بيرفع راسه وهو نايم على بطنه", "بيحرك إيديه ورجليه الاتنين"],
    dangerSigns: YOUNG_INFANT_SIGNS,
  },
  {
    fromMonths: 2, toMonths: 4, title: "متابعة الشهر التاني والتالت", sourceUrl: SRC.cdc("4-months"),
    items: ["بيبتسم عشان يلفت نظرك", "بيطلع أصوات زي «آآه» و«أووه»", "بيلف راسه ناحية صوتك", "بيمسك اللعبة لما تحطيها في إيده"],
    dangerSigns: ["عمره أقل من ٣ شهور وحرارته ٣٨ أو أكتر: كلمي الدكتور فورًا"],
  },
  {
    fromMonths: 4, toMonths: 6, title: "متابعة الشهر الرابع والخامس", sourceUrl: SRC.cdc("6-months"),
    items: ["بيعرف الناس اللي بيشوفهم كل يوم", "بيضحك بصوت", "بيمد إيده يمسك لعبة", "بيتقلب من بطنه على ضهره"],
    dangerSigns: [],
  },
  {
    fromMonths: 6, toMonths: 9, title: "متابعة الشهر السادس", sourceUrl: SRC.cdc("9-months"),
    items: ["بيبص لما تناديه باسمه", "بيقول «ماما» و«بابا» كأصوات", "بيقعد لوحده من غير سند", "بينقل الحاجة من إيد للتانية"],
    dangerSigns: [],
  },
  {
    fromMonths: 9, toMonths: 12, title: "متابعة الشهر التاسع", sourceUrl: SRC.cdc("1-year"),
    items: ["بيعمل «باي باي» بإيده", "بيفهم كلمة «لأ»", "بيقف ماسك في حاجة", "بيمسك الحاجات الصغيرة بصباعين"],
    dangerSigns: [],
  },
  {
    fromMonths: 12, toMonths: 18, title: "متابعة السنة الأولى", sourceUrl: SRC.cdc("15-months"),
    items: ["بيقول كلمة أو اتنين غير «ماما» و«بابا»", "بيشاور على حاجة عايز يوريهالك", "بيمشي كام خطوة لوحده", "بياكل بصوابعه"],
    dangerSigns: [],
  },
  {
    fromMonths: 18, toMonths: 24, title: "متابعة سنة ونص", sourceUrl: SRC.cdc("18-months"),
    items: ["بيقول ٣ كلمات أو أكتر", "بينفذ طلب بسيط من غير إشارة", "بيمشي من غير ما يمسك في حد", "بيحاول ياكل بالمعلقة"],
    dangerSigns: [],
  },
  {
    fromMonths: 24, toMonths: 36, title: "متابعة السنة التانية", sourceUrl: SRC.cdc("2-years"),
    items: ["بيقول كلمتين مع بعض", "بيشاور على جزأين من جسمه لما تسأليه", "بيشوط الكورة", "بيجري"],
    dangerSigns: [],
  },
  {
    fromMonths: 36, toMonths: 48, title: "متابعة السنة التالتة", sourceUrl: SRC.cdc("3-years"),
    items: ["بيتكلم معاكي جملة ورا جملة", "بيقول اسمه لما تسأليه", "بيلبس شوية من هدومه لوحده", "بيلعب مع أطفال تانيين"],
    dangerSigns: [],
  },
];

/** General danger signs for every age (WHO IMCI general danger signs, AAP fever guidance). */
export const DANGER_SIGNS = [
  "مش قادر يرضع أو يشرب خالص",
  "بيرجّع كل حاجة بياكلها أو بيشربها",
  "جاله تشنجات",
  "نايم على غير عادته وصعب تصحّيه",
  "بيتنفس بسرعة أو بصعوبة",
  "حرارته ٤٠ أو أكتر",
  "رقبته متخشبة مع الحرارة",
];
export const DANGER_SIGNS_SOURCES = [SRC.imci, SRC.imciEgypt, SRC.aapFever];

/** Short tips in plain Egyptian Arabic, 2–3 per category (content library, 006). */
export interface DemoTip {
  id: string;
  category: string;
  title: string;
  body: string;
  ageFromMonths?: number;
  ageToMonths?: number;
  sourceUrl: string;
}

export const TIPS: DemoTip[] = [
  {
    id: "tip-fever", category: "fever", title: "إزاي تقيسي حرارة طفلك صح", sourceUrl: SRC.aapTemperature,
    body: "استخدمي ترمومتر ديجيتال. للرضيع أقل من ٣ شهور القياس من الشرج هو الأدق، وتحت الباط ينفع لأي سن بس أقل دقة. اكتبي الرقم والساعة عشان تقوليهم للدكتور.",
  },
  {
    id: "tip-fever-2", category: "fever", title: "الحرارة عند الرضيع الصغير", sourceUrl: SRC.aapFever, ageFromMonths: 0, ageToMonths: 3,
    body: "لو طفلك أقل من ٣ شهور وحرارته ٣٨ أو أكتر، كلمي الدكتور على طول، ومتديهوش أي دوا قبل ما تسأليه.",
  },
  {
    id: "tip-fever-3", category: "fever", title: "إمتى الحرارة تستاهل مكالمة", sourceUrl: SRC.aapFever,
    body: "كلمي الدكتور لو الحرارة ٤٠ أو أكتر، أو لو طفلك أقل من سنتين والحرارة مكمّلة أكتر من يوم، أو لو شكله تعبان جدًا أو نعسان على غير عادته.",
  },
  {
    id: "tip-feeding", category: "feeding", title: "الرضاعة لوحدها أول ٦ شهور", sourceUrl: SRC.whoFeeding, ageFromMonths: 0, ageToMonths: 6,
    body: "أول ٦ شهور الرضاعة الطبيعية لوحدها كفاية لطفلك. ومن ٦ شهور بنبدأ أكل مهروس مع استمرار الرضاعة.",
  },
  {
    id: "tip-feeding-2", category: "feeding", title: "أكلة جديدة كل كام يوم", sourceUrl: SRC.aapSolids, ageFromMonths: 6, ageToMonths: 12,
    body: "ابدئي بأكلة واحدة جديدة، واستني كام يوم قبل اللي بعدها، عشان لو حصل طفح أو إسهال تعرفي سببه.",
  },
  {
    id: "tip-feeding-3", category: "feeding", title: "من غير ملح ولا سكر زيادة", sourceUrl: SRC.aapSalt, ageFromMonths: 6, ageToMonths: 24,
    body: "طفلك مش محتاج ملح أو سكر زيادة على أكله في أول سنتين. الطعم الطبيعي للأكل كفاية، والعادات دي بتفضل معاه.",
  },
  {
    id: "tip-sleep", category: "sleep", title: "نوم الرضيع على ضهره", sourceUrl: SRC.aapSafeSleep, ageFromMonths: 0, ageToMonths: 12,
    body: "نيّمي طفلك على ضهره في كل نومة، على سطح ثابت ومفرود، في سريره هو.",
  },
  {
    id: "tip-sleep-2", category: "sleep", title: "سرير فاضي يعني نوم أأمن", sourceUrl: SRC.aapSafeSleep, ageFromMonths: 0, ageToMonths: 12,
    body: "متحطيش مخدات أو بطاطين تقيلة أو لعب في سرير الرضيع.",
  },
  {
    id: "tip-sleep-3", category: "sleep", title: "روتين ثابت قبل النوم", sourceUrl: SRC.aapBedtime, ageFromMonths: 12, ageToMonths: 48,
    body: "حمام دافي، حكاية، ونفس الميعاد كل يوم. الروتين الهادي بيعرّف طفلك إن وقت النوم جه.",
  },
  {
    id: "tip-allergy", category: "allergy", title: "راقبي طفلك بعد أي أكلة جديدة", sourceUrl: SRC.aapSolids, ageFromMonths: 6, ageToMonths: 24,
    body: "لو ظهر طفح أو ترجيع أو إسهال بعد أكلة جديدة، وقّفيها وكلمي الدكتور.",
  },
  {
    id: "tip-allergy-2", category: "allergy", title: "علامات محتاجة مساعدة فورًا", sourceUrl: SRC.aapAnaphylaxis,
    body: "لو بعد أكل أو أي حاجة جديدة ظهر تورم في الشفايف أو اللسان، أو صعوبة في النفس أو البلع، اطلبي المساعدة فورًا.",
  },
  {
    id: "tip-allergy-3", category: "allergy", title: "الأكلات المشهورة بالحساسية", sourceUrl: SRC.aapAllergens, ageFromMonths: 6, ageToMonths: 12,
    body: "اسألي الدكتور إمتى وإزاي تقدّمي البيض والفول السوداني والسمسم ومنتجات اللبن، خصوصًا لو طفلك عنده إكزيما شديدة.",
  },
  {
    id: "tip-vaccines", category: "vaccines", title: "كارت التطعيم معاكي دايمًا", sourceUrl: SRC.mohp2025,
    body: "خدي كارت التطعيم في كل زيارة، والتطعيمات الإجبارية مجانًا في وحدات الصحة.",
  },
  {
    id: "tip-vaccines-2", category: "vaccines", title: "بعد التطعيم", sourceUrl: SRC.aapVaccineReactions,
    body: "شوية سخونية أو احمرار مكان الحقنة ممكن يحصلوا يوم أو اتنين. كلمي الدكتور لو الحرارة ٤٠ أو أكتر، أو لو طفلك أقل من ٣ شهور وسخن.",
  },
  {
    id: "tip-newborn", category: "newborn", title: "الحضن جلد لجلد", sourceUrl: SRC.whoNewborn, ageFromMonths: 0, ageToMonths: 2,
    body: "حطي المولود على صدرك جلد لجلد. بيدفّيه وبيساعده يرضع.",
  },
  {
    id: "tip-newborn-2", category: "newborn", title: "السُّرّة نضيفة وناشفة", sourceUrl: SRC.aapCord, ageFromMonths: 0, ageToMonths: 1,
    body: "سيبي السُّرّة نضيفة وناشفة، واطوي البامبرز تحتها، ومتحطيش عليها حاجة. لو لسه موجودة بعد ٣ أسابيع، أو فيه احمرار أو صديد، كلمي الدكتور.",
  },
];

/**
 * WHO growth standards medians by month (weight kg, length/height cm, head cm), boys and girls.
 * Values are approximate medians from the WHO tables; demo measurements vary slightly around them.
 */
export const WHO_MEDIANS: Record<"male" | "female", [number, number, number, number][]> = {
  // [month, weight, length, head]
  male: [
    [0, 3.3, 49.9, 34.5], [1, 4.5, 54.7, 37.3], [2, 5.6, 58.4, 39.1], [3, 6.4, 61.4, 40.5], [4, 7.0, 63.9, 41.6],
    [6, 7.9, 67.6, 43.3], [9, 8.9, 72.0, 44.9], [12, 9.6, 75.7, 46.1], [18, 10.9, 82.3, 47.4], [24, 12.2, 87.8, 48.3],
    [36, 14.3, 96.1, 49.5], [48, 16.3, 103.3, 50.2],
  ],
  female: [
    [0, 3.2, 49.1, 33.9], [1, 4.2, 53.7, 36.5], [2, 5.1, 57.1, 38.3], [3, 5.8, 59.8, 39.5], [4, 6.4, 62.1, 40.6],
    [6, 7.3, 65.7, 42.2], [9, 8.2, 70.1, 43.8], [12, 8.9, 74.0, 44.9], [18, 10.2, 80.7, 46.2], [24, 11.5, 86.4, 47.2],
    [36, 13.9, 95.1, 48.5], [48, 16.1, 102.7, 49.3],
  ],
};

/** Medians at [months], interpolated between table rows. */
export function medianAt(sex: "male" | "female", months: number): { weightKg: number; lengthCm: number; headCm: number } {
  const t = WHO_MEDIANS[sex];
  let lo = t[0], hi = t[t.length - 1];
  for (let i = 0; i < t.length - 1; i++) {
    if (t[i][0] <= months && months <= t[i + 1][0]) {
      lo = t[i];
      hi = t[i + 1];
      break;
    }
  }
  const f = hi[0] === lo[0] ? 0 : (months - lo[0]) / (hi[0] - lo[0]);
  const at = (k: 1 | 2 | 3) => lo[k] + (hi[k] - lo[k]) * f;
  return { weightKg: at(1), lengthCm: at(2), headCm: at(3) };
}

/** Fictional demo families (no real people). Numbers are test numbers on the emulators only. */
export interface DemoFamily {
  uid: string;
  phone: string;
  name: string;
  relation: "mother" | "father";
  clinicId: "clinic-1" | "clinic-2";
  children: { id: string; name: string; birthDate: string; sex: "male" | "female"; allergies?: string }[];
}

export const FAMILIES: DemoFamily[] = [
  {
    uid: "demo-g01", phone: "+201000000201", name: "هالة مصطفى", relation: "mother", clinicId: "clinic-1",
    children: [
      { id: "demo-adam", name: "آدم", birthDate: "2026-10-10", sex: "male" },
      { id: "demo-yasmin", name: "ياسمين", birthDate: "2023-02-14", sex: "female" },
    ],
  },
  { uid: "demo-g02", phone: "+201000000202", name: "أحمد سمير", relation: "father", clinicId: "clinic-2",
    children: [{ id: "demo-layan", name: "ليان", birthDate: "2025-06-05", sex: "female" }] },
  {
    uid: "demo-g03", phone: "+201000000203", name: "نادية فتحي", relation: "mother", clinicId: "clinic-1",
    children: [
      { id: "demo-yehia", name: "يحيى", birthDate: "2024-11-20", sex: "male" },
      { id: "demo-tia", name: "تيا", birthDate: "2022-09-09", sex: "female", allergies: "حساسية من البيض" },
    ],
  },
  { uid: "demo-g04", phone: "+201000000204", name: "رنا عادل", relation: "mother", clinicId: "clinic-1",
    children: [{ id: "demo-malek", name: "مالك", birthDate: "2026-04-12", sex: "male" }] },
  {
    uid: "demo-g05", phone: "+201000000205", name: "منة حسين", relation: "mother", clinicId: "clinic-2",
    children: [
      { id: "demo-jana", name: "جنى", birthDate: "2025-01-30", sex: "female" },
      { id: "demo-seif", name: "سيف", birthDate: "2023-08-18", sex: "male" },
    ],
  },
  { uid: "demo-g06", phone: "+201000000206", name: "محمود رشدي", relation: "father", clinicId: "clinic-2",
    children: [{ id: "demo-farida", name: "فريدة", birthDate: "2026-07-01", sex: "female" }] },
  { uid: "demo-g07", phone: "+201000000207", name: "دينا كمال", relation: "mother", clinicId: "clinic-1",
    children: [{ id: "demo-hamza", name: "حمزة", birthDate: "2024-05-25", sex: "male" }] },
  {
    uid: "demo-g08", phone: "+201000000208", name: "شيماء نبيل", relation: "mother", clinicId: "clinic-1",
    children: [
      { id: "demo-lojain", name: "لُجين", birthDate: "2025-09-15", sex: "female" },
      { id: "demo-anas", name: "أنس", birthDate: "2022-12-03", sex: "male" },
    ],
  },
  { uid: "demo-g09", phone: "+201000000209", name: "إيمان طارق", relation: "mother", clinicId: "clinic-2",
    children: [{ id: "demo-rayan", name: "ريان", birthDate: "2026-01-05", sex: "male" }] },
  { uid: "demo-g10", phone: "+201000000210", name: "مروة سعد", relation: "mother", clinicId: "clinic-2",
    children: [{ id: "demo-tamim", name: "تميم", birthDate: "2023-11-11", sex: "male" }] },
];
