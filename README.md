# Endless Subway

لعبة رعب وغموض على روبلوكس: ركاب محبوسين في مترو بيلف في نفس المحطة.
القاعدة: **لو المحطة طبيعية ← كمّل. لو فيها حاجة غلط ← ارجع.**

## اللي في اللعبة دلوقتي

- **Lobby منور:** صالة تذاكر فيها 6 بوابات، ودايمًا English.
- **مجموعات من 1 لـ 10:** أول واحد يقف على بوابة هو الـ host، وبيختار عدد اللاعبين واللغة (العربية / English) لمجموعته بس.
- **كل مجموعة في عالم لوحدها:** في اللعبة الحقيقية (بعد Publish)، البوابة بتنقل المجموعة لسيرفر خاص بيها. في Studio كله بيشتغل في سيرفر واحد، بس كل مجموعة ليها نسخة محطة لوحدها.
- **15 Level:**
  - **Level 1 لـ 5:** محطة عادية منورة ومبهجة. فيها تغييرات بسيطة تدور عليها، ومفيش رعب.
  - **Level 5 = Checkpoint:** بيظهر على الشاشة. بعده لو غلطتوا بترجعوا لـ Level 6 مش Level 1.
  - **من Level 6:** النور بيطفي، والتلميحات بتظهر (الجرنال والورد والموبايل)، والحاجات المرعبة بتبدأ.
- **الموت:** "The Follower" (شخص أسود من غير ملامح) بيمشي ناحيتك، ولو لمسك بتموت. اللي بيموت بيتفرج على صحابه، ولما المجموعة كلها تموت كلكم بترجعوا Level 1.
- **First person**، و **Shift** للجري على الكمبيوتر، وزرار **جري / مشي** على الموبايل.
- **قطر واسع:** أبواب عريضة، ومفيش أعمدة في النص.
- **الركاب** بيلبسوا avatars حقيقية عشوائية من روبلوكس.

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

**مرعبة (من Level 6):**

| الملف | اللي بيحصل |
|---|---|
| `TheFollower` | شخص أسود بيمشي ناحيتك، ولو لمسك تموت |
| `StaringPassengers` | الركاب بيلفوا راسهم ويبصوا عليك |
| `FlickeringLight` | لمبة بتنور وتطفي |
| `ExtraPassenger` | شخص من غير ملامح واقف ووشه للحيطة |
| `NamedPoster` | إعلان عليه اسم واحد منكم |
| `ExtraMissedCall` | الموبايل بقى فيه 13 مكالمة فايتة بدل 12 |

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
- `ctx:Add(instance)`: حاجة جديدة بتتمسح بعد المحطة
- `ctx:Connect(signal, fn)` و `ctx:Spawn(fn)`: لأي حاجة بتتحرك
- `ctx:Pick(list)`: اختيار عشوائي
- `ctx:Text("Key", ...)`: كلام بلغة المجموعة. الكلام نفسه في `src/shared/Strings.luau` بالعربي والإنجليزي.
- `ctx.Refs`: فيه `Lights`, `Posters`, `Passengers`, `Benches`, `Pillars`, `Clock`, `ClockLabel`, `LineBadge`, `StationName`, `PhoneLabel`, `NewspaperLabel`، و `At(x, y, z)` بيحوّل مكان في المحطة لمكان في العالم.

## الإعدادات (`src/shared/Config.luau`)

- **الـ Levels:** `TotalLevels` و `Checkpoints` و `HorrorStartsAtLevel`.
- **الـ anomalies:** `AnomalyChance`، و `CalmAnomalies` (لو false، Level 1 لـ 5 مفيهاش أي تغيير خالص).
- **اللوبي:** `MinPartySize` و `MaxPartySize` و `LobbyPads`.
- **السيرفرات:** `UseSeparateServers`.
- **الحركة:** `WalkSpeed` و `SprintSpeed`.
- **الركاب:** `RandomAvatarNpcs` (لو false، الركاب بالشكل البسيط).
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
  client/  HUD, Mood (الإضاءة), Sprint, Spectate   → StarterPlayerScripts.Client
```

## اللي لسه

- **الأصوات:** إعلان المحطة، وأصوات رعب، وjumpscares.
- **مشهد النهاية:** باب النور، والحيطة التذكارية بأسماء اللاعبين.
- **المحتوى:** anomalies أكتر (لحد 30)، وBadges، وThumbnail.
