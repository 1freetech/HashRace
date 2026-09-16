namespace HashRaceDesktop;

internal record Company(
    string Name, double Cash, int Fleet, double PowerMod, double ResearchMod,
    double UptimeBonus, double AcquisitionMod, double SiteMod, double EfficiencyMod, string Perk);
internal record Partner(string Name, string Category, double Cost, string Benefit);
internal sealed class Rival
{
    public string Name { get; init; } = "";
    public double HashrateTH { get; set; }
    public double EfficiencyJTH { get; set; }
    public double Cash { get; set; }
    public bool Acquired { get; set; }
    public double Value => Cash + HashrateTH * Math.Max(8, 120 / Math.Max(1, EfficiencyJTH));
}

internal static class Program
{
    private const string Version = "v0.002";
    private static readonly List<Company> Companies = new()
    {
        new("Emberline Compute", 9000, 5, .90, 1.00, .000, 1.00, 1.00, 1.00, "low-cost operator + bigger opening fleet"),
        new("Helix Circuit Labs", 9500, 3, 1.00, 1.25, .000, 1.00, 1.00, .98, "research-first mining team"),
        new("ArcCurrent Systems", 8500, 4, .84, 1.00, .000, 1.00, 1.00, 1.00, "grid-optimization specialist"),
        new("StoneGrid Infrastructure", 10000, 3, 1.00, 1.00, .000, 1.00, 1.25, 1.00, "land and site expansion specialist"),
        new("Meridian Node Group", 15000, 2, 1.00, .95, .000, .82, 1.00, 1.02, "deal-focused mining consolidator"),
        new("BlueLoop Compute", 9000, 3, 1.00, 1.00, .025, 1.00, 1.05, .94, "cooling, uptime, and efficiency"),
        new("SignalPeak Systems", 9000, 4, .98, 1.00, .018, 1.00, 1.00, 1.00, "reliability-first fleet operator"),
        new("Parallax Digital Works", 10500, 3, .95, 1.08, .005, .96, 1.08, .97, "balanced industrial miner"),
        new("Lattice Energy Labs", 8000, 3, 1.00, 1.10, .000, 1.00, 1.00, .88, "best opening J/TH profile"),
        new("Epoch Harbor Holdings", 13500, 3, 1.00, .95, .000, .92, 1.20, 1.04, "capital-heavy expansion miner")
    };

    private static readonly List<Partner> Partners = new()
    {
        new("NeuralPeak AI", "AI", 30000, "faster R&D + compute-contract revenue"),
        new("Atlas Robotics", "Robotics", 45000, "higher uptime + lower operating cost"),
        new("SilicaWorks Foundry", "Semiconductor", 80000, "better ASIC efficiency + faster R&D"),
        new("VoltRiver Energy", "Energy", 50000, "lower electricity cost"),
        new("FiberGrid Communications", "Telecom", 55000, "network reliability + uptime"),
        new("MetroLand Development", "Real Estate", 60000, "cheaper expansion + more usable site capacity"),
        new("Frontier Capital", "Finance", 90000, "cheaper acquisitions"),
        new("SkyStack Infrastructure", "Infrastructure", 120000, "larger sites + lower expansion cost"),
        new("QuickBite Franchise Network", "Quick Service", 35000, "recurring non-mining commercial revenue"),
        new("Pro Sports Alliance", "Sports", 70000, "sponsorship cash + franchise prestige")
    };

    private static readonly Random Rng = new(21);
    private static Company Player = null!;
    private static readonly List<Rival> Rivals = new();
    private static readonly HashSet<string> ActivePartners = new();
    private static double Cash;
    private static int Fleet;
    private static int Generation = 1;
    private static double MinerTH = 5;
    private static double BaseJTH = 85;
    private static double Research;
    private static double ResearchTarget = 15000;
    private static double SiteMW = .05;
    private static double Electricity = .060;
    private static double BtcPrice = 1000;
    private static double NetworkTH = 50000;
    private static int Day;
    private static int Season = 1;
    private static int Prestige = 50;
    private static string EventText = "The Bitcoin mining race has started.";

