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
    public class CompanyProfile
    {
        public string Name;
        public string Sector;
        public string Trait;
        public string PartnershipAffinity;
        public double StartingCash;
        public int StartingFleet;
        public double EfficiencyMultiplier;
        public double PowerCostMultiplier;
        public double ResearchMultiplier;
        public double AcquisitionCostMultiplier;
        public double UptimeBonus;
        public double StartingSiteMW;

        public CompanyProfile(string name, string sector, string trait, string partnershipAffinity,
            double startingCash, int startingFleet, double efficiencyMultiplier, double powerCostMultiplier,
            double researchMultiplier, double acquisitionCostMultiplier, double uptimeBonus, double startingSiteMW)
        {
            Name = name;
            Sector = sector;
            Trait = trait;
            PartnershipAffinity = partnershipAffinity;
            StartingCash = startingCash;
            StartingFleet = startingFleet;
            EfficiencyMultiplier = efficiencyMultiplier;
            PowerCostMultiplier = powerCostMultiplier;
            ResearchMultiplier = researchMultiplier;
            AcquisitionCostMultiplier = acquisitionCostMultiplier;
            UptimeBonus = uptimeBonus;
            StartingSiteMW = startingSiteMW;
        }
    }

    [Serializable]
    public class StrategicPartnership
    {
        public string Sector;
        public string PartnerName;
        public string Benefit;
        public double Cost;
        public double RequiredValue;
        public int RequiredGeneration;
        public bool Active;

        public StrategicPartnership(string sector, string partnerName, string benefit, double cost, double requiredValue, int requiredGeneration)
        {
            Sector = sector;
            PartnerName = partnerName;
            Benefit = benefit;
            Cost = cost;
            RequiredValue = requiredValue;
            RequiredGeneration = requiredGeneration;
        }
    }

    [Serializable]
    public class RivalCompany
    {
        public CompanyProfile Profile;
        public double HashrateTH;
        public double Cash;
        public double EfficiencyJTH;
        public string Partnership;
        public bool Acquired;
        public int Generation;

        public RivalCompany(CompanyProfile profile, double hashrateTH, double cash, double efficiencyJTH)
        {
            Profile = profile;
            HashrateTH = hashrateTH;
            Cash = cash;
            EfficiencyJTH = efficiencyJTH;
            Partnership = "None";
            Acquired = false;
            Generation = 0;
        }

        public double Value
        {
            get
            {
                double technologyPremium = Math.Max(2.0, 125.0 / Math.Max(0.5, EfficiencyJTH));
                double partnershipPremium = Partnership == "None" ? 1.0 : 1.12;
                return Math.Max(0.0, Cash) + HashrateTH * technologyPremium * partnershipPremium;
            }
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
        private readonly List<CompanyProfile> companyProfiles = new List<CompanyProfile>();
        private readonly List<StrategicPartnership> partnerships = new List<StrategicPartnership>();
        private readonly List<RivalCompany> rivals = new List<RivalCompany>();

        private CompanyProfile playerCompany;
        private int[] fleet;
        private int unlockedGeneration;
        private double researchProgress;
        private double cash;
        private double bitcoinPrice = 1000.0;
        private double networkHashrateTH = 50000.0;
        private double blockSubsidy = 25.0;
        private double electricityPrice = 0.060;
        private double baseUptime = 0.955;
        private double siteCapacityMW;
        private int siteExpansionLevel;
        private int acquisitions;
        private double gameDay;
        private double lastProcessedDay;
        private double speed = 1.0;
        private bool paused;
        private bool gameOver;
        private bool companySelected;
        private int strategyView;
        private int lastSeason = 1;
        private string eventText = "Choose a company and enter the Hash Race.";
        private Vector2 companyScroll;
        private Vector2 rivalScroll;
        private Vector2 partnershipScroll;

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
            BuildCompanyProfiles();
            BuildPartnershipTree();
            fleet = new int[generations.Count];
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

        private void BuildCompanyProfiles()
        {
            companyProfiles.Add(new CompanyProfile("BlockForge Mining", "Bitcoin Mining", "Fleet-first operator: starts with more miners and cheaper power.", "Energy", 8000, 5, 1.00, 0.90, 0.95, 1.00, 0.000, 0.050));
            companyProfiles.Add(new CompanyProfile("NeuralPeak Compute", "AI Compute", "Research-heavy compute company with strong R&D but a smaller starting fleet.", "AI", 11000, 2, 0.98, 1.05, 1.25, 1.00, 0.000, 0.045));
            companyProfiles.Add(new CompanyProfile("Atlas Robotics", "Robotics", "Automation specialist with higher uptime and lower operating friction.", "Robotics", 9000, 3, 1.00, 1.00, 1.05, 1.00, 0.020, 0.045));
            companyProfiles.Add(new CompanyProfile("VoltRiver Energy", "Energy", "Power-market specialist with the lowest starting electricity burden.", "Energy", 8500, 3, 1.02, 0.76, 0.90, 1.00, 0.000, 0.070));
            companyProfiles.Add(new CompanyProfile("SilicaWorks", "Semiconductors", "Chip specialist whose miners run more efficiently and whose research moves quickly.", "Semiconductor", 7500, 3, 0.90, 1.02, 1.15, 1.00, 0.000, 0.040));
            companyProfiles.Add(new CompanyProfile("CoreVector Systems", "CPU and Systems", "Balanced systems company with dependable efficiency, research, and site growth.", "Semiconductor", 10000, 3, 0.96, 0.98, 1.08, 0.98, 0.005, 0.055));
            companyProfiles.Add(new CompanyProfile("SkyStack Compute", "Cloud Infrastructure", "Large-site operator that can scale facilities earlier than most rivals.", "Infrastructure", 10500, 3, 1.00, 1.00, 1.00, 1.00, 0.005, 0.100));
            companyProfiles.Add(new CompanyProfile("IonDrive Automation", "Autonomy and Tech", "Fast-moving technology company with strong uptime and partnership flexibility.", "Robotics", 9500, 3, 0.97, 1.00, 1.10, 1.00, 0.015, 0.050));
            companyProfiles.Add(new CompanyProfile("OpenCircuit Labs", "Open Technology", "Open engineering lab with the fastest base research but less starting money.", "AI", 6000, 3, 1.00, 1.00, 1.35, 1.00, 0.000, 0.040));
            companyProfiles.Add(new CompanyProfile("Frontier Holdings", "Capital and Acquisitions", "Deal-focused holding company with more cash and cheaper company buyouts.", "Finance", 18000, 2, 1.04, 1.02, 0.90, 0.78, 0.000, 0.045));
        }

        private void BuildPartnershipTree()
        {
            partnerships.Add(new StrategicPartnership("AI", "Neural Compute Alliance", "35% faster R&D and 10% more revenue from compute contracts.", 30000, 20000, 1));
            partnerships.Add(new StrategicPartnership("Robotics", "Autonomous Operations Group", "+2% uptime and 25% lower operating costs.", 45000, 30000, 1));
            partnerships.Add(new StrategicPartnership("Energy", "Grid Power Consortium", "22% lower effective electricity cost.", 50000, 40000, 2));
            partnerships.Add(new StrategicPartnership("Semiconductor", "Advanced Foundry Access", "10% better ASIC J/TH and 15% faster R&D.", 80000, 70000, 2));
            partnerships.Add(new StrategicPartnership("Finance", "Strategic Capital Partners", "20% cheaper acquisitions and stronger deal access.", 100000, 90000, 3));
            partnerships.Add(new StrategicPartnership("Infrastructure", "Hyperscale Infrastructure Pact", "35% more site capacity and 25% cheaper expansions.", 125000, 120000, 3));
        }

        private void SelectCompany(CompanyProfile profile)
        {
            playerCompany = profile;
            companySelected = true;
            cash = profile.StartingCash;
            siteCapacityMW = profile.StartingSiteMW;
            baseUptime = Math.Min(0.985, 0.955 + profile.UptimeBonus);
            fleet = new int[generations.Count];
            fleet[0] = profile.StartingFleet;
            unlockedGeneration = 0;
            researchProgress = 0.0;
            acquisitions = 0;
            siteExpansionLevel = 0;
            gameDay = 0.0;
            lastProcessedDay = 0.0;
            lastSeason = 1;
            rivals.Clear();

            for (int i = 0; i < partnerships.Count; i++) partnerships[i].Active = false;

            for (int i = 0; i < companyProfiles.Count; i++)
            {
                CompanyProfile rivalProfile = companyProfiles[i];
                if (rivalProfile == profile) continue;
                double rivalHash = rivalProfile.StartingFleet * generations[0].HashrateTH * (0.90 + rng.NextDouble() * 0.30);
                double rivalCash = rivalProfile.StartingCash * (0.80 + rng.NextDouble() * 0.35);
                double rivalEfficiency = generations[0].EfficiencyJTH * rivalProfile.EfficiencyMultiplier;
                rivals.Add(new RivalCompany(rivalProfile, rivalHash, rivalCash, rivalEfficiency));
            }

            eventText = profile.Name + " entered the Hash Race. Build the strongest technology empire.";
        }

        private void Update()
        {
            if (!companySelected || paused || gameOver) return;

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
            double operations = DailyOperatingCost();
            cash += revenue - power - operations;

            MoveMarket();
            MoveRivals();

            int day = (int)lastProcessedDay;
            if (day > 0 && day % 30 == 0) ProcessWorldEvent();
            CheckSeasonChange();
            CheckMilestones();

            if (cash < -25000.0)
            {
                gameOver = true;
                eventText = "Company failed. Debt passed $25,000.";
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

                double rivalUptime = Math.Min(0.99, 0.945 + rival.Profile.UptimeBonus);
                double rivalPowerPrice = electricityPrice * rival.Profile.PowerCostMultiplier;
                double btc = MiningMath.BitcoinPerDay(rival.HashrateTH, networkHashrateTH, blockSubsidy, rivalUptime);
                double revenue = btc * bitcoinPrice;
                double power = MiningMath.PowerCostPerDay(rival.HashrateTH, rival.EfficiencyJTH, rivalPowerPrice, rivalUptime);
                rival.Cash += revenue - power - rival.HashrateTH * 0.008;

                double growthChance = 0.12 + rival.Profile.ResearchMultiplier * 0.06;
                if (rival.Cash > 2500.0 && rng.NextDouble() < growthChance)
                {
                    double spend = Math.Min(rival.Cash * 0.10, 4500.0 + rival.HashrateTH * 2.0);
                    rival.Cash -= spend;
                    rival.HashrateTH += Math.Max(1.0, spend / Math.Max(15.0, rival.EfficiencyJTH));
                }

                if (rng.NextDouble() < 0.018 * rival.Profile.ResearchMultiplier)
                {
                    rival.EfficiencyJTH = Math.Max(0.65, rival.EfficiencyJTH * 0.965);
                    rival.Generation = Math.Min(generations.Count - 1, rival.Generation + 1);
                }

                if (rival.Partnership == "None" && lastProcessedDay > 45 && rival.Cash > 15000 && rng.NextDouble() < 0.008)
                {
                    rival.Partnership = rival.Profile.PartnershipAffinity;
                    ApplyRivalPartnership(rival);
                }
            }
        }

        private void ApplyRivalPartnership(RivalCompany rival)
        {
            if (rival.Partnership == "AI") rival.Cash += 5000.0;
            else if (rival.Partnership == "Robotics") rival.HashrateTH *= 1.05;
            else if (rival.Partnership == "Energy") rival.Cash += 3500.0;
            else if (rival.Partnership == "Semiconductor") rival.EfficiencyJTH *= 0.93;
            else if (rival.Partnership == "Finance") rival.Cash += 9000.0;
            else if (rival.Partnership == "Infrastructure") rival.HashrateTH *= 1.10;
        }

        private void ProcessWorldEvent()
        {
            int eventId = rng.Next(0, 6);
            double scale = Math.Max(1000.0, CompanyValue() * 0.015);

            if (eventId == 0)
            {
                double bonus = scale * (HasPartnership("AI") ? 1.6 : 1.0);
                cash += bonus;
                eventText = "WORLD EVENT: AI compute demand jumped. A short contract paid " + Money(bonus) + ".";
            }
            else if (eventId == 1)
            {
                double bonus = scale * (HasPartnership("Energy") ? 1.5 : 1.0);
                cash += bonus;
                eventText = "WORLD EVENT: The grid paid your company to manage load. You earned " + Money(bonus) + ".";
            }
            else if (eventId == 2)
            {
                double research = scale * (HasPartnership("Semiconductor") ? 1.5 : 1.0);
                researchProgress += research;
                eventText = "WORLD EVENT: A chip breakthrough added " + Money(research) + " of R&D progress.";
            }
            else if (eventId == 3)
            {
                double cost = scale * (HasPartnership("Robotics") ? 0.45 : 1.0);
                cash -= cost;
                eventText = "WORLD EVENT: Maintenance problems cost " + Money(cost) + ". Robotics can reduce future hits.";
            }
            else if (eventId == 4)
            {
                double addedMW = HasPartnership("Infrastructure") ? 0.030 : 0.015;
                siteCapacityMW += addedMW;
                eventText = "WORLD EVENT: A regional development deal added " + addedMW.ToString("0.000") + " MW of site capacity.";
            }
            else
            {
                double deal = scale * (HasPartnership("Finance") ? 1.7 : 1.0);
                cash += deal;
                eventText = "WORLD EVENT: Investors backed your expansion with " + Money(deal) + ".";
            }
        }

        private void CheckSeasonChange()
        {
            int season = CurrentSeason();
            if (season == lastSeason) return;
            int oldRank = PlayerLeagueRank();
            lastSeason = season;
            cash += Math.Max(0.0, 12000.0 - (oldRank - 1) * 900.0);
            eventText = "SEASON " + season + " START: You finished the last season ranked #" + oldRank + ". Franchise rating: " + FranchiseRating() + ".";
        }

        private int CurrentSeason()
        {
            return 1 + (int)(gameDay / 365.0);
        }

        private void CheckMilestones()
        {
            double hash = TotalHashrateTH();
            if (hash >= 1000000.0 && PlayerLeagueRank() == 1 && ActivePartnershipCount() >= 3)
                eventText = "DYNASTY MILESTONE: #1 company, 1 EH/s, and three strategic partnerships.";
            else if (hash >= 1000000.0)
                eventText = "1 EH/s reached. The company is now exahash scale.";
            else if (hash >= 100000.0)
                eventText = "100 PH/s reached. Hash Race has entered hyperscale territory.";
            else if (hash >= 10000.0)
                eventText = "10 PH/s reached. Your fleet is becoming industrial scale.";
            else if (hash >= 1000.0)
                eventText = "1 PH/s reached. First major hashrate milestone cleared.";
        }

        private string CurrentEra()
        {
            if (unlockedGeneration <= 1) return "Garage Era";
            if (unlockedGeneration <= 3) return "Industrial ASIC Era";
            if (unlockedGeneration <= 5) return "Infrastructure Era";
            if (unlockedGeneration <= 7) return "Hyperscale Era";
            return "Exahash Era";
        }

        private double EffectiveEfficiency(MinerGeneration generation)
        {
            double value = generation.EfficiencyJTH * playerCompany.EfficiencyMultiplier;
            if (HasPartnership("Semiconductor")) value *= 0.90;
            return Math.Max(0.25, value);
        }

        private double EffectiveElectricityPrice()
        {
            double value = electricityPrice * playerCompany.PowerCostMultiplier;
            if (HasPartnership("Energy")) value *= 0.78;
            return Math.Max(0.005, value);
        }

        private double EffectiveUptime()
        {
            double value = baseUptime;
            if (HasPartnership("Robotics")) value += 0.020;
            return Math.Min(0.999, value);
        }

        private double ResearchMultiplier()
        {
            double value = playerCompany.ResearchMultiplier;
            if (HasPartnership("AI")) value *= 1.35;
            if (HasPartnership("Semiconductor")) value *= 1.15;
            if (playerCompany.PartnershipAffinity == "AI" && HasPartnership("AI")) value *= 1.08;
            return value;
        }

        private double RevenueMultiplier()
        {
            double value = 1.0;
            if (HasPartnership("AI")) value *= 1.10;
            return value;
        }

        private double AcquisitionMultiplier()
        {
            double value = playerCompany.AcquisitionCostMultiplier;
            if (HasPartnership("Finance")) value *= 0.80;
            if (playerCompany.PartnershipAffinity == "Finance" && HasPartnership("Finance")) value *= 0.92;
            return value;
        }

        private double SiteCapacityEffectiveMW()
        {
            return siteCapacityMW * (HasPartnership("Infrastructure") ? 1.35 : 1.0);
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
                total += fleet[i] * MiningMath.PowerKW(generations[i].HashrateTH, EffectiveEfficiency(generations[i]));
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
            return MiningMath.BitcoinPerDay(TotalHashrateTH(), networkHashrateTH, blockSubsidy, EffectiveUptime());
        }

        private double DailyRevenue()
        {
            return DailyBitcoin() * bitcoinPrice * RevenueMultiplier();
        }

        private double DailyPowerCost()
        {
            double cost = 0.0;
            for (int i = 0; i < fleet.Length; i++)
            {
                if (fleet[i] <= 0) continue;
                cost += fleet[i] * MiningMath.PowerCostPerDay(generations[i].HashrateTH, EffectiveEfficiency(generations[i]), EffectiveElectricityPrice(), EffectiveUptime());
            }
            return cost;
        }

        private double DailyOperatingCost()
        {
            double cost = 2.0 * TotalMachineCount() + TotalHashrateTH() * 0.005;
            if (HasPartnership("Robotics")) cost *= 0.75;
            return cost;
        }

        private double CompanyValue()
        {
            double hardware = 0.0;
            for (int i = 0; i < fleet.Length; i++) hardware += fleet[i] * generations[i].PurchasePrice * 0.55;
            double partnerValue = ActivePartnershipCount() * 15000.0;
            double siteValue = SiteCapacityEffectiveMW() * 250000.0;
            return Math.Max(0.0, cash) + hardware + researchProgress * 0.5 + partnerValue + siteValue;
        }

        private int FranchiseRating()
        {
            double hashScore = Math.Min(20.0, Math.Log10(Math.Max(1.0, TotalHashrateTH())) * 5.0);
            double techScore = unlockedGeneration * 3.0;
            double efficiencyScore = Math.Max(0.0, 20.0 - FleetEfficiencyJTH() * 0.18);
            double partnerScore = ActivePartnershipCount() * 3.0;
            double valueScore = Math.Min(15.0, Math.Log10(Math.Max(10.0, CompanyValue())) * 2.5);
            return (int)Math.Max(40.0, Math.Min(99.0, 42.0 + hashScore + techScore + efficiencyScore + partnerScore + valueScore));
        }

        private int RivalRating(RivalCompany rival)
        {
            double hashScore = Math.Min(22.0, Math.Log10(Math.Max(1.0, rival.HashrateTH)) * 5.0);
            double techScore = rival.Generation * 3.0;
            double efficiencyScore = Math.Max(0.0, 18.0 - rival.EfficiencyJTH * 0.15);
            double partnerScore = rival.Partnership == "None" ? 0.0 : 4.0;
            return (int)Math.Max(40.0, Math.Min(99.0, 43.0 + hashScore + techScore + efficiencyScore + partnerScore));
        }

        private int PlayerLeagueRank()
        {
            int rank = 1;
            double playerValue = CompanyValue();
            for (int i = 0; i < rivals.Count; i++)
            {
                if (!rivals[i].Acquired && rivals[i].Value > playerValue) rank++;
            }
            return rank;
        }

        private int ActivePartnershipCount()
        {
            int count = 0;
            for (int i = 0; i < partnerships.Count; i++) if (partnerships[i].Active) count++;
            return count;
        }

        private bool HasPartnership(string sector)
        {
            for (int i = 0; i < partnerships.Count; i++)
            {
                if (partnerships[i].Active && partnerships[i].Sector == sector) return true;
            }
            return false;
        }

        private void BuyCurrentMiner()
        {
            MinerGeneration miner = generations[unlockedGeneration];
            double addedPowerKW = MiningMath.PowerKW(miner.HashrateTH, EffectiveEfficiency(miner));
            if ((TotalPowerKW() + addedPowerKW) / 1000.0 > SiteCapacityEffectiveMW())
            {
                eventText = "SITE FULL: Expand power capacity before adding another " + miner.Name + ".";
                return;
            }
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
            double remainingRawSpend = Math.Max(0.0, (target - researchProgress) / Math.Max(0.01, ResearchMultiplier()));
            double suggested = Math.Max(1000.0, target * 0.16);
            double spend = Math.Min(cash, Math.Min(remainingRawSpend, suggested));
            if (spend <= 0.0)
            {
                eventText = "No cash is available for R&D.";
                return;
            }

            cash -= spend;
            researchProgress += spend * ResearchMultiplier();

            if (researchProgress >= target)
            {
                researchProgress = 0.0;
                unlockedGeneration += 1;
                eventText = "NEW ERA TECH: " + generations[unlockedGeneration].Name + " unlocked at " + EffectiveEfficiency(generations[unlockedGeneration]).ToString("0.##") + " J/TH.";
            }
            else
            {
                eventText = "R&D funded with " + Money(spend) + ". Effective progress: " + Money(spend * ResearchMultiplier()) + ".";
            }
        }

        private void ExpandSite()
        {
            double cost = 15000.0 * Math.Pow(1.85, siteExpansionLevel);
            if (HasPartnership("Infrastructure")) cost *= 0.75;
            if (cash < cost)
            {
                eventText = "You need " + Money(cost) + " to expand the site.";
                return;
            }
            cash -= cost;
            siteExpansionLevel++;
            double added = 0.05 * Math.Pow(1.55, Math.Min(8, siteExpansionLevel - 1));
            siteCapacityMW += added;
            eventText = "SITE EXPANDED: Added " + added.ToString("0.000") + " MW of base capacity.";
        }

        private void SignPartnership(StrategicPartnership partnership)
        {
            if (partnership.Active) return;
            if (CompanyValue() < partnership.RequiredValue || unlockedGeneration < partnership.RequiredGeneration)
            {
                eventText = partnership.Sector + " partnership is locked. Grow company value and technology first.";
                return;
            }
            if (cash < partnership.Cost)
            {
                eventText = "You need " + Money(partnership.Cost) + " to sign " + partnership.PartnerName + ".";
                return;
            }

            cash -= partnership.Cost;
            partnership.Active = true;
            eventText = "PARTNERSHIP SIGNED: " + partnership.PartnerName + ". " + partnership.Benefit;
        }

        private void TryAcquire(RivalCompany rival)
        {
            if (rival.Acquired) return;
            double price = rival.Value * 1.15 * AcquisitionMultiplier();
            if (cash < price)
            {
                eventText = "You need " + Money(price) + " to acquire " + rival.Profile.Name + ".";
                return;
            }

            cash -= price;
            rival.Acquired = true;
            acquisitions++;
            double purchasedHash = rival.HashrateTH;
            int current = unlockedGeneration;
            double units = purchasedHash / Math.Max(1.0, generations[current].HashrateTH);
            fleet[current] += Math.Max(1, (int)Math.Round(units));
            siteCapacityMW += Math.Max(0.01, purchasedHash * rival.EfficiencyJTH / 1000000.0);
            eventText = rival.Profile.Name + " acquired. Its mining fleet and part of its infrastructure joined your empire.";
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

        private void DrawCompanySelection(float width)
        {
            GUILayout.Label("HASH RACE", GUI.skin.box, GUILayout.Height(46));
            GUILayout.Label("Choose your company. Each franchise starts with a different strategy, just like choosing a civilization, team, or business empire.");
            GUILayout.Space(8);

            companyScroll = GUILayout.BeginScrollView(companyScroll);
            for (int i = 0; i < companyProfiles.Count; i++)
            {
                CompanyProfile profile = companyProfiles[i];
                GUILayout.BeginVertical(GUI.skin.box);
                GUILayout.Label((i + 1) + ". " + profile.Name + " — " + profile.Sector);
                GUILayout.Label(profile.Trait);
                GUILayout.Label("Affinity: " + profile.PartnershipAffinity + " | Cash: " + Money(profile.StartingCash) + " | Miners: " + profile.StartingFleet + " | Site: " + profile.StartingSiteMW.ToString("0.000") + " MW");
                if (GUILayout.Button("Start as " + profile.Name, GUILayout.Height(30))) SelectCompany(profile);
                GUILayout.EndVertical();
                GUILayout.Space(4);
            }
            GUILayout.EndScrollView();
        }

        private void DrawFranchisePanel(float width)
        {
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.31f));
            GUILayout.Label(playerCompany.Name.ToUpper());
            GUILayout.Label(playerCompany.Sector + " | " + CurrentEra());
            GUILayout.Label("Franchise rating: " + FranchiseRating() + " OVR");
            GUILayout.Label("League rank: #" + PlayerLeagueRank() + " of " + (10 - acquisitions));
            GUILayout.Label("Season: " + CurrentSeason());
            GUILayout.Label("Acquisitions: " + acquisitions);
            GUILayout.Label("Partnerships: " + ActivePartnershipCount());
            GUILayout.Space(8);
            GUILayout.Label("Hashrate: " + Hashrate(TotalHashrateTH()));
            GUILayout.Label("Fleet efficiency: " + FleetEfficiencyJTH().ToString("0.##") + " J/TH");
            GUILayout.Label("Power: " + TotalPowerKW().ToString("N1") + " kW");
            GUILayout.Label("Site: " + SiteCapacityEffectiveMW().ToString("0.000") + " MW");
            GUILayout.Label("Uptime: " + (EffectiveUptime() * 100.0).ToString("0.0") + "%");
            GUILayout.Label("Machines: " + TotalMachineCount());
            GUILayout.Space(8);
            GUILayout.Label("Revenue/day: " + Money(DailyRevenue()));
            GUILayout.Label("Power/day: " + Money(DailyPowerCost()));
            GUILayout.Label("Ops/day: " + Money(DailyOperatingCost()));
            GUILayout.Label("Electricity: $" + EffectiveElectricityPrice().ToString("0.000") + "/kWh");
            GUILayout.Space(8);
            if (GUILayout.Button("Expand Site")) ExpandSite();
            GUILayout.EndVertical();
        }

        private void DrawTechnologyPanel(float width)
        {
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.34f));
            GUILayout.Label("HARDWARE + R&D");
            MinerGeneration current = generations[unlockedGeneration];
            GUILayout.Label("Current: " + current.Name);
            GUILayout.Label(Hashrate(current.HashrateTH) + " each | " + EffectiveEfficiency(current).ToString("0.##") + " J/TH");
            GUILayout.Label("Price: " + Money(current.PurchasePrice));
            if (GUILayout.Button("Buy Current ASIC")) BuyCurrentMiner();
            if (GUILayout.Button("Sell Newest ASIC")) SellNewestMiner();
            GUILayout.Space(8);

            for (int i = 0; i < generations.Count; i++)
            {
                MinerGeneration generation = generations[i];
                string marker = i < unlockedGeneration ? "DONE" : (i == unlockedGeneration ? "ACTIVE" : "LOCK");
                string owned = fleet[i] > 0 ? " x" + fleet[i] : "";
                GUILayout.Label(marker + "  " + generation.Name + owned + " | " + Hashrate(generation.HashrateTH) + " | " + generation.EfficiencyJTH.ToString("0.##") + " base J/TH");
            }

            GUILayout.Space(8);
            if (unlockedGeneration < generations.Count - 1)
            {
                double target = generations[unlockedGeneration + 1].ResearchCostToUnlock;
                GUILayout.Label("Next: " + generations[unlockedGeneration + 1].Name);
                GUILayout.Label("R&D: " + Money(researchProgress) + " / " + Money(target) + " | x" + ResearchMultiplier().ToString("0.00"));
                if (GUILayout.Button("Fund R&D")) FundResearch();
            }
            else GUILayout.Label("All hardware generations unlocked.");
            GUILayout.EndVertical();
        }

        private void DrawRacePanel(float width)
        {
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.33f));
            GUILayout.Label("THE RACE");
            GUILayout.Label("BTC: " + Money(bitcoinPrice));
            GUILayout.Label("Network: " + Hashrate(networkHashrateTH));
            GUILayout.Label("Block subsidy: " + blockSubsidy.ToString("0.###") + " BTC");
            GUILayout.Space(6);
            rivalScroll = GUILayout.BeginScrollView(rivalScroll);
            for (int i = 0; i < rivals.Count; i++)
            {
                RivalCompany rival = rivals[i];
                if (rival.Acquired)
                {
                    GUILayout.Label(rival.Profile.Name + " — ACQUIRED");
                    continue;
                }
                GUILayout.BeginVertical(GUI.skin.box);
                GUILayout.Label(rival.Profile.Name + " | " + RivalRating(rival) + " OVR");
                GUILayout.Label(rival.Profile.Sector + " | Partner: " + rival.Partnership);
                GUILayout.Label(Hashrate(rival.HashrateTH) + " | " + rival.EfficiencyJTH.ToString("0.##") + " J/TH");
                GUILayout.Label("Value: " + Money(rival.Value));
                double buyout = rival.Value * 1.15 * AcquisitionMultiplier();
                if (GUILayout.Button("Acquire for " + Money(buyout))) TryAcquire(rival);
                GUILayout.EndVertical();
            }
            GUILayout.EndScrollView();
            GUILayout.EndVertical();
        }

        private void DrawPartnershipPanel(float width)
        {
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.33f));
            GUILayout.Label("STRATEGIC PARTNERSHIPS");
            GUILayout.Label("Partnerships are a second technology tree. They change how your company wins.");
            partnershipScroll = GUILayout.BeginScrollView(partnershipScroll);
            for (int i = 0; i < partnerships.Count; i++)
            {
                StrategicPartnership partnership = partnerships[i];
                GUILayout.BeginVertical(GUI.skin.box);
                GUILayout.Label(partnership.Sector + " — " + partnership.PartnerName);
                GUILayout.Label(partnership.Benefit);
                if (partnership.Active)
                {
                    GUILayout.Label("ACTIVE");
                }
                else
                {
                    GUILayout.Label("Cost: " + Money(partnership.Cost) + " | Need value " + Money(partnership.RequiredValue) + " | Gen " + (partnership.RequiredGeneration + 1));
                    if (GUILayout.Button("Sign Partnership")) SignPartnership(partnership);
                }
                GUILayout.EndVertical();
            }
            GUILayout.EndScrollView();
            GUILayout.EndVertical();
        }

        private void DrawLeaguePanel(float width)
        {
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(width * 0.33f));
            GUILayout.Label("FRANCHISE LEAGUE");
            GUILayout.Label("Season " + CurrentSeason() + " | Your rank #" + PlayerLeagueRank());
            GUILayout.Label(playerCompany.Name + " — " + FranchiseRating() + " OVR — " + Money(CompanyValue()));
            for (int i = 0; i < rivals.Count; i++)
            {
                RivalCompany rival = rivals[i];
                if (rival.Acquired) continue;
                GUILayout.Label(rival.Profile.Name + " — " + RivalRating(rival) + " OVR — " + Money(rival.Value));
            }
            GUILayout.Space(10);
            GUILayout.Label("DYNASTY GOALS");
            GUILayout.Label("• Reach #1 company value");
            GUILayout.Label("• Reach 1 EH/s");
            GUILayout.Label("• Unlock sub-1 J/TH technology");
            GUILayout.Label("• Build at least 3 strategic partnerships");
            GUILayout.Label("• Acquire rival companies when the deal makes sense");
            GUILayout.EndVertical();
        }

        private void OnGUI()
        {
            GUI.skin.label.fontSize = 15;
            GUI.skin.button.fontSize = 14;
            GUI.skin.box.fontSize = 17;

            float margin = 16f;
            float width = Mathf.Min(Screen.width - margin * 2f, 1280f);
            GUILayout.BeginArea(new Rect(margin, margin, width, Screen.height - margin * 2f));

            if (!companySelected)
            {
                DrawCompanySelection(width);
                GUILayout.EndArea();
                return;
            }

            GUILayout.BeginHorizontal();
            GUILayout.Label("HASH RACE", GUILayout.Width(130));
            GUILayout.Label("Day " + gameDay.ToString("0.0"), GUILayout.Width(100));
            GUILayout.Label("Cash " + Money(cash), GUILayout.Width(170));
            GUILayout.Label("Value " + Money(CompanyValue()), GUILayout.Width(180));
            GUILayout.Label("#" + PlayerLeagueRank() + " | " + FranchiseRating() + " OVR", GUILayout.Width(130));
            GUILayout.FlexibleSpace();
            if (GUILayout.Button(paused ? "Resume" : "Pause", GUILayout.Width(80))) paused = !paused;
            if (GUILayout.Button("1x", GUILayout.Width(45))) speed = 1.0;
            if (GUILayout.Button("5x", GUILayout.Width(45))) speed = 5.0;
            if (GUILayout.Button("20x", GUILayout.Width(50))) speed = 20.0;
            GUILayout.EndHorizontal();

            GUILayout.Space(6);
            GUILayout.Box(eventText, GUILayout.ExpandWidth(true), GUILayout.Height(42));
            GUILayout.Space(6);

            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Race + Buyouts")) strategyView = 0;
            if (GUILayout.Button("Partnerships")) strategyView = 1;
            if (GUILayout.Button("Franchise League")) strategyView = 2;
            GUILayout.EndHorizontal();
            GUILayout.Space(6);

            GUILayout.BeginHorizontal();
            DrawFranchisePanel(width);
            GUILayout.Space(6);
            DrawTechnologyPanel(width);
            GUILayout.Space(6);
            if (strategyView == 0) DrawRacePanel(width);
            else if (strategyView == 1) DrawPartnershipPanel(width);
            else DrawLeaguePanel(width);
            GUILayout.EndHorizontal();

            if (gameOver)
            {
                GUILayout.Space(10);
                GUILayout.Box("GAME OVER — restart Play Mode to build another company.", GUILayout.Height(45));
            }

            GUILayout.EndArea();
        }
    }
}
