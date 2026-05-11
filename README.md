hi, i hope you're finding COMP0008 fun.

The point of this repo is to provide you (your agent) with nicely-formatted, comprehensive, and token-efficient
materials of COMP0008.  
With these, you can do stuff from asking directed questions to making the ai quiz you.

The intended usage is for you to clone this repo and boot up OpenCode / Claude Code / etc. on the directory.  
You could technically also copy all the stuff in `materials/` verbatim into the system prompt of a Claude web UI
"project" / Gemini web "Gem" / etc. if you're allergic to local tooling.  
`SLIDES_ALL.md` is only ~50k tokens! (yet contains ALL the lecture slides)

_It is recommended that you use a model with SotA long-context performance; this (exhaustively) includes:_

- Any GPT-5.x (NOT mini/nano; high / xhigh as applicable)
- Gemini 3.1 Pro (high)
- Opus 4.5 (max; 4.6 and 4.7 perform a bit worse, similar to Sonnet 4.6 / max)
- MiMo V2.5 Pro

Additionally, there are curated syllabuses that list all conceptual topics covered.  
`SYLLABUS.md` is probably the best. It has been iteratively curated.

The other syllabuses (with suffixes):

- `_c` -- `Opus 4.7 / max`'s one-shot try
- `_g` -- `Gemini 3.1 Pro / high`'s one-shot try
- `_d` -- `Deepseek v4 Pro / max`'s one-shot try

One good use case of the syllabus is to have the agent quiz you (or even teach you from scratch :skull:) over the entire
module.
