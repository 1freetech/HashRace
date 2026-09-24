# Hash Race gameplay references from the Godot 2022 showreel

Updated September 15, 2026.

The source video is Godot Engine's **Desktop/Console 2022 Showreel**. It contains many games with very different genres, so Hash Race should not copy their art, characters, maps, names, story, interface, or unique mechanics. The useful material is limited to broad game-design patterns that strengthen a Bitcoin-mining company simulator.

Source showreel: https://www.youtube.com/watch?v=UAS_pUTFA7o

## Ideas worth adapting

### The Omins — direct priorities plus autonomous simulation

The Omins is a settlement strategy game where the player can issue direct orders while the population also handles needs and routine behavior on its own. Its current design also uses structured scenario objectives, eras, a readable top information bar, faction identity, and a faction journal. The important lesson for Hash Race is not to turn technicians into fantasy-style controllable villagers. The useful idea is to let the mining company keep operating automatically while the player gives **high-level operational priorities**, sees a clear objective, and keeps a history of major company events.

Hash Race adaptation now implemented:

- Site-wide operating priorities: Balanced, Efficiency, Reliability, and R&D.
- The company continues mining automatically underneath those choices.
- A season objective gives the player one clear near-term target without replacing the long game.
- A company journal records major milestones such as generations, partnerships, acquisitions, and season results.

References:
- https://store.steampowered.com/app/2397750/The_Omins/
- https://steamcommunity.com/app/2397750/allnews/
- https://temesagames.itch.io/the-omins

### Dome Keeper — readable tradeoffs and a repeatable decision rhythm

Dome Keeper alternates resource gathering with pressure and upgrades. Its upgrade paths work because the player can immediately understand what an upgrade changes and because some choices create meaningful tradeoffs rather than simply making every number better at once.

Hash Race adaptation now implemented:

- Each upcoming ASIC generation can use one lab focus: Balanced, Throughput, Efficiency, or Reliability.
- The focus changes the next generation's performance instead of granting a universal upgrade.
- The player can preview the projected TH/s, J/TH, and uptime before spending more R&D money.
- Season objectives create a light operate -> review -> improve rhythm without adding combat or artificial wave defense.

References:
- https://store.steampowered.com/app/1637320/Dome_Keeper/
- https://domekeeper.wiki.gg/wiki/Blast_Mining/Upgrades

### Virtual Circuit Board — separate planning from live simulation

Virtual Circuit Board clearly separates editing from simulation. That separation is useful for an engineering-heavy management game because players should be able to inspect a planned change before committing capital.

Hash Race adaptation now implemented:

- The ASIC lab has a preview step before the next generation is deployed.
- The preview reports projected hashrate, efficiency, and uptime using the current company state and semiconductor partnership effects.
- Future facility and electrical planning can use the same "plan first, simulate second, deploy third" rule.

Reference:
- https://store.steampowered.com/app/1885690/Virtual_Circuit_Board/

### Brotato — short, legible upgrade decisions

Brotato's wave/shop structure demonstrates the value of presenting a small number of meaningful upgrade decisions between active periods rather than burying the player in a permanent catalog. Hash Race should use that lesson selectively for future supplier bids, hiring candidates, and partnership offers. It should **not** become a roguelite shop game.

References:
- https://brotato.wiki.spellsandguns.com/Waves
- https://brotato.wiki.spellsandguns.com/Shop

### Voxurbis: Age of Politicians — manage through people and priorities

Voxurbis is a small management game centered on balancing officials while the city changes over time. The useful pattern for Hash Race is executive delegation: a company owner should increasingly manage department leaders and priorities rather than manually touching every subsystem forever. This is a strong future direction for operations, facilities, electrical, network, finance, and R&D staff.

Reference:
- https://yurisizov.itch.io/

### Extinction Eclipse — persistent assets between operations

Extinction Eclipse carries surviving ships and unused resources forward between missions. Hash Race already treats mining hardware and sites as persistent company assets, so the transferable lesson is to make regional projects and temporary operating events matter to the permanent company rather than resetting after each scenario.

Reference:
- https://store.steampowered.com/app/1961250/Extinction_Eclipse/

## Ideas intentionally not imported

The showreel also includes monster fusion, combat-heavy action, rhythm mechanics, platforming, fantasy combat, and card-focused systems. Those may be good games, but they do not strengthen Hash Race's core identity enough to justify adding them. The project should stay centered on Bitcoin mining economics, hardware evolution, physical infrastructure, company competition, partnerships, acquisitions, staff, and long-term seasons.
