using System.Globalization;

namespace HashRaceDesktop;

internal record Company(string Name, string Archetype, double Cash, int Fleet, double PowerMod, double ResearchMod, double UptimeBonus, string Perk);
internal record MinerGen(string Name, double TH, double JTH, double Cost, double Research);
internal record Partner(string Name, string Category, double Cost, string Benefit);
internal sealed class Rival
{
    public string Name { get; init; } = "";
    public double HashrateTH { get; set; }
    public double EfficiencyJTH { get; set; }
    public double Cash { get; set; }
    public int Ovr { get; set; }
    public bool Acquired { get; set; }
    public double Value => Cash + HashrateTH * Math.Max(8, 120 / Math.Max(1, EfficiencyJTH));
}

internal static class Program
{
    private static readonly List<Company> Companies = new()
    {
        new("BlockForge Mining", "Bitcoin Mining", 8000, 5, .90, 1.00, 0.00, "cheap power + larger opening fleet"),
        new("NeuralPeak Compute", "AI Compute", 11000, 2, 1.05, 1.25, 0.00, "faster R&D + AI deal access"),
        new("Atlas Robotics", "Robotics", 9000, 3, 1.00, 1.05, .02, "higher uptime + automation"),
        new("VoltRiver Energy", "Energy", 8500, 3, .76, .90, 0.00, "lowest starting energy burden"),
        new("SilicaWorks", "Semiconductors", 7500, 3, 1.02, 1.15, 0.00, "better chip efficiency + R&D"),
        new("CoreVector Systems", "CPU + Systems", 10000, 3, .98, 1.08, .005, "balanced engineering stack"),
        new("SkyStack Compute", "Cloud Infrastructure", 10500, 3, 1.00, 1.00, .005, "site growth + infrastructure"),
        new("IonDrive Automation", "Autonomy", 9500, 3, 1.00, 1.10, .015, "uptime + flexible partnerships"),
        new("OpenCircuit Labs", "Open Technology", 6000, 3, 1.00, 1.35, 0.00, "fastest base research"),
        new("Frontier Holdings", "Capital + Acquisitions", 18000, 2, 1.02, .90, 0.00, "cash + cheaper buyouts")
    };

    private static readonly List<MinerGen> Gens = new()
    {
        new("Gen 1 Prototype", 5, 85, 650, 0),
        new("Gen 2 Hashbox", 14, 60, 1500, 15000),
        new("Gen 3 Performance ASIC", 45, 38, 3200, 50000),
        new("Gen 4 Efficient ASIC", 110, 25, 5200, 150000),
        new("Gen 5 Hydro ASIC", 250, 15, 9000, 450000),
        new("Gen 6 PH Node", 1000, 8, 30000, 1500000),
        new("Gen 7 10 PH Rack", 10000, 4, 220000, 8000000),
        new("Gen 8 100 PH Core", 100000, 1.5, 1800000, 40000000),
        new("Gen 9 EH Engine", 1000000, .75, 14000000, 150000000)
    };

    private static readonly List<Partner> Partners = new()
    {
        new("Neural Compute Alliance", "AI", 30000, "R&D + compute revenue"),
        new("Autonomous Operations Group", "Robotics", 45000, "uptime + lower operations cost"),
        new("Grid Power Consortium", "Energy", 50000, "lower electricity cost"),
        new("Advanced Foundry Access", "Semiconductor", 80000, "lower J/TH + faster R&D"),
        new("Strategic Capital Partners", "Finance", 100000, "cheaper acquisitions"),
        new("Hyperscale Infrastructure Pact", "Infrastructure", 125000, "more MW + cheaper expansion"),
        new("MetroLand Development Group", "Real Estate", 60000, "cheaper property + more site space"),
        new("QuickBite Franchise Network", "Quick Service", 35000, "daily commercial revenue"),
        new("FiberGrid Communications", "Telecom", 55000, "higher uptime + lower ops cost"),
        new("Pro Sports Alliance", "Sports", 90000, "sponsor revenue + franchise prestige")
    };