    private static void Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        Console.Title = $"Hash Race {Version}";
        SelectCompany();
        SetupLeague();
        while (true)
        {
            Render();
            switch (Console.ReadKey(true).Key)
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

    private static void SelectCompany()
    {
        while (true)
        {
            Console.Clear();
            Header($"HASH RACE {Version} — CHOOSE A BITCOIN MINING COMPANY");
            Console.WriteLine("All ten competitors are Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real estate, finance, infrastructure, food, and sports organizations appear later as outside partners.\n");
            for (int i = 0; i < Companies.Count; i++)
            {
                var c = Companies[i];
                Console.WriteLine($" {i + 1,2}. {c.Name,-27} | ${c.Cash,7:N0} | fleet {c.Fleet} | {c.Perk}");
            }
            Console.Write("\nChoose 1-10: ");
            if (!int.TryParse(Console.ReadLine(), out var pick) || pick < 1 || pick > Companies.Count) continue;
            Player = Companies[pick - 1];
            Cash = Player.Cash;
            Fleet = Player.Fleet;
            BaseJTH = 85 * Player.EfficiencyMod;
            SiteMW = .05 * Player.SiteMod;
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
                HashrateTH = c.Fleet * 5 * (.92 + Rng.NextDouble() * .18),
                EfficiencyJTH = 85 * c.EfficiencyMod,
                Cash = c.Cash
            });
        }
    }

    private static void Render()
    {
        Console.Clear();
        Header($"HASH RACE {Version} | {Player.Name} | Season {Season} | Day {Day}");
        Console.WriteLine($"Cash ${Cash:N0}   Rank #{LeagueRank()}/10   Prestige {Prestige}   Partnerships {ActivePartners.Count}");
        Console.WriteLine($"Fleet {Fleet}   Hashrate {FormatHash(TotalHashrate())}   Efficiency {EffectiveJTH():0.00} J/TH   Power {PowerKW():0.0} kW / {EffectiveSiteMW() * 1000:0} kW site");
        Console.WriteLine($"BTC ${BtcPrice:N0}   Network {FormatHash(NetworkTH)}   Electricity ${EffectiveElectricity():0.000}/kWh   Uptime {Uptime() * 100:0.0}%   Profit/day ${DailyProfit():N0}");
        Console.WriteLine(new string('─', 112));
        DrawFacility();
        Console.WriteLine(new string('─', 112));
        Console.WriteLine($"Hardware Gen {Generation}: {MinerTH:N1} TH/s each at {EffectiveJTH():0.00} J/TH");
        Console.WriteLine($"R&D ${Research:N0} / ${EffectiveResearchTarget():N0}");
        Console.WriteLine($"NEWS: {EventText}\n");
        Console.WriteLine("[A] Advance day   [B] Buy ASIC   [R] Fund R&D   [P] External partners   [X] Expand site   [D] Acquire miner   [S] Standings   [Q] Quit");
    }

    private static void DrawFacility()
    {
        Console.WriteLine("2D MINING SITE — H=HQ P=power C=cooling M=miners +=expansion");
        int miners = Math.Min(24, Fleet);
        for (int y = 0; y < 5; y++)
        {
            Console.Write("   ");
            for (int x = 0; x < 12; x++)
            {
                char tile = '.';
                if (y == 0 && x == 0) tile = 'H';
                else if (y == 0 && x == 1) tile = 'P';
                else if (y == 0 && x == 2) tile = 'C';
                else if (miners-- > 0) tile = 'M';
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
            if (Rng.NextDouble() < .04) r.EfficiencyJTH = Math.Max(.70, r.EfficiencyJTH * .97);
        }
        if (Day > 0 && Day % 30 == 0)
        {
            Season++;
            Prestige = Math.Clamp(Prestige + Math.Max(0, 6 - LeagueRank()), 0, 99);
            EventText = $"Season {Season - 1} ended. You finished #{LeagueRank()} and entered Season {Season}.";
        }
        else
        {
            string[] events = { "Power prices moved today.", "A rival miner announced new capacity.", "Engineers found a firmware optimization.", "Outside partners are watching the mining standings.", "Property prices around mining sites changed." };
            EventText = events[Rng.Next(events.Length)];
        }
    }

    private static void BuyMiner()
    {
        var price = 650 * Math.Pow(1.9, Generation - 1);
        var nextPowerMW = (PowerKW() + MinerTH * EffectiveJTH() / 1000) / 1000;
        if (Cash < price) { EventText = "Not enough cash for the current ASIC."; return; }
        if (nextPowerMW > EffectiveSiteMW()) { EventText = "Site power is full. Expand before installing another ASIC."; return; }
        Cash -= price;
        Fleet++;
        EventText = $"Installed one Gen {Generation} ASIC.";
    }

    private static void FundResearch()
    {
        var target = EffectiveResearchTarget();
        var spend = Math.Min(Cash, Math.Min(Math.Max(1000, target * .20), target - Research));
        if (spend <= 0) { EventText = "No cash available for R&D."; return; }
        Cash -= spend;
        Research += spend;
        if (Research >= target)
        {
            Research = 0;
            Generation++;
            MinerTH *= 2.2;
            BaseJTH = Math.Max(.75, BaseJTH * .72);
            ResearchTarget *= 3;
            Prestige = Math.Min(99, Prestige + 2);
            EventText = $"HARDWARE EVOLUTION: Gen {Generation} unlocked at {MinerTH:N1} TH/s and {EffectiveJTH():0.00} J/TH.";
        }
        else EventText = $"Invested ${spend:N0} in mining R&D.";
    }

    private static void PartnershipMenu()
    {
        Console.Clear(); Header("EXTERNAL PARTNERSHIP MARKET");
        Console.WriteLine("These organizations are not mining competitors. They help your Bitcoin mining company with technology, capital, infrastructure, revenue, or prestige.\n");
        for (int i = 0; i < Partners.Count; i++)
        {
            var p = Partners[i];
            var status = ActivePartners.Contains(p.Category) ? "SIGNED" : $"${p.Cost:N0}";
            Console.WriteLine($" {i + 1,2}. {p.Category,-15} | {p.Name,-29} | {status,-10} | {p.Benefit}");
        }
        Console.Write("\nChoose 1-10 or Enter to cancel: ");
        if (!int.TryParse(Console.ReadLine(), out var pick) || pick < 1 || pick > Partners.Count) return;
        var partner = Partners[pick - 1];
        if (ActivePartners.Contains(partner.Category)) { EventText = partner.Category + " partner already signed."; return; }
        if (Cash < partner.Cost) { EventText = "Not enough cash for that partnership."; return; }
        Cash -= partner.Cost;
        ActivePartners.Add(partner.Category);
        if (partner.Category == "Sports") Prestige = Math.Min(99, Prestige + 5);
        EventText = $"Signed outside partner {partner.Name}: {partner.Benefit}.";
    }

    private static void ExpandSite()
    {
        var cost = 15000 * Math.Pow(1.55, Math.Max(0, SiteMW / .05 - 1));
        if (ActivePartners.Contains("Infrastructure")) cost *= .75;
        if (ActivePartners.Contains("Real Estate")) cost *= .80;
        if (Cash < cost) { EventText = $"Need ${cost:N0} to expand the mining site."; return; }
        Cash -= cost;
        SiteMW += .05 * Player.SiteMod;
        EventText = $"Expanded mining site to {SiteMW:0.000} MW base capacity.";
    }

    private static void DealMenu()
    {
        Console.Clear(); Header("MINING COMPANY DEAL ROOM");
        var available = Rivals.Where(r => !r.Acquired).OrderBy(r => r.Value).ToList();
        for (int i = 0; i < available.Count; i++)
            Console.WriteLine($" {i + 1}. {available[i].Name,-28} | {FormatHash(available[i].HashrateTH),10} | Value ${available[i].Value:N0}");
        Console.Write("\nChoose a rival Bitcoin miner to acquire or Enter to cancel: ");
        if (!int.TryParse(Console.ReadLine(), out var pick) || pick < 1 || pick > available.Count) return;
        var r = available[pick - 1];
        var price = r.Value * 1.15 * Player.AcquisitionMod * (ActivePartners.Contains("Finance") ? .80 : 1);
        if (Cash < price) { EventText = $"Acquisition needs ${price:N0}."; return; }
        Cash -= price;
        r.Acquired = true;
        Fleet += Math.Max(1, (int)Math.Round(r.HashrateTH / Math.Max(1, MinerTH)));
        Prestige = Math.Min(99, Prestige + 3);
        EventText = $"Acquired rival miner {r.Name} for ${price:N0}.";
    }

    private static void Standings()
    {
        Console.Clear(); Header($"BITCOIN MINING LEAGUE — SEASON {Season}");
        var rows = Rivals.Where(r => !r.Acquired).Select(r => (r.Name, r.Value, r.HashrateTH)).ToList();
        rows.Add((Player.Name, CompanyValue(), TotalHashrate()));
        int rank = 1;
        foreach (var row in rows.OrderByDescending(x => x.Value))
            Console.WriteLine($" #{rank++,2} {row.Name,-28} | Value ${row.Value,12:N0} | {FormatHash(row.HashrateTH),12}");
        Console.WriteLine("\nPress any key to return...");
        Console.ReadKey(true);
    }

    private static double TotalHashrate() => Fleet * MinerTH;
    private static double EffectiveJTH() => BaseJTH * (ActivePartners.Contains("Semiconductor") ? .90 : 1);
    private static double PowerKW() => TotalHashrate() * EffectiveJTH() / 1000;
    private static double EffectiveElectricity() => Electricity * Player.PowerMod * (ActivePartners.Contains("Energy") ? .78 : 1);
    private static double Uptime() => Math.Min(.995, .955 + Player.UptimeBonus + (ActivePartners.Contains("Robotics") ? .025 : 0) + (ActivePartners.Contains("Telecom") ? .015 : 0));
    private static double EffectiveSiteMW() => SiteMW * (ActivePartners.Contains("Infrastructure") ? 1.35 : 1) * (ActivePartners.Contains("Real Estate") ? 1.20 : 1);
    private static double EffectiveResearchTarget() => ResearchTarget / Player.ResearchMod * (ActivePartners.Contains("AI") ? .75 : 1) * (ActivePartners.Contains("Semiconductor") ? .85 : 1);
    private static double DailyBtc() => NetworkTH <= 0 ? 0 : TotalHashrate() / NetworkTH * 144 * 25 * Uptime();
    private static double DailyProfit()
    {
        var revenue = DailyBtc() * BtcPrice;
        if (ActivePartners.Contains("AI")) revenue *= 1.10;
        if (ActivePartners.Contains("Quick Service")) revenue += 300;
        if (ActivePartners.Contains("Sports")) revenue += 450;
        var power = PowerKW() * 24 * EffectiveElectricity() * Uptime();
        var ops = Fleet * 2.0 + TotalHashrate() * .005;
        if (ActivePartners.Contains("Robotics")) ops *= .75;
        if (ActivePartners.Contains("Telecom")) ops *= .90;
        return revenue - power - ops;
    }
    private static double CompanyValue() => Math.Max(0, Cash) + Fleet * 650 * Math.Pow(1.9, Generation - 1) * .55 + ActivePartners.Count * 5000 + Prestige * 100;
    private static int LeagueRank() => 1 + Rivals.Count(r => !r.Acquired && r.Value > CompanyValue());
    private static string FormatHash(double th) => th >= 1_000_000 ? $"{th / 1_000_000:0.###} EH/s" : th >= 1000 ? $"{th / 1000:0.###} PH/s" : $"{th:0.##} TH/s";
    private static void Header(string text) { Console.WriteLine(text); Console.WriteLine(new string('═', Math.Min(112, text.Length + 16))); }
}