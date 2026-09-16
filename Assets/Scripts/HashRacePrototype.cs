using System;
using System.Collections.Generic;
using UnityEngine;

namespace HashRace
{
    [Serializable]
    public class MinerGeneration
    {
        public string Name;
        public double HashrateTH;
        public double EfficiencyJTH;
        public double PurchasePrice;
        public double ResearchCostToUnlock;

        public MinerGeneration(string name, double hashrateTH, double efficiencyJTH, double purchasePrice, double researchCostToUnlock)
        {
            Name = name;
            HashrateTH = hashrateTH;
            EfficiencyJTH = efficiencyJTH;
            PurchasePrice = purchasePrice;
            ResearchCostToUnlock = researchCostToUnlock;
        }
    }

    [Serializable]
    public class RivalCompany
    {
        public string Name;
        public double HashrateTH;
        public double Cash;
        public double EfficiencyJTH;
        public bool Acquired;

        public RivalCompany(string name, double hashrateTH, double cash, double efficiencyJTH)
        {
            Name = name;
            HashrateTH = hashrateTH;
            Cash = cash;
            EfficiencyJTH = efficiencyJTH;
            Acquired = false;
        }

        public double Value
        {
            get { return Cash + HashrateTH * Math.Max(2.0, 110.0 / Math.Max(1.0, EfficiencyJTH)); }
        }
    }

    public static class MiningMath
    {
        public const double BlocksPerDay = 144.0;

        public static double PowerKW(double hashrateTH, double efficiencyJTH)
        {
            return hashrateTH * efficiencyJTH / 1000.0;
        }

        public static double BitcoinPerDay(double playerHashrateTH, double networkHashrateTH, double blockSubsidy, double uptime)
        {
            if (networkHashrateTH <= 0.0) return 0.0;
            return (playerHashrateTH / networkHashrateTH) * BlocksPerDay * blockSubsidy * uptime;
        }

        public static double PowerCostPerDay(double hashrateTH, double efficiencyJTH, double electricityPerKWh, double uptime)
        {
            return PowerKW(hashrateTH, efficiencyJTH) * 24.0 * electricityPerKWh * uptime;
        }
    }

    public class HashRaceGame : MonoBehaviour
    {
        private readonly List<MinerGeneration> generations = new List<MinerGeneration>();
        private readonly List<RivalCompany> rivals = new List<RivalCompany>();
        private int[] fleet;

        private int unlockedGeneration;
        private double researchProgress;
        private double cash = 7500.0;
        private double bitcoinPrice = 1000.0;
        private double networkHashrateTH = 50000.0;
        private double blockSubsidy = 25.0;
        private double electricityPrice = 0.060;
        private double uptime = 0.96;
        private double gameDay;
        private double lastProcessedDay;
        private double speed = 1.0;
        private bool paused;
        private bool gameOver;
        private string eventText = "The race has started. Build a better mining company.";

        private const double BaseDaysPerSecond = 0.25;
        private readonly System.Random rng = new System.Random(21);

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void AutoStart()
        {
            if (FindFirstObjectByType<HashRaceGame>() != null) return;
            GameObject host = new GameObject("Hash Race Prototype");
            host.AddComponent<HashRaceGame>();
            DontDestroyOnLoad(host);
        }

        private void Awake()
        {
            BuildTechnologyTree();
            fleet = new int[generations.Count];
            fleet[0] = 3;

            rivals.Add(new RivalCompany("Northstar Mining", 18.0, 5000.0, 82.0));
            rivals.Add(new RivalCompany("VoltHash", 13.0, 7000.0, 74.0));
            rivals.Add(new RivalCompany("BlockWorks", 9.0, 9000.0, 68.0));
        }

        private void BuildTechnologyTree()
        {
            generations.Add(new MinerGeneration("Gen 1 Prototype", 5.0, 85.0, 650.0, 0.0));
            generations.Add(new MinerGeneration("Gen 2 Hashbox", 14.0, 60.0, 1500.0, 15000.0));
            generations.Add(new MinerGeneration("Gen 3 Performance ASIC", 45.0, 38.0, 3200.0, 50000.0));
            generations.Add(new MinerGeneration("Gen 4 Efficient ASIC", 110.0, 25.0, 5200.0, 150000.0));
            generations.Add(new MinerGeneration("Gen 5 Hydro ASIC", 250.0, 15.0, 9000.0, 450000.0));
            generations.Add(new MinerGeneration("Gen 6 PH Node", 1000.0, 8.0, 30000.0, 1500000.0));
            generations.Add(new MinerGeneration("Gen 7 10 PH Rack", 10000.0, 4.0, 220000.0, 8000000.0));
            generations.Add(new MinerGeneration("Gen 8 100 PH Core", 100000.0, 1.5, 1800000.0, 40000000.0));
            generations.Add(new MinerGeneration("Gen 9 EH Engine", 1000000.0, 0.75, 14000000.0, 150000000.0));
        }

