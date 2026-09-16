# Hash Race — Gameplay Design

## Core idea

Hash Race is a 2D Bitcoin mining strategy game about building a technology company that can survive, expand, partner, acquire rivals, and win the hardware race.

The player is not only buying miners. The player is running a company over many simulated years. Every important decision competes for the same money: ASICs, R&D, power capacity, partnerships, acquisitions, and survival.

The design borrows broad strategy ideas from empire games, business board games, city builders, open-world management games, and sports franchise modes. Hash Race must use original companies, art, names, maps, interfaces, events, and game rules rather than copying protected content from those games.

## Primary gameplay pillars

### 1. Civilization-style long game

The company moves through technology eras instead of simply leveling up.

- Garage Era
- Industrial ASIC Era
- Infrastructure Era
- Hyperscale Era
- Exahash Era

R&D changes what hardware is possible. Partnerships change which path is easiest. Rivals continue researching while the player makes decisions, so standing still means falling behind.

### 2. Monopoly-style company control

Money can be used to buy productive assets or entire rival companies.

- Buy ASICs
- Sell old ASICs
- Expand mining sites
- Acquire weaker competitors
- Build company value
- Use finance partnerships to improve deal economics
- Eventually add negotiation, debt, stock ownership, hostile bids, and sellout offers

An acquisition should feel like buying a valuable property in a business game: it costs a lot now but can change the whole board.

### 3. SimCity-style infrastructure

Hashrate cannot grow forever inside an unlimited imaginary building.

Every facility has a power capacity in MW. New miners consume part of that capacity. The player must expand the site before the fleet can grow past its physical limits.

Future facility systems should include:

- Electrical service and substations
- Transformers and PDUs
- Cooling capacity
- Water for hydro systems
- Network capacity
- Rack and floor space
- Repair areas
- Reliability
- Local energy prices
- Multiple cities and sites

### 4. Sports-franchise management

Each mining company functions like a franchise competing in a league.

The game tracks:

- Franchise OVR rating
- League rank
- Company value
- Technology generation
- Hashrate
- Efficiency
- Partnerships
- Acquisitions
- Seasons

A new season begins every 365 game days. Long-term play should eventually include historical records, awards, rivalries, owner goals, yearly budgets, front-office staff, engineering staff, scouting, and company legacy records.

### 5. Living-world flavor

The game world should occasionally create opportunities and problems outside the normal menu loop.

Current prototype events include:

- AI compute demand
- Grid load-management payments
- Semiconductor breakthroughs
- Maintenance failures
- Regional development/site opportunities
- Investor financing
- Property development deals
- Retail branding opportunities
- Telecom outages
- Sports sponsorship opportunities

Future 2D maps can allow the player to move through facilities, visit partner companies, inspect racks, meet engineers, and interact with business opportunities. The open-world influence should add personality without turning Hash Race into an action game.

## Ten starting companies

All ten companies are fictional and original. They are inspired by broad real-world technology sectors rather than using real company names, logos, or assets.

| Company | Sector | Main advantage | Natural partnership |
| --- | --- | --- | --- |
| BlockForge Mining | Bitcoin mining | More starting miners and cheaper power | Energy |
| NeuralPeak Compute | AI compute | Faster R&D | AI |
| Atlas Robotics | Robotics | Better uptime and operations | Robotics |
| VoltRiver Energy | Energy | Very low effective power cost | Energy |
| SilicaWorks | Semiconductors | Better ASIC efficiency | Semiconductor |
| CoreVector Systems | CPU/systems | Balanced engineering company | Semiconductor |
| SkyStack Compute | Cloud infrastructure | Large starting site | Infrastructure |
| IonDrive Automation | Autonomy/technology | Strong uptime and flexible R&D | Robotics |
| OpenCircuit Labs | Open technology | Fastest base research | AI |
| Frontier Holdings | Capital/acquisitions | More cash and cheaper buyouts | Finance |

The player chooses one company. The other nine enter the world as AI competitors with the same general strengths and weaknesses.

## Strategic partnerships

Partnerships are the second technology tree. They should be powerful enough that choosing partners changes the player's strategy.

### AI — Neural Compute Alliance

- Faster R&D
- Additional compute-contract revenue
- Helps a technology-first company reach new ASIC generations early

### Robotics — Autonomous Operations Group

