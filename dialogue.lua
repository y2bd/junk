local Dialogue = {}

Dialogue.lines = {
    "hey there.     \n\nwelcome to the factory, kid.                 ",
    "have you done this before?          \n\nthe other kids say it's like \n\nsome old video game.                   ",
    "you know,        \n\n'left' and 'right' to move,        \n\n'z' and 'x' to spin,                         ",
    "'down' to lower the thing,         \n\nand 'up' to just drop it.                             ",
    "it's pretty simple.           ",
    "and thanks to the union,         \n\nshifts are only two minutes long.                      ",
    "i'll let you get right to it then,             ",
    "...                                   ",
    "wait a sec,            \n\nforgot to mention,           ",
    "the last person we got in  \n\nmade a whole mess of things.          ",
    "what was their name again,                   \n\n",
    "yeah that's right.           \n\nabsolutely horrible,    \n\nknocking everything over.            ",
    "a lot of their junk  \n\nis still lying around....        \n\nso...              ",
    "if you could clean \n\nthat up as well             \n\nit would be great, thanks.              ",
    "see ya at lunch.                                   ",
    "<beginning in \n\n   3...          \n\n        2...    \n\n             1...>               ",
}

Dialogue.nameLine = 11

Dialogue.outroBad = {
    "hey!                          ",
    "the heck is this?       \n\ni swear, things look worse    \n\nthan before.                    ",
    "and it's only been  \n\ntwo minutes!               ",
    "look,     \n\ni know you're new but  \n\nyou gotta try harder  \n\nthan this.                      ",
    "ugh, this is yesterday  \n\nall over again...                        ",
    "<face burying noises>                          ",
    "anyway,                 ",
    "i need to fill out \n\npaperwork...                 ",
    "what's your name again?                       ",
};

Dialogue.outroLazy = {
    "alright, lunch time!                          ",
    "you touch anything else \n\nand we'll have  \n\nthe union on our asses!                 ",
    "so what's up?      \n\nheard you were doing pretty well  \n\nfrom some other employees.                   ",
    "it's great that you acclimated  \n\nso quickly to the work.              ",
    "however...                        ",
    "there's still quite a lot of junk...            \n\nand some of it even looks new...               ",
    "next time, make sure to balance  \n\nyour priorities.                 ",
    "<wistful sighing>                        ",
    "by the way,                 ",
    "sorry, i don't actually \n\nknow your name.                       ",
};

Dialogue.outroGood = {
    "hey, lunch time!                          ",
    "you touch anything else \n\nand we'll have  \n\nthe union on our asses!                 ",
    "wow, i'm actually impressed.          \n\nyou did better than I hoped.             ",
    "like I said before, \n\nthere's so much junk  \n\nthat we spend more time cleaning  \n\nthan assembling.           ",
    "so thanks for getting rid of  \n\na lot of it.              ",
    "i think in due time,       \n\nyou'll be one of the \n\nbest people 'round here.                    ",
    "<soft applause>                            ",
    "by the way,                  ",
    "i didn't actually get your name.                       ",
};


Dialogue.outroGreat = {
    "ding ding, lunch time!                          ",
    "you touch anything else \n\nand we'll have  \n\nthe union on our asses!                 ",
    "wow, i'm really impressed.          \n\nyou did fantastic.             ",
    "like I said before, \n\nthere's so much junk \n\nthat we spend more time cleaning  \n\nthan assembling.        ",
    "so thanks for getting rid of \n\na ton of it.              ",
    "you sure you haven't \n\ndone this work before?          \n\nyou ain't one of them \n\nSRS inspection agents  \n\ni've been hearin about are ya?                 ",
    "<vigorous questioning>                     ",
    "just kidding of course.          \n\nthanks,          \n\nreally.            ",
    "by the way,                 ",
    "what's your name, friend?                       ",
};

Dialogue.speak = function(args)
    local text = args[1]
    local maxLine = args[2]
    local base = args[3]

    for delay=1,10 do
        args = coroutine.yield({ text, maxLine, base })
        base = args[3]
    end

    local textIndex = 1
    local lineIndex = 1

    while textIndex < #text do
        local val = string.sub(text, textIndex, textIndex)
        base = base .. string.sub(text, textIndex, textIndex)

        for delay=1,2 do
            args = coroutine.yield({ text, maxLine, base })
            base = args[3]
        end

        textIndex = textIndex + 1
    end

    return text, maxLine, text
end

return Dialogue