        private void Update()
        {
            if (paused || gameOver) return;

            gameDay += Time.unscaledDeltaTime * BaseDaysPerSecond * speed;
            int wholeDay = (int)Math.Floor(gameDay);
            while (lastProcessedDay < wholeDay)
            {
                lastProcessedDay += 1.0;
                ProcessOneDay();
            }
        }

        private void ProcessOneDay()
        {
            double revenue = DailyRevenue();
            double power = DailyPowerCost();
            double operations = 2.0 * TotalMachineCount() + TotalHashrateTH() * 0.005;
            cash += revenue - power - operations;

            MoveMarket();
            MoveRivals();
            CheckMilestones();

            if (cash < -25000.0)
            {
                gameOver = true;
                eventText = "Company failed. Your debt passed $25,000.";
            }
        }

        private void MoveMarket()
        {
            double priceMove = (rng.NextDouble() - 0.48) * 0.035;
            bitcoinPrice = Math.Max(50.0, bitcoinPrice * (1.0 + priceMove));

            double networkMove = 0.001 + rng.NextDouble() * 0.004;
            networkHashrateTH *= 1.0 + networkMove;

            double powerMove = (rng.NextDouble() - 0.50) * 0.004;
            electricityPrice = Math.Max(0.015, Math.Min(0.20, electricityPrice + powerMove));
        }

        private void MoveRivals()
        {
            for (int i = 0; i < rivals.Count; i++)
            {
                RivalCompany rival = rivals[i];
                if (rival.Acquired) continue;

                double btc = MiningMath.BitcoinPerDay(rival.HashrateTH, networkHashrateTH, blockSubsidy, 0.94);
                double revenue = btc * bitcoinPrice;
                double power = MiningMath.PowerCostPerDay(rival.HashrateTH, rival.EfficiencyJTH, electricityPrice, 0.94);
                rival.Cash += revenue - power - rival.HashrateTH * 0.01;

                if (rival.Cash > 2500.0 && rng.NextDouble() < 0.20)
                {
                    double spend = Math.Min(rival.Cash * 0.12, 5000.0 + rival.HashrateTH * 2.0);
                    rival.Cash -= spend;
                    rival.HashrateTH += Math.Max(1.0, spend / Math.Max(20.0, rival.EfficiencyJTH));
                }

                if (rng.NextDouble() < 0.025)
                {
                    rival.EfficiencyJTH = Math.Max(0.65, rival.EfficiencyJTH * 0.97);
                }
            }
        }

        private void CheckMilestones()
        {
            double hash = TotalHashrateTH();
            if (hash >= 1000000.0)
                eventText = "1 EH/s reached. You built an exahash-scale mining company.";
            else if (hash >= 100000.0)
                eventText = "100 PH/s reached. Hash Race has entered hyperscale territory.";
            else if (hash >= 10000.0)
                eventText = "10 PH/s reached. Your fleet is becoming industrial scale.";
            else if (hash >= 1000.0)
                eventText = "1 PH/s reached. First major hashrate milestone cleared.";
        }

        private double TotalHashrateTH()
        {
            double total = 0.0;
            for (int i = 0; i < fleet.Length; i++) total += fleet[i] * generations[i].HashrateTH;
            return total;
        }

        private double TotalPowerKW()
        {
            double total = 0.0;
            for (int i = 0; i < fleet.Length; i++)
                total += fleet[i] * MiningMath.PowerKW(generations[i].HashrateTH, generations[i].EfficiencyJTH);
            return total;
        }

        private double FleetEfficiencyJTH()
        {
            double hash = TotalHashrateTH();
            if (hash <= 0.0) return 0.0;
            return TotalPowerKW() * 1000.0 / hash;
        }

        private int TotalMachineCount()
        {
            int total = 0;
            for (int i = 0; i < fleet.Length; i++) total += fleet[i];
            return total;
        }

        private double DailyBitcoin()
        {
            return MiningMath.BitcoinPerDay(TotalHashrateTH(), networkHashrateTH, blockSubsidy, uptime);
        }

        private double DailyRevenue()
        {
            return DailyBitcoin() * bitcoinPrice;
        }

