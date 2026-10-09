# Endless Subway

لعبة رعب وغموض على روبلوكس: ركاب محبوسين في مترو بيلف في نفس المحطة.
القاعدة: **لو المحطة طبيعية ← كمّل. لو فيها حاجة غلط ← ارجع.**

## اللي في اللعبة دلوقتي

- **Lobby منور:** صالة تذاكر فيها 6 بوابات، ودايمًا English.
- **مجموعات من 1 لـ 10:** أول واحد يقف على بوابة هو الـ host، وبيختار عدد اللاعبين واللغة (العربية / English) لمجموعته بس.
- **كل مجموعة في عالم لوحدها:** في اللعبة الحقيقية (بعد Publish)، البوابة بتنقل المجموعة لسيرفر خاص بيها. في Studio كله بيشتغل في سيرفر واحد، بس كل مجموعة ليها نسخة محطة لوحدها.
- **15 Level:**
  - **Level 1:** دايمًا أمان، مفيهوش أي anomaly، ومفيهوش باب "ارجع" أصلًا. الباب بيظهر من Level 2.
  - **Level 1 لـ 5:** محطة عادية منورة ومبهجة. فيها تغييرات بسيطة تدور عليها، ومفيش رعب.
  - **Level 5 = Checkpoint:** بيظهر على الشاشة. بعده لو غلطتوا بترجعوا لـ Level 6 مش Level 1.
  - **من Level 6:** النور بيطفي، والألوان بتبقى كئيبة (رمادي باهت)، والتلميحات بتظهر (الجرنال والورد والموبايل)، والحاجات المرعبة بتبدأ.
- **الراجل اللي في النص:** في كل محطة بيمشي ويدخل القطر ويقعد. ده جزء من الشكل الطبيعي.
- **الموت:** "The Follower" (شخص أسود من غير ملامح) بيمشي ناحيتك، ولو لمسك بتموت. اللي بيموت بيتفرج على صحابه، ولما المجموعة كلها تموت كلكم بترجعوا Level 1.
- **Tutorial** بلغة المجموعة لكل اللاعبين في Level 1 ("لو لقيت حاجة مختلفة يبقى فيه مشكلة")، وتاني لما الرعب يبدأ في Level 6.
- **الكاميرا:** third person في اللوبي، و first person جوه اللعبة من غير ماوس في نص الشاشة.
- **Shift** للجري على الكمبيوتر، وزرار **جري / مشي** على الموبايل.
- **كابينة السواق** في أول القطر: زجاج قدامي، وأنوار، ولوحة تحكم، وسواق قاعد.
- **شكل المترو الحقيقي (معمول بالـ Parts):**
  - **القطر من بره:** فضي، وسقفه مدوّر، وأبوابه دبل بشبابيك صغيرة، وشبابيك على طول جنبه.
  - **القطر من جوه:** كنب أزرق على الجنبين بمساند، وصفوف مقابض، وإعلانات، وباب في كل آخر. والممر واسع.
  - **المحطة:** بلاط فاتح، وشريط أصفر على الحرف، وكمرات في السقف بينها لوحات نور، وأعمدة بلونين، وكراسي معدن، وأنوار برتقاني في النفق.
- **الركاب ثابتين:** 6 أشكال اتختاروا عشوائي مرة واحدة واتحفظوا، فبيبقوا نفس الناس في كل لعبة وفي اللوبي. **والسواق لابس سكن DRG1YOUSSIF.**

## تجربها إزاي

1. نزّل [`EndlessSubway.rbxlx`](EndlessSubway.rbxlx).
2. افتحه في Roblox Studio: **File ← Open from File**.
3. دوس **Play**، واقف على بوابة. لو لوحدك: دوس **Start now**.

> قبل Play الـ Workspace هيبان فاضي. ده طبيعي: الكود هو اللي بيبني كل حاجة.

**تجربة مجموعة:** من تبويب **Test** اختار **Clients and Servers** بـ 2 أو 3 لاعبين.

**عشان كل مجموعة تروح سيرفر لوحدها:** اعمل **File ← Publish to Roblox** والعب من روبلوكس نفسه، مش من Studio. ولو عايز كله يفضل في سيرفر واحد، خلي `Config.UseSeparateServers = false`.

## التحكم

| | كمبيوتر | موبايل |
|---|---|---|
| جري | اضغط Shift باستمرار | زرار جري / مشي على الشاشة |
| الرجوع للوبي | دوس L مرتين | زرار "ارجع للوبي" |
| تحرير الماوس (first person) | Ctrl يحرره، و Ctrl تاني يقفله | - |
| تغيير اللي بتتفرج عليه (لو مت) | Q / E أو الأسهم | الأسهم |

## الـ anomalies

**بسيطة (من Level 1):**

