# Endless Subway

لعبة رعب وغموض على روبلوكس: ركاب محبوسين في مترو بيلف في نفس المحطة.
القاعدة: **لو المحطة طبيعية ← كمّل. لو فيها حاجة غلط ← ارجع.**

النسخة دي هي خطوة 1 و 2 من خطة التنفيذ في الـ pitch، يعني نسخة بتتلعب:

- **Lobby:** صالة تذاكر فيها 6 بوابات. تقف على بوابة مع صحابك، وأول واحد يقف هو الـ host: بيختار عدد اللاعبين (من 1 لـ 10) واللغة (عربي أو English).
- **كل مجموعة ليها محطة لوحدها:** بتتبني بلغة المجموعة دي بس. الـ lobby نفسه دايمًا English.
- **نظام المحطات والتصويت:** محطة طولها 200 stud، فيها قطر من 3 عربيات، باب "كمّل" وباب "ارجع"، عداد محطات، وتصويت الأغلبية.
- **نظام الـ anomalies:** كل anomaly في ModuleScript لوحده فيه `Apply` و `Reset`. فيه 10 جاهزين.
- **جرافيك مظلم:** إضاءة Future، ضباب، ألوان باهتة، لمبات بايظة، والركاب بيلبسوا avatars حقيقية عشوائية من روبلوكس.

## أسهل طريقة تجربها (من غير أي برامج زيادة)

1. نزّل ملف [`EndlessSubway.rbxlx`](EndlessSubway.rbxlx).
2. افتح Roblox Studio ← **File ← Open from File** واختار الملف.
3. دوس **Play**. الـ lobby بيتبني أوتوماتيك وهتلاقي نفسك فيه.
4. اقف على بوابة. لو بتجرب لوحدك: دوس **Start now** (أو خلي العدد 1).

> في وضع التعديل (قبل Play) الـ Workspace هيبان فاضي. ده طبيعي: الكود هو اللي بيبني كل حاجة.

**تجربة الـ Multiplayer:** من تبويب **Test** اختار **Clients and Servers** وعدد لاعبين 2 أو 3، ودوس Start.

## الـ Lobby

- اقف على بوابة عشان تدخل مجموعتها، وانزل من عليها عشان تخرج.
- أول واحد على البوابة هو الـ host: بيختار **Group size** (من 1 لـ 10) و **Language** (العربية / English)، وممكن يدوس **Start now** من غير ما يستنى.
- لما البوابة تتملي (أو الـ host يدوس Start now) بيبدأ عد 5 ثواني، وبعدها المجموعة كلها بتروح محطتها.
- لو البوابة مليانة، دوّر على بوابة تانية.
- جوه اللعبة فيه زرار **ارجع للوبي / Back to lobby**.

## إزاي بتتلعب

1. القطر بيقف والأبواب بتفتح. انزلوا على الرصيف وبصّوا على كل حاجة.
2. كل لاعب يقف على المنطقة الملونة قدام الباب اللي عايزه (أخضر = كمّل، أحمر = ارجع).
3. لما الكل يقف وتبقى فيه أغلبية واضحة، بيبدأ عد تنازلي 3 ثواني. لو حد اتحرك العد بيبطل.
   - تعادل؟ لازم تتفقوا. بعد 45 ثانية القرعة بتختار.
4. صح ← العداد يزيد. غلط ← العداد يرجع صفر (أول الـ Level).
5. 5 محطات صح = Level خلص. فيه 3 Levels. بعد آخر Level بترجعوا للـ lobby.

أول محطة في كل Level دايمًا طبيعية، عشان تحفظوا شكل المحطة.

## الـ 10 anomalies

| الملف | اللي بيتغير |
|---|---|
| `StoppedClock` | الساعة واقفة ومش بتعد |
| `MissingPassenger` | راكب من الركاب اختفى |
| `NamedPoster` | إعلان عليه اسم لاعب من اللاعبين |
| `ExtraPassenger` | شخص أسود من غير ملامح واقف ووشه للحيطة |
| `FlickeringLight` | لمبة في السقف بتنور وتطفي |
| `WrongLineNumber` | رقم الخط مكتوب 41 بدل 14 |
| `MissingPillar` | عمود من الأعمدة مش موجود |
| `TurnedBench` | الكرسي الفاضي متلف ناحية الحيطة |
| `ExtraMissedCall` | الموبايل اللي على الأرض بقى فيه 13 مكالمة فايتة بدل 12 |
| `StaringPassengers` | كل الركاب بيلفوا راسهم ويبصّوا عليك |

