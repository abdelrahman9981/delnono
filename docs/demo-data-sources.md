# Demo data sources

Sources for the researched demo data in `functions/scripts/demo_data.ts` (emulator seed, later the
D-43 demo). Checked on **26 Oct 2026**. Every medical item is seeded with `reviewStatus: "proposed"`
and its source URL, shows «مقترح · يراجعه الدكتور» in the dashboard, and must be approved by the
doctor before launch (see [launch-checklist.md](launch-checklist.md)). Prices change often; treat
them as approximate.

| What | Source | Date of source | Notes |
|---|---|---|---|
| Egyptian public holidays 2027 (none in Nov–Dec 2026) | https://holidaydb.com/guides/public-holidays/egypt/2027 | 2027 calendar | Lunar holidays (Eids, Mawlid, Hijri new year) may move by a day; confirm each official announcement. |
| Visit price, Cairo pediatric clinics (Moqattam 350–450 EGP) | https://www.vezeeta.com/ar/دكتور/اطفال-وحديثي-الولادة/المقطم | listing, undated | Seed: 400 EGP (Moqattam), 450 EGP (Nasr City). |
| Annual package price | — | — | **No public source found.** Seed: 4,000 / 4,500 EGP (about ten visits). Estimate for the doctor to set. |
| MOHP mandatory schedule (birth, 2, 4, 6, 9, 12, 18 months) | https://www.youm7.com/story/2025/5/26/جدول-تطعيمات-الأطفال-منذ-الولادة-وحتى-18-شهرًا-تفاصيل/6995920 | May 2025 | Hep B within 24 h, OPV zero dose, BCG, pentavalent 2/4/6 months. |
| Salk (IPV) at 2, 4 and 6 months | https://www.youm7.com/story/2025/11/16/الصحة-توضح-جداول-التطعيمات-الإجبارية-والإضافية-لحديثى-الميلاد-صور/7199401 | 16 Nov 2025 | MOHP update. |
| MMR 12 and 18 months, OPV 9/12/18 months, booster at 18 months, BCG within 15 days | https://gate.ahram.org.eg/News/3524751.aspx | 23 May 2022 | Older article; ages consistent with 2025 sources. |
| Rotavirus price (Rotarix 646, RotaTeq 631 EGP) | https://www.vetogate.com/5333728 | 24 Jan 2025 | Seed: 650 EGP. |
| Pneumococcal (~700 EGP/dose), chickenpox (~1,500 EGP), optional vaccines 700–3,700 EGP/dose | https://manassa.news/stories/31652 | 3 Jun 2026 | Chickenpox figure is a parent's estimate. Hepatitis A seeded at 750 EGP: estimate within this range. |
| Meningococcal (Nimenrix 1,275 EGP) | https://www.youm7.com/story/2024/6/7/وزارة-الصحة-تكشف-سعر-لقاح-الالتهاب-السحائى-وموعد-الحصول-عليه/6601191 | 7 Jun 2024 | May have risen. |
| Seasonal flu (322 EGP, season 2026/2027) | https://www.elbalad.news/7127226 | 2026 | Vacsera range 280–370 EGP. |
| Milestones by age (2, 4, 6, 9, 12, 15, 18 months; 2, 3 years) | https://www.cdc.gov/act-early/milestones/index.html (per-age pages, e.g. /2-months.html) | CDC 2022 checklists | Translated and shortened; a checklist for the doctor to review, not a screening tool. |
| General danger signs (cannot drink, vomits everything, convulsions, lethargic) and young infant signs | https://www.afro.who.int/sites/default/files/2017-06/chartbooklet.pdf ; Egypt IMCI booklet https://platform.who.int/docs/default-source/mca-documents/policy-documents/operational-guidance/EGY-CH-59-01-OPERATIONALGUIDANCE-eng-IMCI-Assessment-Booklet-2m-5yrs.pdf | WHO IMCI | Young-infant list summarised from the IMNCI chart; the doctor confirms thresholds. |
| Fever: under 3 months with 38 °C or more; 40 °C or more; stiff neck | https://www.healthychildren.org/English/health-issues/conditions/fever/pages/When-to-Call-the-Pediatrician.aspx | AAP | |
| Taking a temperature | https://www.healthychildren.org/English/health-issues/conditions/fever/Pages/How-to-Take-a-Childs-Temperature.aspx | AAP | Tip «إزاي تقيسي حرارة طفلك صح». |
| Safe sleep (back, firm flat surface, empty crib) | https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/A-Parents-Guide-to-Safe-Sleep.aspx | AAP | |
| Bedtime routine | https://www.healthychildren.org/English/healthy-living/sleep/Pages/Bedtime-Trouble.aspx | AAP | |
| Starting solids one at a time; reactions to watch | https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/starting-solid-foods.aspx | AAP | |
| No added salt or sugar under 2 | https://www.healthychildren.org/English/healthy-living/nutrition/Pages/We-Dont-Need-to-Add-Salt-to-Food.aspx | AAP | |
| Common allergens from about 6 months | https://www.healthychildren.org/English/healthy-living/nutrition/Pages/when-to-introduce-egg-peanut-butter-and-other-common-food-allergens-to-your-baby-food-allergy-prevention-tips.aspx | AAP | |
| Severe allergic reaction signs | https://www.healthychildren.org/English/health-issues/injuries-emergencies/pages/Anaphylaxis.aspx | AAP | |
| Mild reactions after vaccines | https://www.healthychildren.org/English/tips-tools/symptom-checker/Pages/symptomviewer.aspx?symptom=Immunization+Reactions | AAP | |
| Umbilical cord care | https://www.healthychildren.org/English/ages-stages/baby/bathing-skin-care/Pages/Umbilical-Cord-Care.aspx | AAP | |
| Skin-to-skin contact, early exclusive breastfeeding | https://www.who.int/news-room/fact-sheets/detail/newborn-mortality | WHO | |
| Exclusive breastfeeding to 6 months, then complementary foods | https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding | WHO | Could not be fetched from the build environment on 26 Oct 2026; confirm the page. |
| Growth medians (weight, length/height, head circumference by month) | https://www.who.int/tools/child-growth-standards/standards | WHO Child Growth Standards | Approximate medians; demo measurements vary within a few percent. Values only, no judgments. |

Demo families, children, phone numbers (+2010000002xx, +2010000003xx) and walk-in names are
fictional. Clinic names, addresses and phone numbers in the seed are demo values for the doctor to
confirm.
