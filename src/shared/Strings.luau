-- Every piece of in-game text, in Arabic and English. The lobby is always English; each group's
-- host picks the language of their own session (station signs, posters, HUD, messages).
--
-- Strings.get(language, key, ...) formats the text with string.format when arguments are given.

export type Language = "ar" | "en"

local TEXT: { [string]: { [string]: any } } = {
	en = {
		-- Station
		StationName = "Al-Nour Station",
		DoorContinue = "CONTINUE",
		DoorBack = "GO BACK",
		Counter = "LEVEL\n%d / %d",
		Newspaper = "METRO DAILY\n%s",
		MissedCalls = "%d missed calls",
		Vending = "DRINKS",
		NamedPoster = "%s\nDon't miss your stop",
		Posters = {
			"SPEED ENERGY\nFor the last train",
			"AL-NOUR HOMES\nPay over 10 years",
			"MESHWAR APP\nYour ride is on us",
			"METRO MUSEUM\nOpening soon",
			"LINE 14\nWe never stop",
			"NIGHT PHARMACY\nOpen 24 hours",
			"LOST SOMEONE?\nCall 14 14 14",
		},
		Months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" },

		-- HUD
		Rule = "Normal station -> CONTINUE.  Something wrong -> GO BACK.",
		RuleFirst = "The first station is always safe. Look around, then go to CONTINUE.",
		TutorialTitle = "How to play",
		TutorialBody = table.concat({
			"The train keeps stopping at the same station.",
			"Look at everything: the clock, the signs, the passengers, the benches...",
			"If you find something different (a stopped clock, a missing passenger, a wrong number), there is a problem: go to GO BACK.",
			"If everything is normal: go to CONTINUE.",
			"This first station is always safe. Remember how it looks.",
		}, "\n\n"),
		TutorialHorrorTitle = "Careful...",
		TutorialHorrorBody = table.concat({
			"From here the station gets dark, and stranger things happen.",
			"If a dark figure walks toward you, run (hold Shift, or tap Sprint). If it touches you, you die and watch your friends.",
			"If the whole group dies, everyone goes back to Level 1.",
		}, "\n\n"),
		TutorialOk = "Got it",
		PhaseCalm = "The Last Train",
		PhaseHorror = "Something Is Wrong",
		HudLevel = "Level %d / %d",
		HudCheckpoint = "Checkpoint: Level %d",
		Sprint = "Sprint",
		Walk = "Walk",
		VoteContinue = "Continue: %d",
		VoteBack = "Go back: %d",
		VoteTie = "Tie! You need a majority",
		VoteCountdown = "Deciding in %d...",
		VoteStandAtDoor = "Stand in front of the door you choose",
		VoteWaiting = "Waiting for the others (%d / %d)",
		LeaveRun = "Back to lobby",
		LeaveConfirm = "Press L again to go back to the lobby",

		-- Messages
		CoinFlip = "Tie... a coin flip chose \"%s\"",
		Wrong = "Wrong... back to Level %d",
		CheckpointReached = "CHECKPOINT! Mistakes now send you back to Level %d",
		HorrorBegins = "The lights are going out... something is wrong",
		Wiped = "Everyone is dead... back to Level 1",
		Spectating = "You died. Watching %s",
		SpectateHint = "Waiting until the whole group is gone",
		Ending = "You reached the end... (the final scene is still being built)",
	},

	ar = {
		StationName = "محطة النور",
		DoorContinue = "كمّل",
		DoorBack = "ارجع",
		Counter = "LEVEL\n%d / %d",
		Newspaper = "جريدة المترو\n%s",
		MissedCalls = "%d مكالمة فايتة",
		Vending = "مشروبات",
		NamedPoster = "%s\nمتنساش تنزل هنا",
		Posters = {
			"مشروب سبيد\nطاقة لآخر الليل",
			"شقق النور\nقسّط على 10 سنين",
			"تطبيق مشوار\nمشوارك علينا",
			"متحف المترو\nافتتاح قريبًا",
			"الخط 14\nإحنا مبنقفش",
			"صيدلية الليل\nمفتوحة 24 ساعة",
			"فقدت حد؟\nكلمنا 14 14 14",
		},
		Months = { "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر" },

		Rule = "المحطة طبيعية ← كمّل.  فيها حاجة غلط ← ارجع.",
		RuleFirst = "أول محطة دايمًا أمان. بص حواليك، وبعدين روح لباب كمّل.",
		TutorialTitle = "إزاي تلعب",
		TutorialBody = table.concat({
			"القطر بيفضل يقف في نفس المحطة كل مرة.",
			"بص على كل حاجة: الساعة، واللافتات، والركاب، والكراسي...",
			"لو لقيت حاجة مختلفة (ساعة واقفة، راكب ناقص، رقم غلط) يبقى فيه مشكلة: روح لباب ارجع.",
			"لو كل حاجة طبيعية: روح لباب كمّل.",
			"أول محطة دي دايمًا أمان. احفظ شكلها.",
		}, "\n\n"),
		TutorialHorrorTitle = "خلي بالك...",
		TutorialHorrorBody = table.concat({
			"من هنا المحطة بتضلم، وبتحصل حاجات أغرب.",
			"لو شخص أسود مشي ناحيتك، اجري (دوس Shift، أو زرار جري). لو لمسك هتموت وتتفرج على صحابك.",
			"لو المجموعة كلها ماتت، كلكم بترجعوا لـ Level 1.",
		}, "\n\n"),
		TutorialOk = "فهمت",
		PhaseCalm = "آخر قطر",
		PhaseHorror = "فيه حاجة غلط",
		HudLevel = "Level %d / %d",
		HudCheckpoint = "نقطة الحفظ: Level %d",
		Sprint = "جري",
		Walk = "مشي",
		VoteContinue = "كمّل: %d",
		VoteBack = "ارجع: %d",
		VoteTie = "تعادل! لازم أغلبية",
		VoteCountdown = "القرار خلال %d…",
		VoteStandAtDoor = "اقف قدام الباب اللي تختاره",
		VoteWaiting = "مستنيين الباقيين (%d / %d)",
		LeaveRun = "ارجع للوبي",
		LeaveConfirm = "دوس L تاني عشان ترجع للوبي",

		CoinFlip = "تعادل… القرعة اختارت \"%s\"",
		Wrong = "غلط… رجعتوا لـ Level %d",
		CheckpointReached = "Checkpoint! لو غلطتوا من هنا هترجعوا لـ Level %d",
		HorrorBegins = "النور بيطفي… فيه حاجة غلط",
		Wiped = "كلكم متّوا… رجعتوا لـ Level 1",
		Spectating = "انت مت. بتتفرج على %s",
		SpectateHint = "مستني لحد ما المجموعة كلها تموت",
		Ending = "وصلتوا للنهاية… (المشهد الأخير لسه بيتبني)",
	},
}

local Strings = {}

function Strings.normalize(language: any): Language
	return if language == "ar" then "ar" else "en"
end

function Strings.get(language: any, key: string, ...: any): any
	local value = TEXT[Strings.normalize(language)][key]
	if value == nil then
		value = TEXT.en[key]
	end
	if value == nil then
		return key
	end
	if select("#", ...) > 0 then
		return string.format(value, ...)
	end
	return value
end

-- Tomorrow's date, written the way the language writes dates.
function Strings.tomorrow(language: any): string
	local date = os.date("*t", os.time() + 24 * 60 * 60)
	local month = Strings.get(language, "Months")[date.month]
	if Strings.normalize(language) == "ar" then
		return string.format("%d %s %d", date.day, month, date.year)
	end
	return string.format("%s %d, %d", month, date.day, date.year)
end

return Strings
