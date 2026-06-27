namespace PillReminder;

public static class Phrases
{
    private static readonly Random _rng = new();

    private static readonly string[] _reminders =
    [
        "ALERT! ALERT! The Ministry of Silly Walks has officially declared it PILL O'CLOCK! I don't care HOW you walk to them, just GET THERE!",
        "Listen! Strange women lying in ponds distributing swords is no basis for a health plan — but PILLS ARE! Take them NOW, I command thee!",
        "TIS BUT A SCRATCH! said no responsible pill-taker ever. Get those pills down you, brave knight, before things escalate to 'just a flesh wound!'",
        "We are the Knights Who Say... PILL! And we demand a shrubbery... AFTER you take your medication! PILL FIRST! SHRUBBERY SECOND!",
        "NOBODY expects the Spanish Inquisition... but everybody expects YOU to take your pills! Our chief weapon is persistence! Take! Your! PILLS!",
        "I'm not dead yet! And you won't be either, provided you take your medication! Now stop arguing and get those pills down you!",
        "He's a very naughty boy! And he HASN'T TAKEN HIS PILLS! Don't be like Brian! Brian forgot! Don't be Brian!",
        "What is the airspeed velocity of an unladen swallow? African or European? Doesn't MATTER — take your pills FIRST and we'll sort out the swallows afterward!",
        "Brave Sir Robin ran away... but even Brave Sir Robin took his pills! Allegedly! The minstrel may have glossed over that part. PILL TIME!",
        "I am Arthur, King of the Britons! And I hereby decree by royal proclamation that ALL pills shall be consumed at this very moment! The coconuts can wait!",
        "RUN AWAY! Run away from your symptoms! The only weapon against the terrible beast is... your PILLS! Fetch the pills!",
        "SPAM! Spam spam spam spam! Spam pills spam! Wonderful pills! Except it is not spam — it is VERY IMPORTANT MEDICATION TIME!",
        "Always look on the bright side of life! *whistles cheerfully* Which is much easier to do after you have taken your PILLS! So take them! Now! Please!",
        "Tim the Enchanter has foreseen it! The pills must be taken! Ignore his warning and face the consequences of not taking your medication, which I assure you are quite nasty!",
        "Your mother was a hamster and your father smelt of elderberries! But more critically — IT IS PILL TIME! We shall taunt you a second time if you do not comply!",
        "A moose once bit my sister... but that is not the point. The point is IT IS PILL O'CLOCK! The moose agrees! TAKE YOUR MEDICATION!",
        "And now for something completely different... it is time for your PILLS! Which, come to think of it, is not that different from last time. Still! TAKE THEM!",
        "The Black Knight NEVER surrenders! And neither shall YOU surrender to your condition! Your sword is your medication! WIELD IT! Take! Those! PILLS!",
        "Bring out your pills! Bring out your pills! We're not dead yet — and with YOUR medication on schedule, we intend to keep it that way! PILLS! FORWARD!",
        "Strange women lying in ponds may not distribute pills, but I AM distributing this reminder! The Lady of the Lake commands you: TAKE THEM!",
        "On second thought, let's NOT forget the pills. 'Tis a silly thing to do! Get them down you, and we shall say no more about the shrubbery incident.",
        "Dennis! Come see the medication not being taken! Help! Help! I'm being ignored by my own pill bottle! This is what happens when you skip doses, you see!",
        "Message for you, sir! MESSAGE FOR YOU, SIR! From the Castle of Your Doctor: TAKE YOUR PILLS IMMEDIATELY! The castle demands it!",
        "What have the Romans ever done for us? Well, modern medicine, sanitation, roads, aqueducts... and your PILLS. Which you should be taking RIGHT NOW!",
        "The Larch. The Larch. How to take your pills. Step one: open the bottle. Step two: take the pills. Step three: feel magnificent. TAKE THEM NOW!",
        "We're the People's Front of Medication Reminders! WHAT have we done for the patient? We REMIND them, every single time! It is our sacred duty!",
        "Ooh, I feel happy! I feel happy! That is because the previous patient took their pills on time. Be like that patient! Take yours! HAPPINESS AWAITS!",
        "This is an EX-excuse! Your excuse for not taking your pills has CEASED TO BE! It has expired and gone to meet its maker! TAKE! YOUR! MEDICATION!",
        "Camelot! It's only a model — but your HEALTH is real! And real health requires real pills taken at real times! Which is RIGHT NOW! Onward, brave pill-taker!",
        "Fetchez la pilule! FETCHEZ LA PILULE! Go and fetch the sacred medication from its vessel! The French taunting can wait — your health cannot!",
        "I didn't vote for this pill reminder! You don't VOTE for pill reminders! But your doctor prescribed this medication, and supreme executive health demands compliance!",
        "Strange, isn't it, how every day at this hour a magical voice appears to tell you to take your medication? Some would call it enchanted. I call it PILL O'CLOCK.",
        "Sir Galahad the Pure must remain pure of MISSED DOSES! Even he paused his quest for the Holy Grail to take his medication. Follow his noble example!",
        "Patsy! Are you SURE we can't stop for pills? King Arthur paused his coconut clapping to inform you: PILL O'CLOCK HAS ARRIVED. The kingdom depends upon it!",
        "We interrupt this quest for the Holy Grail to bring you a CRITICAL ANNOUNCEMENT: The God of Abraham commands thee — TAKE THY PILLS! He's not angry, just disappointed.",
    ];

    private static readonly string[] _acknowledgments =
    [
        "Splendid! The brave knight has consumed the sacred medication! King Arthur himself would be proud! Now hear ye the news from the realm...",
        "Excellent! The Black Knight's symptoms may nip at your heels, but YOUR PILLS ARE TAKEN! Victory! Onward to the news...",
        "Right, that's settled then! No more 'tis but a scratch' for you today. Well done! Now let us consult the oracles of news and weather...",
        "BRILLIANT! A shrubbery! No wait — better than a shrubbery: you took your pills! Now for today's briefing from the kingdom...",
        "And there was much rejoicing! The pills have been taken! Now let us see what chaos the outside world has managed today...",
        "We are no longer the knights who say NIH — we are the knights who say WELL DONE! Pills consumed! Now for the news...",
    ];

    public static string PickReminder(string malady)
    {
        var phrase = _reminders[_rng.Next(_reminders.Length)];
        if (!string.Equals(malady, "Parkinson's", StringComparison.OrdinalIgnoreCase))
            phrase = phrase.Replace("Parkinson's", malady, StringComparison.Ordinal);
        return phrase;
    }

    public static string PickAcknowledgment() =>
        _acknowledgments[_rng.Next(_acknowledgments.Length)];
}
