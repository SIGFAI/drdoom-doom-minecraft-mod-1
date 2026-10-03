// Minecraft HUD: hotbar with the gear (the weapon in hand framed, ammo as stack counts), hearts, armor,
// food, the green experience bar with the level, and the little white crosshair.
class MCStatusBar : BaseStatusBar
{
	HUDFont small;
	const W = 640;
	const H = 360;
	static const String SLOTICON[] = { "mcisword", "mcibow", "mcixbow", "mcitnt", "mciarrow", "mciarrow", "mciapple", "", "" };
	static const Name SLOTCLASS[] = { 'MCSword', 'MCBow', 'MCCrossbow', 'MCTNT', 'Clip', 'Shell', '', '', '' };

	override void Init()
	{
		Super.Init();
		SetSize(0, W, H);
		small = HUDFont.Create(SmallFont, 0, Mono_Off, 1, 1);
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		if (state == HUD_None || !CPlayer || !CPlayer.mo) return;
		BeginHUD(1, true, W, H);
		let mo = CPlayer.mo;
		DrawImage("mccross", (0, 0), DI_SCREEN_CENTER | DI_ITEM_CENTER, 0.85);

		// hotbar
		double hx = -91, hy = -24;
		DrawImage("mchotbar", (hx, hy), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
		let ready = CPlayer.ReadyWeapon;
		for (int i = 0; i < 9; i++)
		{
			if (SLOTICON[i] == "") continue;
			Class<Inventory> c = SLOTCLASS[i];
			int count = 0;
			if (c) { let inv = mo.FindInventory(c); if (!inv) continue; count = inv is "Weapon" ? -1 : inv.Amount; }
			Vector2 p = (hx + 3 + i * 20, hy + 3);
			DrawImage(SLOTICON[i], p, DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
			if (i == 3) count = mo.CountInv("RocketAmmo");
			if (count > 1 || i == 3) DrawString(small, FormatNumber(count), p + (17, 9), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_RIGHT, Font.CR_WHITE);
			if (ready && c && ready.GetClass() == c) DrawImage("mchotsel", (hx - 1 + i * 20, hy - 1), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
		}

		// experience bar and level
		let st = MCStats(EventHandler.Find("MCStats"));
		double frac = st ? double(st.xp) / MCStats.Need(st.lvl) : 0;
		DrawImage("mcxpbg", (hx, hy - 7), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
		if (frac > 0) DrawImage("mcxpfg", (hx, hy - 7), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP, 1, (182 * frac, 5));
		if (st && st.lvl > 0)
		{
			String l = String.Format("%d", st.lvl);
			DrawString(small, l, (1, hy - 16), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER, Font.CR_BLACK);
			DrawString(small, l, (0, hy - 17), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER, st.lvlFlash > 0 && (st.lvlFlash / 4) % 2 ? Font.CR_WHITE : Font.CR_GREEN);
		}
		if (st && st.lvlFlash > 0)
			DrawString(small, "LEVEL UP!", (0, hy - 48), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER, Font.CR_GREEN);

		// hearts (10 health each), armor above them, food on the right
		int hp = max(0, mo.health);
		for (int i = 0; i < 10; i++)
		{
			int v = hp - i * 10;
			String img = v >= 10 ? "mcheaf" : (v >= 5 ? "mcheah" : "mcheae");
			double shake = (hp <= 20 && v > 0) ? (((level.maptime / 2 + i) % 3) - 1) : 0;
			DrawImage(img, (hx + i * 8, hy - 17 + shake), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
		}
		int ap = mo.CountInv("BasicArmor");
		if (ap > 0)
		{
			for (int i = 0; i < 10; i++)
			{
				int v = ap / 2 - i * 10;
				DrawImage(v >= 10 ? "mcarmf" : (v >= 5 ? "mcarmh" : "mcarme"), (hx + i * 8, hy - 27), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
			}
		}
		for (int i = 0; i < 10; i++)
			DrawImage("mcfoof", (hx + 182 - 9 - i * 8, hy - 17), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP);
	}
}
