// Experience: orbs from every kill fill the bar, every few orbs is a new level (with the level up chime).
class MCStats : EventHandler
{
	int xp, lvl, lvlFlash;

	static void AddXP(int n)
	{
		let h = MCStats(EventHandler.Find("MCStats"));
		if (h) h.Gain(n);
	}

	static clearscope int Need(int l) { return 7 + l * 2; }

	void Gain(int n)
	{
		xp += n;
		while (xp >= Need(lvl))
		{
			xp -= Need(lvl);
			lvl++;
			lvlFlash = 70;
			let mo = players[consoleplayer].mo;
			if (mo) mo.A_StartSound("mc/levelup", CHAN_AUTO, CHANF_OVERLAP, 0.8, ATTN_NONE);
		}
	}

	override void WorldTick()
	{
		if (lvlFlash > 0) lvlFlash--;
	}
}
