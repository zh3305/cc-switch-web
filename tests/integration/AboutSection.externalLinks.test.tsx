import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { AboutSection } from "@/components/settings/AboutSection";

const { invokeMock, listenMock } = vi.hoisted(() => ({
  invokeMock: vi.fn(),
  listenMock: vi.fn(),
}));

vi.mock("@/lib/transport", () => ({
  invoke: invokeMock,
  listen: listenMock,
}));

vi.mock("@/contexts/UpdateContext", () => ({
  useUpdate: () => ({
    hasUpdate: false,
    updateInfo: null,
    updateHandle: null,
    checkUpdate: vi.fn().mockResolvedValue(false),
    resetDismiss: vi.fn(),
    isChecking: false,
  }),
}));

vi.mock("@/lib/updater", () => ({
  getCurrentVersion: vi.fn().mockResolvedValue("3.15.0"),
  relaunchApp: vi.fn(),
}));

vi.mock("@/lib/platform", () => ({
  isWindows: () => true,
}));

describe("AboutSection 外链按钮", () => {
  beforeEach(() => {
    invokeMock.mockReset();
    listenMock.mockReset();
    vi.restoreAllMocks();
  });

  it("点击官方网站按钮时会在 Web 端打开外链", async () => {
    invokeMock.mockResolvedValue({ url: "https://ccswitch.io" });
    const openSpy = vi.spyOn(window, "open").mockReturnValue(null);

    render(<AboutSection isPortable={false} />);

    const button = await screen.findByRole("button", {
      name: /officialwebsite|settings\.officialWebsite|官方网站/i,
    });

    await userEvent.click(button);

    await waitFor(() => {
      expect(invokeMock).toHaveBeenCalledWith("open_external", {
        url: "https://ccswitch.io",
      });
    });
    expect(openSpy).toHaveBeenCalledWith(
      "https://ccswitch.io",
      "_blank",
      "noopener,noreferrer",
    );
  });
});