| الملف | اللي بيتغير |
|---|---|
| `StoppedClock` | الساعة واقفة |
| `MissingPassenger` | راكب اختفى |
| `WrongLineNumber` | رقم الخط 41 بدل 14 |
| `MissingPillar` | عمود مش موجود |
| `TurnedBench` | كرسي فاضي متلف ناحية الحيطة |
| `MissingDriver` | مفيش سواق في الكابينة |

**مرعبة (من Level 6):**

| الملف | اللي بيحصل |
|---|---|
| `TheFollower` | شخص أسود بيمشي ناحيتك، ولو لمسك تموت |
| `StaringPassengers` | الركاب بيلفوا راسهم ويبصوا عليك |
| `FlickeringLight` | لمبة بتنور وتطفي |
| `ExtraPassenger` | شخص من غير ملامح واقف ووشه للحيطة |
| `NamedPoster` | إعلان عليه اسم واحد منكم |
| `ExtraMissedCall` | الموبايل بقى فيه 13 مكالمة فايتة بدل 12 |
| `BloodyWalker` | الراجل اللي في النص شكله مرعب: باهت، وغرقان دم، وعينيه حمرا |
| `WalkerJumpscare` | نفس الشكل المرعب، وبيجري عليك ويعملك jumpscare (مش بتموت) |

## إضافة anomaly جديد

اعمل ملف جديد في `src/server/Anomalies`:

```lua
return {
	Name = "WrongStationName",
	Horror = false, -- true = يظهر من Level 6 بس
	Apply = function(ctx)
		ctx:Set(ctx.Refs.StationName, "Text", "???")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
```

أي تغيير بتعمله عن طريق `ctx` بيرجع زي ما كان أوتوماتيك:

- `ctx:Set(instance, "Property", value)`
- `ctx:SetAttribute(instance, "Name", value)`
- `ctx:Pivot(model, cframe)`
- `ctx:Hide(model)`: يخفي حاجة من غير ما يمسحها
- `ctx:Add(instance)`: حاجة جديدة بتتمسح بعد المحطة
- `ctx:Connect(signal, fn)` و `ctx:Spawn(fn)`: لأي حاجة بتتحرك
- `ctx:Pick(list)`: اختيار عشوائي
- `ctx:Text("Key", ...)`: كلام بلغة المجموعة. الكلام نفسه في `src/shared/Strings.luau` بالعربي والإنجليزي.
- `ctx.Refs`: فيه `Lights`, `Posters`, `Passengers`, `Benches`, `Pillars`, `Clock`, `ClockLabel`, `LineBadge`, `StationName`, `PhoneLabel`, `NewspaperLabel`, `Driver`، و `At(x, y, z)` بيحوّل مكان في المحطة لمكان في العالم.

## الإعدادات (`src/shared/Config.luau`)

- **الـ Levels:** `TotalLevels` و `Checkpoints` و `HorrorStartsAtLevel` و `BackDoorFromLevel`.
- **الـ anomalies:** `AnomalyChance`، و `CalmAnomalies` (لو false، Level 1 لـ 5 مفيهاش أي تغيير خالص).
- **اللوبي:** `MinPartySize` و `MaxPartySize` و `LobbyPads`.
- **السيرفرات:** `UseSeparateServers`.
- **الحركة:** `WalkSpeed` و `SprintSpeed`.
- **الركاب:** `AvatarNpcs` (لو false، الركاب بالشكل البسيط). أشكالهم ثابتة في `src/server/NpcOutfits.luau`.
- **التجربة:** `Debug = true` بيكتب في Output اسم الـ anomaly اللي في كل محطة.

## للمطورين (Rojo)

```sh
rojo serve                                                # sync مباشر مع Studio
rojo build default.project.json -o EndlessSubway.rbxlx   # بعد أي تعديل
```

```
src/
  shared/  Config, Net, Strings (AR/EN)            → ReplicatedStorage.Shared
  server/  Main             يختار: سيرفر lobby ولا سيرفر لعب
           LobbyBuilder, LobbyManager    اللوبي والبوابات
           SessionManager                المجموعات، والنقل بين السيرفرات، والموت
           GameLoop, VoteManager         الـ Levels والتصويت
           MapBuilder, Build, Npc, Mannequin, Graphics
           AnomalyContext, AnomalyRegistry, Anomalies/*
  client/  HUD, Mood (الإضاءة), Sprint, Camera (والمشاهدة بعد الموت)   → StarterPlayerScripts.Client
```

## اللي لسه

- **الأصوات:** إعلان المحطة، وأصوات رعب، وjumpscares.
- **مشهد النهاية:** باب النور، والحيطة التذكارية بأسماء اللاعبين.
- **المحتوى:** anomalies أكتر (لحد 30)، وBadges، وThumbnail.