        private double DailyPowerCost()
        {
            double cost = 0.0;
            for (int i = 0; i < fleet.Length; i++)
            {
                if (fleet[i] <= 0) continue;
                cost += fleet[i] * MiningMath.PowerCostPerDay(generations[i].HashrateTH, generations[i].EfficiencyJTH, electricityPrice, uptime);
            }
            return cost;
        }

        private double CompanyValue()
        {
            double hardware = 0.0;
            for (int i = 0; i < fleet.Length; i++) hardware += fleet[i] * generations[i].PurchasePrice * 0.55;
            return Math.Max(0.0, cash) + hardware + researchProgress * 0.5;
        }

        private void BuyCurrentMiner()
        {
            MinerGeneration miner = generations[unlockedGeneration];
            if (cash < miner.PurchasePrice)
            {
                eventText = "Not enough cash to buy " + miner.Name + ".";
                return;
            }

            cash -= miner.PurchasePrice;
            fleet[unlockedGeneration] += 1;
            eventText = miner.Name + " added to the fleet.";
        }

        private void SellNewestMiner()
        {
            for (int i = fleet.Length - 1; i >= 0; i--)
            {
                if (fleet[i] <= 0) continue;
                fleet[i] -= 1;
                double resale = generations[i].PurchasePrice * 0.40;
                cash += resale;
                eventText = generations[i].Name + " sold for " + Money(resale) + ".";
                return;
            }
            eventText = "There are no miners to sell.";
        }

        private void FundResearch()
        {
            if (unlockedGeneration >= generations.Count - 1)
            {
                eventText = "All prototype hardware generations are unlocked.";
                return;
            }

            double target = generations[unlockedGeneration + 1].ResearchCostToUnlock;
            double remaining = target - researchProgress;
            double spend = Math.Min(cash, Math.Min(remaining, Math.Max(1000.0, target * 0.20)));
            if (spend <= 0.0)
            {
                eventText = "No cash is available for R&D.";
                return;
            }

            cash -= spend;
            researchProgress += spend;

            if (researchProgress >= target)
            {
                researchProgress = 0.0;
                unlockedGeneration += 1;
                eventText = "EVOLUTION UNLOCKED: " + generations[unlockedGeneration].Name + " — " + generations[unlockedGeneration].HashrateTH.ToString("N0") + " TH/s at " + generations[unlockedGeneration].EfficiencyJTH.ToString("0.##") + " J/TH.";
            }
            else
            {
                eventText = "R&D funded with " + Money(spend) + ".";
            }
        }

        private void TryAcquire(RivalCompany rival)
        {
            if (rival.Acquired) return;
            double price = rival.Value * 1.15;
            if (cash < price)
            {
                eventText = "You need " + Money(price) + " to acquire " + rival.Name + ".";
                return;
            }

            cash -= price;
            rival.Acquired = true;
            double purchasedHash = rival.HashrateTH;
            int current = unlockedGeneration;
            double units = purchasedHash / Math.Max(1.0, generations[current].HashrateTH);
            fleet[current] += Math.Max(1, (int)Math.Round(units));
            eventText = rival.Name + " acquired. Its mining capacity has joined your company.";
        }

        private string Hashrate(double th)
        {
            if (th >= 1000000.0) return (th / 1000000.0).ToString("0.###") + " EH/s";
            if (th >= 1000.0) return (th / 1000.0).ToString("0.###") + " PH/s";
            return th.ToString("0.##") + " TH/s";
        }

        private string Money(double value)
        {
            return "$" + value.ToString("N0");
        }

