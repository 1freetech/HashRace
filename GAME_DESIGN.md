# Hash Race — Game Design Foundation

## Core fantasy

The player runs a Bitcoin mining company in a race against other miners. Winning is not just owning more machines. The player has to make better engineering and business decisions so the company can produce more hashrate with less energy and reach new ASIC generations before its rivals.

## Format

- 2D management simulation
- Desktop first
- Unity + C#
- Mobile/iOS later
- Time based, with pause and multiple speed settings
- Simple readable screens before detailed art

## Main loop

**Mine → earn → pay costs → improve → research → unlock → scale → compete.**

Every machine generation should feel like a meaningful evolution. New machines can be faster, more efficient, more expensive, or more difficult to cool. Old equipment does not magically disappear. The player decides when to keep it, sell it, or replace it.

## Major systems

### Mining economics

Hashrate produces a share of the simulated Bitcoin network reward. Electricity, uptime, and equipment efficiency determine whether that hashrate is profitable.

### Hardware evolution

The initial prototype contains nine hardware generations. They begin with small TH/s machines and eventually reach PH/s and EH/s-class systems. Future versions can split research into chips, boards, PSU, cooling, firmware, packaging, and facility infrastructure.

### Rival miners

AI companies earn money, buy machines, research technology, and increase their hashrate. The player can fall behind even while remaining profitable.

### Company deals

A stronger company can eventually acquire a weaker rival. A badly performing player may also receive a sellout offer. Later versions can add negotiation, shares, debt, joint ventures, hosting contracts, and hostile bids.

### Facility layer

The next visual step is a 2D facility map. Racks, transformers, cooling equipment, network equipment, repair benches, and engineers can occupy physical spaces. Capacity will then depend on power, cooling, floor space, and reliability instead of only money.

## Visual direction

The first visual style should be readable and inexpensive to build: top-down 2D rooms, clean pixel-inspired machines and racks, strong status icons, animated fans/lights, and simple hardware evolution cards. The progression can have the excitement of collecting and evolving equipment without copying any protected characters, art, names, or assets from other games.

## Prototype victory targets

The long game is a sequence of races rather than one finish line:

1. Reach 1 PH/s total fleet hashrate.
2. Unlock a sub-10 J/TH machine.
3. Reach 10 PH/s.
4. Unlock a sub-5 J/TH machine.
5. Reach 100 PH/s.
6. Unlock a sub-1 J/TH machine.
7. Reach 1 EH/s.
8. Become the most valuable mining company.

These targets can later unlock new eras, maps, markets, and difficulty levels.
