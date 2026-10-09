# Endless Subway

لعبة رعب وغموض على روبلوكس: ركاب محبوسين في مترو بيلف في نفس المحطة.
القاعدة: **لو المحطة طبيعية ← كمّل. لو فيها حاجة غلط ← ارجع.**

النسخة دي هي خطوة 1 و 2 من خطة التنفيذ في الـ pitch، يعني نسخة بتتلعب:

- **نظام المحطات والتصويت:** عربية مترو ورصيف، باب "كمّل" وباب "ارجع"، عداد محطات، وتصويت الأغلبية.
- **نظام الـ anomalies:** كل anomaly في ModuleScript لوحده فيه `Apply` و `Reset`. فيه 10 جاهزين.

## أسهل طريقة تجربها (من غير أي برامج زيادة)

1. نزّل ملف [`EndlessSubway.rbxlx`](EndlessSubway.rbxlx).
2. افتح Roblox Studio ← **File ← Open from File** واختار الملف.
3. دوس **Play**. الماب كلها بتتبني أوتوماتيك أول ما اللعبة تشتغل، فهتلاقي نفسك جوه القطر.

> في وضع التعديل (قبل Play) الـ Workspace هيبان فاضي. ده طبيعي: الكود هو اللي بيبني المحطة.

**تجربة الـ Multiplayer:** من تبويب **Test** اختار **Clients and Servers** وعدد لاعبين 2 أو 3، ودوس Start.

## إزاي بتتلعب

1. القطر بيقف والأبواب بتفتح. انزلوا على الرصيف وبصّوا على كل حاجة.
2. كل لاعب يقف على المنطقة الملونة قدام الباب اللي عايزه (أخضر = كمّل، أحمر = ارجع).
3. لما الكل يقف وتبقى فيه أغلبية واضحة، بيبدأ عد تنازلي 3 ثواني. لو حد اتحرك العد بيبطل.
   - تعادل؟ لازم تتفقوا. بعد 45 ثانية القرعة بتختار.
4. صح ← العداد يزيد. غلط ← العداد يرجع صفر (أول الـ Level).
5. 5 محطات صح = Level خلص. فيه 3 Levels.

أول محطة في كل Level دايمًا طبيعية، عشان تحفظوا شكل المحطة.

## الـ 10 anomalies

| الملف | اللي بيتغير |
|---|---|
| `StoppedClock` | الساعة واقفة ومش بتعد |
| `MissingPassenger` | راكب من الركاب اختفى |
| `NamedPoster` | إعلان عليه اسم لاعب من اللاعبين |
| `ExtraPassenger` | راكب زيادة واقف ووشه للحيطة |
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

اللعبة بتلاقيه لوحدها. أي تغيير بتعمله عن طريق `ctx` بيترجع زي ما كان أوتوماتيك في `ctx:Restore()`:

- `ctx:Set(instance, "Property", value)`: غيّر خاصية (و `Parent = nil` بيخفي الحاجة)
- `ctx:SetAttribute(instance, "Name", value)`
- `ctx:Pivot(model, cframe)`: حرّك Model
- `ctx:Add(instance)`: ضيف حاجة جديدة (بتتمسح بعد المحطة)
- `ctx:Connect(signal, fn)` و `ctx:Spawn(fn)`: لأي حاجة بتتحرك باستمرار
- `ctx:Pick(list)`: اختيار عشوائي

الحاجات اللي ممكن تغيّرها موجودة في `ctx.Refs`: `Lights`, `Posters`, `Passengers`, `Benches`, `Pillars`, `Clock`, `ClockLabel`, `LineBadge`, `StationName`, `PhoneLabel`, `NewspaperLabel`.

## الإعدادات

كل الأرقام في `src/shared/Config.luau`: عدد المحطات في الـ Level، نسبة ظهور الـ anomalies، وقت التصويت، وإضاءة كل Level.
خلي `Config.Debug = true` وانت بتجرب، وهيكتب في الـ Output اسم الـ anomaly اللي في المحطة.

## للمطورين (Rojo)

```sh
rojo serve                                       # sync مباشر مع Studio
rojo build default.project.json -o EndlessSubway.rbxlx   # بعد أي تعديل، عشان الملف الجاهز يتحدّث
```

```
src/
  shared/   Config, Net                       → ReplicatedStorage.Shared
  server/   Main, MapBuilder, GameLoop,       → ServerScriptService.Server
            VoteManager, AnomalyContext,
            AnomalyRegistry, Mannequin,
            Anomalies/*
  client/   HUD                               → StarterPlayerScripts.Client
```

## اللي لسه (خطوات 3 لـ 5 في الخطة)

- **3. الانتقال بين الـ Levels:** دلوقتي Level 2 و 3 بيغيروا الإضاءة بس. لسه مشهد الحادثة، والمحطة المتكسرة، والظل، والمحطة الغرقانة، والحيطة التذكارية في النهاية.
- **4. الجو:** أصوات، إعلان المحطة، jumpscares.
- **5. المحتوى والنشر:** لحد 30 anomaly، Badges، Thumbnail.
