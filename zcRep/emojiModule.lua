-- youll never guess what this does
local EmojiModule = {}


EmojiModule.EmojiMap = {
	[":skull:"] = "💀",
	[":sob:"] = "😭",
	[":smile:"] = "😄",
	[":laugh:"] = "😂",
	[":cry:"] = "😢",
	[":fire:"] = "🔥",
	[":thumbsup:"] = "👍",
	[":thumbsdown:"] = "👎",
	[":heart:"] = "❤️",
	[":heartbreak:"] = "💔",
	[":star:"] = "⭐",
	[":sparkles:"] = "✨",
	[":eyes:"] = "👀",
	[":clown:"] = "🤡",
	[":100:"] = "💯",
	[":ok:"] = "👌",
	[":wave:"] = "👋",
	[":think:"] = "🤔",
	[":sunglasses:"] = "😎",
	[":sleep:"] = "😴",
	[":zzz:"] = "💤",
	[":angry:"] = "😠",
	[":pensive:"] = "😔",
	[":rage:"] = "😡",
	[":astonished:"] = "😲",
	[":grimace:"] = "😬",
	[":wink:"] = "😉",
	[":blush:"] = "😊",
	[":neutral:"] = "😐",
	[":expressionless:"] = "😑",
	[":sweat:"] = "😅",
	[":weary:"] = "😩",
	[":plead:"] = "🥺",
	[":pray:"] = "🙏",
	[":joy:"] = "😂",
	[":cool:"] = "😎",
	[":poop:"] = "💩",
	[":robot:"] = "🤖",
	[":warning:"] = "⚠️",
	[":check:"] = "✅",
	[":x:"] = "❌",
	[":question:"] = "❓",
	[":exclamation:"] = "❗",
	[":lightbulb:"] = "💡",
	[":rocket:"] = "🚀",
	[":gem:"] = "💎",
	[":isreal:"] = "🇮🇱",
	[":evil:"] = "😈",
}


function EmojiModule.ReplaceCodes(text)
	for code, emoji in pairs(EmojiModule.EmojiMap) do
		text = text:gsub(code, emoji)
	end
	return text
end

return EmojiModule