    private static readonly Random Rng = new(21);
    private static Company Player = null!;
    private static int[] Fleet = Array.Empty<int>();
    private static readonly List<Rival> Rivals = new();
    private static readonly HashSet<string> ActivePartners = new();
    private static int Unlocked;
    private static double Research;
    private static double Cash;
    private static double BtcPrice = 1000;
    private static double NetworkTH = 50000;
    private static double Electricity = .060;
    private static double BaseUptime = .955;
    private static double SiteMW = .05;
    private static int Day;
    private static int Season = 1;
    private static int FranchiseOvr = 60;
    private static string EventText = "Welcome to Hash Race v0.001.";

    private static void Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        Console.Title = "Hash Race v0.001";
        SelectCompany();
        SetupLeague();
        GameLoop();
    }

    private static void SelectCompany()
    {
        while (true)
        {
            Console.Clear();
            Header("HASH RACE v0.001 — CHOOSE YOUR COMPANY");
            Console.WriteLine("Every company starts differently. Your choice changes the opening strategy.\n");
            for (int i = 0; i < Companies.Count; i++)
            {
                var c = Companies[i];
                Console.WriteLine($" {i + 1,2}. {c.Name,-24} | {c.Archetype,-22} | ${c.Cash,7:N0} | fleet {c.Fleet} | {c.Perk}");
            }
            Console.Write("\nChoose 1-10: ");
            if (!int.TryParse(Console.ReadLine(), out var pick) || pick < 1 || pick > Companies.Count) continue;
            Player = Companies[pick - 1];
            Cash = Player.Cash;
            BaseUptime = Math.Min(.99, .955 + Player.UptimeBonus);
            Fleet = new int[Gens.Count];
            Fleet[0] = Player.Fleet;
            break;
        }
    }

    private static void SetupLeague()
    {
        Rivals.Clear();
        foreach (var c in Companies.Where(c => c.Name != Player.Name))
        {
            Rivals.Add(new Rival
            {
                Name = c.Name,
                HashrateTH = c.Fleet * 5 * (.9 + Rng.NextDouble() * .3),
                EfficiencyJTH = 70 + Rng.NextDouble() * 20,
                Cash = c.Cash,
                Ovr = 58 + Rng.Next(10)
            });
        }
    }

    private static void GameLoop()
    {
        while (true)
        {
            Render();
            var key = Console.ReadKey(true).Key;
            switch (key)
            {
                case ConsoleKey.A: AdvanceDay(); break;
                case ConsoleKey.B: BuyMiner(); break;
                case ConsoleKey.R: FundResearch(); break;
                case ConsoleKey.P: PartnershipMenu(); break;
                case ConsoleKey.X: ExpandSite(); break;
                case ConsoleKey.D: DealMenu(); break;
                case ConsoleKey.S: Standings(); break;
                case ConsoleKey.Q: return;
            }
        }
    }

    private static void Render()
    {
        Console.Clear();
        Header($"HASH RACE v0.001 | {Player.Name} | Season {Season} Day {Day % 30 + 1}");
        var hash = TotalHashrate();
        var eff = FleetEfficiency();
        var power = TotalPowerKW();
        var daily = DailyProfit();
        Console.WriteLine($"Cash ${Cash:N0}   Value ${CompanyValue():N0}   OVR {FranchiseOvr}   League #{LeagueRank()}   Partnerships {ActivePartners.Count}");
        Console.WriteLine($"Hashrate {FormatHash(hash),12}   Fleet {Fleet.Sum(),4}   Efficiency {eff,6:0.00} J/TH   Power {power,8:0.0} kW   Site {power / 1000:0.000}/{SiteMW:0.000} MW");
        Console.WriteLine($"BTC ${BtcPrice:N0}   Network {FormatHash(NetworkTH)}   Electricity ${EffectiveElectricity():0.000}/kWh   Uptime {Uptime() * 100:0.0}%   Profit/day ${daily:N0}");
        Console.WriteLine(new string('─', 112));
        DrawFacility();
        Console.WriteLine(new string('─', 112));
        Console.WriteLine($"ASIC: {Gens[Unlocked].Name} | {FormatHash(Gens[Unlocked].TH)} each | {EffectiveJTH(Gens[Unlocked]):0.00} J/TH | ${Gens[Unlocked].Cost:N0}");
        if (Unlocked < Gens.Count - 1)
            Console.WriteLine($"R&D: ${Research:N0} / ${Gens[Unlocked + 1].Research / Player.ResearchMod:N0} toward {Gens[Unlocked + 1].Name}");
        Console.WriteLine($"NEWS: {EventText}");
        Console.WriteLine();
        Console.WriteLine("[A] Advance day   [B] Buy ASIC   [R] Fund R&D   [P] Partnerships   [X] Expand site   [D] Deals/Buyouts   [S] Standings   [Q] Quit");
    }

    private static void DrawFacility()
    {
        Console.WriteLine("2D FACILITY — each M is installed mining capacity; P=power, C=cooling, H=HQ, +=future expansion");
        int miners = Math.Min(24, Fleet.Sum());
        for (int y = 0; y < 5; y++)
        {
            Console.Write("   ");
            for (int x = 0; x < 12; x++)
            {
                char tile = '.';
                if (y == 0 && x == 0) tile = 'H';
                else if (y == 0 && x == 1) tile = 'P';
                else if (y == 0 && x == 2) tile = 'C';
                else if (miners > 0) { tile = 'M'; miners--; }
                else if (x > 8) tile = '+';
                Console.Write($"[{tile}]");
            }
            Console.WriteLine();
        }
    }

    private static void AdvanceDay()
    {
        Cash += DailyProfit();
        Day++;
        BtcPrice = Math.Max(100, BtcPrice * (1 + (Rng.NextDouble() - .48) * .035));
        NetworkTH *= 1.001 + Rng.NextDouble() * .004;
        Electricity = Math.Clamp(Electricity + (Rng.NextDouble() - .5) * .003, .015, .20);
        foreach (var r in Rivals.Where(r => !r.Acquired))
        {
            r.Cash += 120 + r.HashrateTH * .04 - r.HashrateTH * r.EfficiencyJTH / 1000 * 24 * Electricity;
            if (Rng.NextDouble() < .25 && r.Cash > 1500) { r.HashrateTH *= 1.02 + Rng.NextDouble() * .04; r.Cash -= 500; }
            if (Rng.NextDouble() < .04) r.EfficiencyJTH = Math.Max(.7, r.EfficiencyJTH * .97);
            r.Ovr = Math.Clamp((int)(55 + Math.Log10(Math.Max(10, r.Value)) * 5), 55, 99);
        }
        if (Day > 0 && Day % 30 == 0)
        {
            Season++;
            FranchiseOvr = Math.Clamp(FranchiseOvr + Math.Max(0, 5 - LeagueRank()), 50, 99);
            EventText = $"Season {Season - 1} finished. You placed #{LeagueRank()} and begin Season {Season} with OVR {FranchiseOvr}.";
        }
        else
        {
            string[] events = { "Power markets moved today.", "A rival announced new capacity.", "Engineers found a small firmware optimization.", "Commercial partners are watching the league table.", "Property prices around mining sites are changing." };
            EventText = events[Rng.Next(events.Length)];
        }
    }

    private static void BuyMiner()
    {
        var g = Gens[Unlocked];
        if (Cash < g.Cost) { EventText = "Not enough cash for that ASIC."; return; }
        var newPowerMW = (TotalPowerKW() + g.TH * EffectiveJTH(g) / 1000) / 1000;
        if (newPowerMW > EffectiveSiteMW()) { EventText = "Site power capacity is full. Expand the facility first."; return; }
        Cash -= g.Cost;
        Fleet[Unlocked]++;
        EventText = $"Installed one {g.Name}.";
    }

    private static void FundResearch()
    {
        if (Unlocked >= Gens.Count - 1) { EventText = "All current ASIC generations are unlocked."; return; }
        var target = Gens[Unlocked + 1].Research / Player.ResearchMod;
        if (ActivePartners.Contains("AI")) target *= .75;
        if (ActivePartners.Contains("Semiconductor")) target *= .85;
        var spend = Math.Min(Cash, Math.Min(Math.Max(1000, target * .2), target - Research));
        if (spend <= 0) { EventText = "No cash available for research."; return; }
        Cash -= spend;
        Research += spend;
        if (Research >= target)
        {
            Unlocked++;
            Research = 0;
            FranchiseOvr = Math.Min(99, FranchiseOvr + 2);
            EventText = $"HARDWARE EVOLUTION: unlocked {Gens[Unlocked].Name} at {EffectiveJTH(Gens[Unlocked]):0.00} J/TH.";
        }
        else EventText = $"Invested ${spend:N0} in R&D.";
    }

    private static void PartnershipMenu()
    {
        Console.Clear(); Header("PARTNERSHIP MARKET");
        for (int i = 0; i < Partners.Count; i++)
        {
            var p = Partners[i];
            var active = ActivePartners.Contains(p.Category) ? "ACTIVE" : $"${p.Cost:N0}";
            Console.WriteLine($" {i + 1,2}. {p.Category,-15} | {p.Name,-32} | {active,-10} | {p.Benefit}");
        }
        Console.Write("\nChoose 1-10 or Enter to cancel: ");
        var input = Console.ReadLine();
        if (!int.TryParse(input, out var pick) || pick < 1 || pick > Partners.Count) return;
        var partner = Partners[pick - 1];
        if (ActivePartners.Contains(partner.Category)) { EventText = partner.Category + " partnership already active."; return; }
        if (Cash < partner.Cost) { EventText = "Not enough cash for that partnership."; return; }
        Cash -= partner.Cost;
        ActivePartners.Add(partner.Category);
        if (partner.Category == "Sports") FranchiseOvr = Math.Min(99, FranchiseOvr + 5);
        EventText = $"Signed {partner.Name}. {partner.Benefit}.";
    }

    private static void ExpandSite()
    {
        var cost = 15000 * Math.Pow(1.6, Math.Max(0, SiteMW / .05 - 1));
        if (ActivePartners.Contains("Infrastructure")) cost *= .75;
        if (ActivePartners.Contains("Real Estate")) cost *= .80;
        if (Cash < cost) { EventText = $"Need ${cost:N0} to expand the site."; return; }
        Cash -= cost;
        SiteMW += .05;
        EventText = $"Expanded site to {SiteMW:0.000} MW.";
    }

    private static void DealMenu()
    {
        Console.Clear(); Header("RIVAL DEAL ROOM");
        var available = Rivals.Where(r => !r.Acquired).OrderBy(r => r.Value).ToList();
        for (int i = 0; i < available.Count; i++)
            Console.WriteLine($" {i + 1}. {available[i].Name,-25} OVR {available[i].Ovr} | {FormatHash(available[i].HashrateTH),10} | Value ${available[i].Value:N0}");
        Console.Write("\nChoose a company to acquire or Enter to cancel: ");
        var input = Console.ReadLine();
        if (!int.TryParse(input, out var pick) || pick < 1 || pick > available.Count) return;
        var r = available[pick - 1];
        var price = r.Value * (ActivePartners.Contains("Finance") ? .92 : 1.15) * (Player.Archetype.Contains("Capital") ? .85 : 1);
        if (Cash < price) { EventText = $"Acquisition needs ${price:N0}."; return; }
        Cash -= price; r.Acquired = true; FranchiseOvr = Math.Min(99, FranchiseOvr + 3);
        var units = Math.Max(1, (int)Math.Round(r.HashrateTH / Math.Max(1, Gens[Unlocked].TH)));
        Fleet[Unlocked] += units;
        EventText = $"Acquired {r.Name} for ${price:N0}. Its capacity joined your fleet.";
    }

    private static void Standings()
    {
        Console.Clear(); Header($"HASH LEAGUE — SEASON {Season}");
        var rows = Rivals.Where(r => !r.Acquired).Select(r => (r.Name, r.Value, r.Ovr, r.HashrateTH)).ToList();
        rows.Add((Player.Name, CompanyValue(), FranchiseOvr, TotalHashrate()));
        int rank = 1;
        foreach (var row in rows.OrderByDescending(x => x.Value))
            Console.WriteLine($" #{rank++,2} {row.Name,-25} OVR {row.Ovr,2} | Value ${row.Value,12:N0} | {FormatHash(row.HashrateTH),12}");
        Console.WriteLine("\nPress any key to return..."); Console.ReadKey(true);
    }

    private static double TotalHashrate() => Fleet.Select((n, i) => n * Gens[i].TH).Sum();
    private static double EffectiveJTH(MinerGen g) => g.JTH * (Player.Archetype.Contains("Semiconductor") ? .92 : 1) * (ActivePartners.Contains("Semiconductor") ? .90 : 1);
    private static double TotalPowerKW() => Fleet.Select((n, i) => n * Gens[i].TH * EffectiveJTH(Gens[i]) / 1000).Sum();
    private static double FleetEfficiency() => TotalHashrate() <= 0 ? 0 : TotalPowerKW() * 1000 / TotalHashrate();
    private static double EffectiveElectricity() => Electricity * Player.PowerMod * (ActivePartners.Contains("Energy") ? .78 : 1);
    private static double Uptime() => Math.Min(.995, BaseUptime + (ActivePartners.Contains("Robotics") ? .02 : 0) + (ActivePartners.Contains("Telecom") ? .015 : 0));
    private static double EffectiveSiteMW() => SiteMW * (ActivePartners.Contains("Infrastructure") ? 1.35 : 1) * (ActivePartners.Contains("Real Estate") ? 1.20 : 1);
    private static double DailyBtc() => NetworkTH <= 0 ? 0 : TotalHashrate() / NetworkTH * 144 * 25 * Uptime();
    private static double DailyProfit()
    {
        var revenue = DailyBtc() * BtcPrice * (ActivePartners.Contains("AI") ? 1.10 : 1);
        if (ActivePartners.Contains("Quick Service")) revenue += 300;
        if (ActivePartners.Contains("Sports")) revenue += 450;
        var power = TotalPowerKW() * 24 * EffectiveElectricity() * Uptime();
        var ops = Fleet.Sum() * 2.0 + TotalHashrate() * .005;
        if (ActivePartners.Contains("Robotics")) ops *= .75;
        if (ActivePartners.Contains("Telecom")) ops *= .90;
        return revenue - power - ops;
    }
    private static double CompanyValue() => Math.Max(0, Cash) + Fleet.Select((n, i) => n * Gens[i].Cost * .55).Sum() + ActivePartners.Count * 5000 + FranchiseOvr * 100;
    private static int LeagueRank() => 1 + Rivals.Count(r => !r.Acquired && r.Value > CompanyValue());
    private static string FormatHash(double th) => th >= 1_000_000 ? $"{th / 1_000_000:0.###} EH/s" : th >= 1000 ? $"{th / 1000:0.###} PH/s" : $"{th:0.##} TH/s";
    private static void Header(string text) { Console.WriteLine(text); Console.WriteLine(new string('═', Math.Min(112, text.Length + 16))); }
}
