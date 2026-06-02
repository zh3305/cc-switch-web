import { beforeEach, describe, expect, it, vi } from "vitest";

const invokeMock = vi.fn();

vi.mock("@/lib/transport", () => ({
  invoke: invokeMock,
}));

describe("settingsApi.openExternal", () => {
  beforeEach(() => {
    invokeMock.mockReset();
    vi.restoreAllMocks();
  });

  it("在 Web 模式下会打开后端返回的外链地址", async () => {
    invokeMock.mockResolvedValue({ url: "https://ccswitch.io" });
    const openSpy = vi.spyOn(window, "open").mockReturnValue(null);

    const { settingsApi } = await import("@/lib/api/settings");

    await settingsApi.openExternal("https://ccswitch.io");

    expect(invokeMock).toHaveBeenCalledWith("open_external", {
      url: "https://ccswitch.io",
    });
    expect(openSpy).toHaveBeenCalledWith(
      "https://ccswitch.io",
      "_blank",
      "noopener,noreferrer",
    );
  });

  it("桌面端返回布尔值时不会重复调用浏览器打开", async () => {
    invokeMock.mockResolvedValue(true);
    const openSpy = vi.spyOn(window, "open").mockReturnValue(null);

    const { settingsApi } = await import("@/lib/api/settings");

    await settingsApi.openExternal("https://ccswitch.io");

    expect(openSpy).not.toHaveBeenCalled();
  });
});
