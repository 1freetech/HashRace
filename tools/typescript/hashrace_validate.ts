declare const require: (name: string) => any;
declare const process: { exitCode?: number };

const fs = require("fs");

type ContentContract = {
  miners: readonly string[];
  partnerSectors: readonly string[];
};

const contract: ContentContract = {
  miners: [
    "BlockForge Mining",
    "Northstar Hash",
    "VoltHash Mining",
    "TerraHash Industries",
    "Frontier Mining Co.",
    "HydroBlock Mining",
    "IronPeak Digital Mining",
    "Atlas Hashworks",
    "Cascade Mining Systems",
    "DeepCore Bitcoin Mining",
  ],
  partnerSectors: [
    "AI",
    "Robotics",
    "Semiconductor",
    "Energy",
    "Telecom",
    "Real Estate",
    "Finance",
    "Infrastructure",
    "Quick Service",
    "Sports",
  ],
};

function fail(message: string): never {
  throw new Error(`Hash Race content validation failed: ${message}`);
}

function countOccurrences(source: string, token: string): number {
  return source.split(token).length - 1;
}

function validateSource(source: string): void {
  if (!source.includes("const STARTING_MINERS")) fail("STARTING_MINERS is missing");
  if (!source.includes("const PARTNERS")) fail("PARTNERS is missing");

  for (const miner of contract.miners) {
    if (!source.includes(`\"name\":\"${miner}\"`)) fail(`missing mining company: ${miner}`);
  }

  for (const sector of contract.partnerSectors) {
    if (!source.includes(`\"sector\":\"${sector}\"`)) fail(`missing partner sector: ${sector}`);
  }

  const selectableMinerNames = contract.miners.filter((miner) =>
    source.includes(`\"name\":\"${miner}\"`),
  );
  if (selectableMinerNames.length !== 10) fail("expected exactly ten canonical mining competitors");

  if (countOccurrences(source, '\"sector\":') < 10) fail("expected at least ten outside partner sectors");
  if (source.includes('\"name\":\"NeuralPeak Compute\"')) fail("AI company must not be a selectable miner");
}

function main(): void {
  const source = fs.readFileSync("Godot/scripts/main.gd", "utf8");
  validateSource(source);
  console.log("Hash Race TypeScript validator passed: 10 Bitcoin miners and 10 outside partner sectors are intact.");
}

try {
  main();
} catch (error) {
  console.error(error);
  process.exitCode = 1;
}