والتلميحات بتاعة القصة موجودة في المحطة الطبيعية: جرنال تاريخه بكرة، ورد جنب العمود، وموبايل فيه "12 مكالمة فايتة".

## إضافة anomaly جديد (في دقايق)

اعمل ModuleScript جديد جوه `ServerScriptService/Server/Anomalies` (أو ملف `.luau` جديد في `src/server/Anomalies`):

```lua
-- اسم المحطة بقى مكتوب غلط.
return {
	Name = "WrongStationName",
	Apply = function(ctx)
		ctx:Set(ctx.Refs.StationName, "Text", "محطة النوم")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
```

اللعبة بتلاقيه لوحدها. لو فيه كلام، حطه في `src/shared/Strings.luau` بالعربي والإنجليزي واستخدم `ctx:Text("Key")`. أي تغيير بتعمله عن طريق `ctx` بيترجع زي ما كان أوتوماتيك في `ctx:Restore()`:

- `ctx:Set(instance, "Property", value)`: غيّر خاصية (و `Parent = nil` بيخفي الحاجة)
- `ctx:SetAttribute(instance, "Name", value)`
- `ctx:Pivot(model, cframe)`: حرّك Model
- `ctx:Add(instance)`: ضيف حاجة جديدة (بتتمسح بعد المحطة)
- `ctx:Connect(signal, fn)` و `ctx:Spawn(fn)`: لأي حاجة بتتحرك باستمرار
- `ctx:Pick(list)`: اختيار عشوائي

الحاجات اللي ممكن تغيّرها موجودة في `ctx.Refs`: `Lights`, `Posters`, `Passengers`, `Benches`, `Pillars`, `Clock`, `ClockLabel`, `LineBadge`, `StationName`, `PhoneLabel`, `NewspaperLabel`. و `ctx.Refs.At(x, y, z)` بيحوّل مكان في المحطة لمكان في العالم.

## الإعدادات

كل الأرقام في `src/shared/Config.luau`: عدد المحطات في الـ Level، نسبة ظهور الـ anomalies، وقت التصويت، عدد البوابات وأقل وأكبر عدد لاعبين، وإضاءة كل Level.
لو عايز الركاب بالشكل البسيط بدل الـ avatars: خلي `Config.RandomAvatarNpcs = false`.

**عدد اللاعبين في السيرفر:** كل المجموعات في نفس السيرفر. لو عايز أكتر من الحد الافتراضي، غيّره من Game Settings في Studio بعد ما تعمل Publish.
خلي `Config.Debug = true` وانت بتجرب، وهيكتب في الـ Output اسم الـ anomaly اللي في المحطة.

## للمطورين (Rojo)

```sh
rojo serve                                       # sync مباشر مع Studio
rojo build default.project.json -o EndlessSubway.rbxlx   # بعد أي تعديل، عشان الملف الجاهز يتحدّث
```

```
src/
  shared/   Config, Net, Strings (AR/EN)      → ReplicatedStorage.Shared
  server/   Main, Graphics,                   → ServerScriptService.Server
            LobbyBuilder, LobbyManager,       (اللوبي والبوابات)
            SessionManager, GameLoop,         (محطة ولوب لكل مجموعة)
            MapBuilder, Build, Npc, Mannequin,
            VoteManager, AnomalyContext,
            AnomalyRegistry, Anomalies/*
  client/   HUD                               → StarterPlayerScripts.Client
```

## اللي لسه (خطوات 3 لـ 5 في الخطة)

- **3. الانتقال بين الـ Levels:** دلوقتي Level 2 و 3 بيغيروا الإضاءة بس. لسه مشهد الحادثة، والمحطة المتكسرة، والظل، والمحطة الغرقانة، والحيطة التذكارية في النهاية.
- **4. الجو:** أصوات، إعلان المحطة، jumpscares.
- **5. المحتوى والنشر:** لحد 30 anomaly، Badges، Thumbnail.