- Higher uptime
- Lower operating costs
- Makes large facilities easier to maintain

### Energy — Grid Power Consortium

- Lower electricity cost
- Makes older or less efficient hardware remain profitable longer

### Semiconductor — Advanced Foundry Access

- Better effective J/TH
- Faster R&D
- Strong path toward sub-1 J/TH hardware

### Finance — Strategic Capital Partners

- Lower acquisition prices
- Future versions can add debt, equity, IPOs, and takeover financing

### Infrastructure — Hyperscale Infrastructure Pact

- More effective site capacity
- Cheaper site expansion
- Strong path toward PH/s and EH/s scale

### Real Estate — MetroLand Development Group

- Cheaper land and site expansion
- More effective usable site capacity
- Future versions can add leases, land appreciation, zoning, taxes, and property portfolios

### Quick Service — QuickBite Franchise Network

- Creates steady non-mining commercial income
- Adds brand visibility and retail sponsorship opportunities
- Future versions can add branded locations, franchise deals, and heat-reuse partnerships

### Telecom — FiberGrid Communications

- Better network uptime
- Lower operating costs
- Future versions can add carrier redundancy, latency, bandwidth, network outages, and private fiber builds

### Sports — Pro Sports Alliance

- Adds sponsorship income
- Adds franchise prestige and OVR value
- Future versions can add team sponsorships, league partnerships, naming rights, stadium deals, and seasonal marketing events

Partnerships require minimum company value, technology progress, and cash. A small early-game company cannot instantly sign every major partner.

## Partnership philosophy

Hash Race partnerships do not need to stay inside Bitcoin or technology. A successful company can become a broader business empire.

A mining company might partner with an AI company for research, an energy company for cheaper electricity, a real-estate developer for land, a telecom provider for connectivity, a food franchise for commercial cash flow, or a sports organization for sponsorship and brand power.

The important design rule is that every partnership must change a real game system. Partnerships should never be badges that only decorate the UI.

## Mining economics

Hashrate produces a share of the simulated Bitcoin network reward. Electricity, uptime, equipment efficiency, network hashrate, and the Bitcoin price determine whether that hashrate is profitable.

Core formulas remain grounded in mining concepts:

`power watts = hashrate TH/s × J/TH`

`BTC/day = company hashrate ÷ network hashrate × blocks/day × block subsidy × uptime`

Partnerships and company traits modify business results without replacing the underlying mining math.

## Hardware evolution

The first prototype has nine hardware generations:

1. Gen 1 Prototype
2. Gen 2 Hashbox
3. Gen 3 Performance ASIC
4. Gen 4 Efficient ASIC
5. Gen 5 Hydro ASIC
6. Gen 6 PH Node
7. Gen 7 10 PH Rack
8. Gen 8 100 PH Core
9. Gen 9 EH Engine

Future research should split into separate engineering trees for silicon, boards, power supplies, firmware, cooling, packaging, networking, and facility design.

## Dynasty goals

Hash Race should not have only one victory screen. The player builds a legacy across several goals:

1. Become the #1 company by value.
2. Reach 1 PH/s.
3. Reach 10 PH/s.
4. Reach 100 PH/s.
5. Reach 1 EH/s.
6. Unlock sub-10 J/TH hardware.
7. Unlock sub-5 J/TH hardware.
8. Unlock sub-1 J/TH hardware.
9. Build at least three major strategic partnerships.
10. Acquire rival companies when it strengthens the empire.

Reaching #1, 1 EH/s, and at least three partnerships is currently treated as the first dynasty milestone.

## Visual direction

Desktop remains 2D first.

The eventual playable world should use a top-down facility/campus view with readable rooms, sites, racks, machines, substations, cooling systems, engineers, executives, partner locations, and company headquarters.

Hardware evolution should feel exciting and collectible, but all machines, characters, interfaces, animations, names, and art should be original to Hash Race.

## Immediate build order

1. Keep the company/partnership economy stable.
2. Add a real 2D facility map and physical rack placement.
3. Split R&D into engineering branches.
4. Give rivals stronger personalities and strategic behavior.
5. Add staff/front-office management.
6. Add multiple sites, regions, and power markets.
7. Add negotiation and sellout systems.
8. Add season history, records, awards, and rivalries.
9. Add mobile-friendly UI after desktop gameplay is proven.
