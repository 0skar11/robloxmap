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
		Counter = "Level %d\nStation %d / %d",
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
		HudStation = "Station %d / %d",
		VoteContinue = "Continue: %d",
		VoteBack = "Go back: %d",
		VoteTie = "Tie! You need a majority",
		VoteCountdown = "Deciding in %d...",
		VoteStandAtDoor = "Stand in front of the door you choose",
		VoteWaiting = "Waiting for the others (%d / %d)",
		LeaveRun = "Back to lobby",

		-- Messages
		CoinFlip = "Tie... a coin flip chose \"%s\"",
		Wrong = "Wrong... back to the start of the level",
		LevelUp = "Level %d - %s",
		Ending = "You reached the end... (the final scene is still being built)",
	},

	ar = {
		StationName = "محطة النور",
		DoorContinue = "كمّل",
		DoorBack = "ارجع",
		Counter = "Level %d\nالمحطة %d / %d",
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
		HudStation = "المحطة %d / %d",
		VoteContinue = "كمّل: %d",
		VoteBack = "ارجع: %d",
		VoteTie = "تعادل! لازم أغلبية",
		VoteCountdown = "القرار خلال %d…",
		VoteStandAtDoor = "اقف قدام الباب اللي تختاره",
		VoteWaiting = "مستنيين الباقيين (%d / %d)",
		LeaveRun = "ارجع للوبي",

		CoinFlip = "تعادل… القرعة اختارت \"%s\"",
		Wrong = "غلط… رجعتوا لأول الـ Level",
		LevelUp = "Level %d — %s",
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
