import { spawnSync } from "node:child_process";

const dart = process.env.DART || "dart";
const result = spawnSync(dart, ["pub", "get"], { stdio: "inherit" });

process.exit(result.status ?? 1);

