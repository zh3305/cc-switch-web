import { readFileSync } from "node:fs";
import path from "node:path";

describe("desktop updater endpoint", () => {
  it("uses the web fork release feed instead of upstream releases", () => {
    const configPath = path.resolve(__dirname, "../../src-tauri/tauri.conf.json");
    const raw = readFileSync(configPath, "utf-8");
    const config = JSON.parse(raw) as {
      plugins?: {
        updater?: {
          endpoints?: string[];
        };
      };
    };

    expect(config.plugins?.updater?.endpoints).toEqual([
      "https://github.com/zh3305/cc-switch-web/releases/latest/download/latest.json",
    ]);
  });
});