        private void OnGUI()
        {
            GUI.skin.label.fontSize = 16;
            GUI.skin.button.fontSize = 15;
            GUI.skin.box.fontSize = 18;

            float margin = 18f;
            float width = Mathf.Min(Screen.width - margin * 2f, 1180f);
            GUILayout.BeginArea(new Rect(margin, margin, width, Screen.height - margin * 2f));

            GUILayout.BeginHorizontal();
            GUILayout.Label("HASH RACE", GUILayout.Width(180));
            GUILayout.Label("Day " + gameDay.ToString("0.0"), GUILayout.Width(110));
            GUILayout.Label("Cash " + Money(cash), GUILayout.Width(180));
            GUILayout.Label("Value " + Money(CompanyValue()), GUILayout.Width(190));
            GUILayout.FlexibleSpace();
            if (GUILayout.Button(paused ? "Resume" : "Pause", GUILayout.Width(90))) paused = !paused;
            if (GUILayout.Button("1x", GUILayout.Width(55))) speed = 1.0;
            if (GUILayout.Button("5x", GUILayout.Width(55))) speed = 5.0;
            if (GUILayout.Button("20x", GUILayout.Width(55))) speed = 20.0;
            GUILayout.EndHorizontal();

            GUILayout.Space(8);
            GUILayout.Box(eventText, GUILayout.ExpandWidth(true), GUILayout.Height(40));
            GUILayout.Space(8);

            GUILayout.BeginHorizontal();

            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.34f));
            GUILayout.Label("YOUR MINING COMPANY");
            GUILayout.Label("Hashrate: " + Hashrate(TotalHashrateTH()));
            GUILayout.Label("Fleet efficiency: " + FleetEfficiencyJTH().ToString("0.##") + " J/TH");
            GUILayout.Label("Power: " + TotalPowerKW().ToString("N1") + " kW");
            GUILayout.Label("Machines: " + TotalMachineCount());
            GUILayout.Label("Uptime: " + (uptime * 100.0).ToString("0.0") + "%");
            GUILayout.Space(8);
            GUILayout.Label("BTC/day: " + DailyBitcoin().ToString("0.000000"));
            GUILayout.Label("Revenue/day: " + Money(DailyRevenue()));
            GUILayout.Label("Power/day: " + Money(DailyPowerCost()));
            GUILayout.Label("Electricity: $" + electricityPrice.ToString("0.000") + "/kWh");
            GUILayout.Space(12);

            MinerGeneration current = generations[unlockedGeneration];
            GUILayout.Label("CURRENT ASIC");
            GUILayout.Label(current.Name);
            GUILayout.Label(Hashrate(current.HashrateTH) + " each");
            GUILayout.Label(current.EfficiencyJTH.ToString("0.##") + " J/TH");
            GUILayout.Label("Price: " + Money(current.PurchasePrice));
            if (GUILayout.Button("Buy Miner")) BuyCurrentMiner();
            if (GUILayout.Button("Sell Newest Miner")) SellNewestMiner();
            GUILayout.EndVertical();

            GUILayout.Space(8);

            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.31f));
            GUILayout.Label("HARDWARE EVOLUTION");
            for (int i = 0; i < generations.Count; i++)
            {
                MinerGeneration g = generations[i];
                string marker = i < unlockedGeneration ? "✓" : (i == unlockedGeneration ? ">" : "LOCK");
                string owned = fleet[i] > 0 ? " x" + fleet[i] : "";
                GUILayout.Label(marker + "  " + g.Name + owned + "\n     " + Hashrate(g.HashrateTH) + " | " + g.EfficiencyJTH.ToString("0.##") + " J/TH");
            }

            GUILayout.Space(8);
            if (unlockedGeneration < generations.Count - 1)
            {
                double target = generations[unlockedGeneration + 1].ResearchCostToUnlock;
                GUILayout.Label("Next R&D: " + generations[unlockedGeneration + 1].Name);
                GUILayout.Label(Money(researchProgress) + " / " + Money(target));
                if (GUILayout.Button("Fund R&D")) FundResearch();
            }
            else
            {
                GUILayout.Label("All prototype generations unlocked.");
            }
            GUILayout.EndVertical();

            GUILayout.Space(8);

            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.31f));
            GUILayout.Label("THE RACE");
            GUILayout.Label("BTC price: " + Money(bitcoinPrice));
            GUILayout.Label("Network: " + Hashrate(networkHashrateTH));
            GUILayout.Label("Block subsidy: " + blockSubsidy.ToString("0.###") + " BTC");
            GUILayout.Space(10);

            for (int i = 0; i < rivals.Count; i++)
            {
                RivalCompany rival = rivals[i];
                if (rival.Acquired)
                {
                    GUILayout.Label(rival.Name + " — ACQUIRED");
                    continue;
                }

                GUILayout.Label(rival.Name);
                GUILayout.Label("  " + Hashrate(rival.HashrateTH) + " | " + rival.EfficiencyJTH.ToString("0.##") + " J/TH");
                GUILayout.Label("  Value: " + Money(rival.Value));
                if (GUILayout.Button("Acquire " + rival.Name)) TryAcquire(rival);
                GUILayout.Space(6);
            }
            GUILayout.EndVertical();

            GUILayout.EndHorizontal();

            if (gameOver)
            {
                GUILayout.Space(12);
                GUILayout.Box("GAME OVER — restart Play Mode to begin a new company.", GUILayout.Height(45));
            }

            GUILayout.EndArea();
        }
    }
}
