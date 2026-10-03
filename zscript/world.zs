// The level turns into Minecraft blocks at map start, in a wave from the player: floors first, then the
// walls from the bottom up, the ceilings last. Grass on outdoor floors and on the sides of outdoor steps,
// doors become double doors, switches become levers. Chips of each new block fly out where it appears.
class MCWorld : EventHandler
{
	const SPEED = 480.;      // map units per second of the wave
	const STEP = 10;         // tics between floor, lower, middle and upper parts of one place
	const MAXT = 35 * 14;
	const DELAY = 75;        // tics of plain Doom first, so the change is seen
	const BURSTS = 5;        // chip bursts per tic at most

	enum EPart { P_FLOOR, P_LOWER, P_MID, P_UPPER, P_CEIL }
	enum EFix { F_NONE, F_GRASS, F_LEVER, F_DOOR }

	// Conversion queue, bucketed by tic (linked lists).
	Array<int> head, nxt, kind, idx, target, fix;
	Array<TextureID> uniqFrom, uniqTo;
	TextureID grassTop, grassSide, door, ironDoor, lava, water, lever0, lever1;
	int startTic, lastTic, burstsThisTic;
	bool active, ready, skyDone;
	TextureID mcSky;
	Vector2 origin;

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) return;
		grassTop = TexMan.CheckForTexture("MCGRASS", TexMan.Type_Any);
		grassSide = TexMan.CheckForTexture("MCGRSID", TexMan.Type_Any);
		door = TexMan.CheckForTexture("MCDOOR", TexMan.Type_Any);
		ironDoor = TexMan.CheckForTexture("MCIDOOR", TexMan.Type_Any);
		lava = TexMan.CheckForTexture("MCLAVA01", TexMan.Type_Any);
		water = TexMan.CheckForTexture("MCWATR01", TexMan.Type_Any);
		lever0 = TexMan.CheckForTexture("MCLEVR0", TexMan.Type_Any);
		lever1 = TexMan.CheckForTexture("MCLEVR1", TexMan.Type_Any);
		mcSky = TexMan.CheckForTexture("MCSKY1", TexMan.Type_Any);
		if (mc_demo) MCDemo.PlaceStart();
		origin = players[consoleplayer].mo ? players[consoleplayer].mo.pos.xy : (0, 0);
		head.Resize(MAXT + STEP * 5 + 2);
		for (int i = 0; i < head.Size(); i++) head[i] = -1;

		for (int i = 0; i < level.sectors.Size(); i++)
		{
			Sector s = level.sectors[i];
			int t = TicFor(s.centerspot);
			Queue(P_FLOOR, i, t, FloorTarget(s), F_NONE);
			Queue(P_CEIL, i, t + STEP * 3, Convert(s.GetTexture(Sector.ceiling)), F_NONE);
		}
		for (int i = 0; i < level.sides.Size(); i++)
		{
			Side sd = level.sides[i];
			Line ln = sd.linedef;
			int t = TicFor((ln.v1.p + ln.v2.p) / 2) + 2;
			int f;
			int tgt;
			[tgt, f] = LowerTarget(sd);
			Queue(P_LOWER, i, t + STEP, tgt, f);
			[tgt, f] = MidTarget(sd);
			Queue(P_MID, i, t + STEP * 2, tgt, f);
			[tgt, f] = UpperTarget(sd);
			Queue(P_UPPER, i, t + STEP * 3, tgt, f);
		}
		startTic = level.maptime + DELAY;
		lastTic = -1;
		active = true;
		ready = true;
	}

	// When the wave reaches a spot (level time), -1 before the map is ready.
	static int ArrivalTic(Vector2 p)
	{
		let h = MCWorld(EventHandler.Find("MCWorld"));
		if (!h || !h.ready) return -1;
		return h.startTic + h.TicFor(p) + STEP;
	}

	// A Doom thing turns into its Minecraft self: a puff of smoke and the place sound.
	static void PopInto(Actor a)
	{
		a.A_StartSound("mc/place", CHAN_AUTO, CHANF_OVERLAP, 0.9);
		for (int i = 0; i < 6; i++)
		{
			let p = Actor.Spawn("MCPoofSmoke", a.pos + (frandom(-a.radius, a.radius), frandom(-a.radius, a.radius), frandom(0, a.height)));
			if (p) { p.vel = (frandom(-1, 1), frandom(-1, 1), frandom(0.2, 1.5)); p.scale *= 0.6; }
		}
	}

	int TicFor(Vector2 p)
	{
		return min(MAXT, int((p - origin).Length() / SPEED * 35.));
	}

	void Queue(int k, int i, int t, int tgt, int f)
	{
		if (tgt < 0) return;
		kind.Push(k);
		idx.Push(i);
		target.Push(tgt);
		fix.Push(f);
		nxt.Push(head[t]);
		head[t] = kind.Size() - 1;
	}

	// Index of the block replacing a Doom texture in uniqTo (-1: keep it, e.g. the sky).
	int Convert(TextureID tex)
	{
		if (!tex.IsValid() || tex == skyflatnum) return -1;
		for (int i = 0; i < uniqFrom.Size(); i++) if (uniqFrom[i] == tex) return uniqTo[i].IsValid() ? i : -1;
		String name = TexMan.GetName(tex).MakeUpper();
		TextureID to;
		if (name.Left(3) == "SKY") to.SetNull();
		else
		{
			for (int j = 0; j < MCBlockMap.DOOMTEX.Size(); j++)
			{
				if (MCBlockMap.DOOMTEX[j] == name) { to = TexMan.CheckForTexture(MCBlockMap.BLOCK[j], TexMan.Type_Any); break; }
			}
			if (!to.IsValid()) to = TexMan.CheckForTexture("MCSTONE", TexMan.Type_Any);
		}
		uniqFrom.Push(tex);
		uniqTo.Push(to);
		return to.IsValid() ? uniqFrom.Size() - 1 : -1;
	}

	int Special(TextureID t)
	{
		for (int i = 0; i < uniqTo.Size(); i++) if (uniqTo[i] == t) return i;
		uniqFrom.Push(t);
		uniqTo.Push(t);
		return uniqTo.Size() - 1;
	}

	static bool Outdoor(Sector s) { return s && s.GetTexture(Sector.ceiling) == skyflatnum; }

	int FloorTarget(Sector s)
	{
		int c = Convert(s.GetTexture(Sector.floor));
		if (c < 0) return -1;
		TextureID to = uniqTo[c];
		if (s.damageamount > 0 && to != water) return Special(lava);
		bool liquid = to == lava || to == water;
		String n = TexMan.GetName(to);
		bool light = n == "MCGLOWS" || n == "MCLAMP" || n.Left(6) == "MCSEAL";
		if (Outdoor(s) && !liquid && !light) return Special(grassTop);
		return c;
	}

	static bool IsDoor(Line ln)
	{
		int sp = ln.special;
		return sp == 10 || sp == 11 || sp == 12 || sp == 13 || sp == 14 || sp == 202 || sp == 249;
	}

	int, int LowerTarget(Side sd)
	{
		int c = Convert(sd.GetTexture(Side.bottom));
		if (c < 0) return -1, F_NONE;
		Line ln = sd.linedef;
		Sector other = ln.frontsector == sd.sector ? ln.backsector : ln.frontsector;
		TextureID to = uniqTo[c];
		Vector2 mid = (ln.v1.p + ln.v2.p) / 2;
		if (other && Outdoor(other) && to != lava && to != water && other.floorplane.ZatPoint(mid) > sd.sector.floorplane.ZatPoint(mid))
			return Special(grassSide), F_GRASS;
		return c, F_NONE;
	}

	int, int MidTarget(Side sd)
	{
		int c = Convert(sd.GetTexture(Side.mid));
		if (c < 0) return -1, F_NONE;
		TextureID to = uniqTo[c];
		if ((to == lever0 || to == lever1) && !sd.linedef.backsector) return c, F_LEVER;
		return c, F_NONE;
	}

	int, int UpperTarget(Side sd)
	{
		Line ln = sd.linedef;
		if (IsDoor(ln) && ln.backsector && sd.GetTexture(Side.top).IsValid())
		{
			bool locked = ln.special == 13 || (ln.special == 202 && ln.args[4] != 0);
			return Special(locked ? ironDoor : door), F_DOOR;
		}
		return Convert(sd.GetTexture(Side.top)), F_NONE;
	}

	override void WorldTick()
	{
		if (!active) return;
		int now = level.maptime - startTic;
		burstsThisTic = 0;
		if (!skyDone && now >= 6 && mcSky.IsValid())
		{
			// the sky goes Minecraft blue as the wave starts
			level.ChangeSky(mcSky, mcSky);
			skyDone = true;
		}
		while (lastTic < now && lastTic < head.Size() - 1)
		{
			lastTic++;
			for (int i = head[lastTic]; i >= 0; i = nxt[i]) Apply(i);
		}
		if (lastTic >= head.Size() - 1) active = false;
	}

	void Apply(int i)
	{
		TextureID to = uniqTo[target[i]];
		int k = kind[i];
		if (k == P_FLOOR || k == P_CEIL)
		{
			Sector s = level.sectors[idx[i]];
			bool fl = k == P_FLOOR;
			s.SetTexture(fl ? Sector.floor : Sector.ceiling, to);
			double z = fl ? s.floorplane.ZatPoint(s.centerspot) + 4 : s.ceilingplane.ZatPoint(s.centerspot) - 4;
			Burst((s.centerspot, z), to, fl, !fl);
			return;
		}
		Side sd = level.sides[idx[i]];
		Line ln = sd.linedef;
		int part = k == P_LOWER ? Side.bottom : (k == P_MID ? Side.mid : Side.top);
		switch (fix[i])
		{
		case F_GRASS:
			// grass strip on top: the lower texture starts at the top of the step
			ln.flags &= ~Line.ML_DONTPEGBOTTOM;
			sd.SetTextureYOffset(Side.bottom, 0);
			break;
		case F_LEVER:
			// the lever in the middle of the line, 32 to 64 units above the floor
			ln.flags |= Line.ML_DONTPEGBOTTOM;
			sd.SetTextureYOffset(Side.mid, 0);
			sd.SetTextureXOffset(Side.mid, 64 - ln.delta.Length() / 2);
			break;
		case F_DOOR:
			// the face of a door: double doors standing on the door's lower edge
			ln.flags &= ~Line.ML_DONTPEGTOP;
			sd.SetTextureYOffset(Side.top, 0);
			sd.SetTextureXOffset(Side.top, 32 - ln.delta.Length() / 2);
			break;
		}
		sd.SetTexture(part, to);
		// a burst of chips just off the wall, in the middle of the part that changed
		Vector2 mid = (ln.v1.p + ln.v2.p) / 2;
		Vector2 n = (ln.delta.y, -ln.delta.x).Unit();
		if (ln.sidedef[1] == sd) n = -n;
		Sector own = sd.sector;
		Sector other = ln.frontsector == own ? ln.backsector : ln.frontsector;
		double f = own.floorplane.ZatPoint(mid), c = own.ceilingplane.ZatPoint(mid);
		double z = (f + c) / 2;
		if (other && k == P_LOWER) z = (f + max(f, other.floorplane.ZatPoint(mid))) / 2;
		if (other && k == P_UPPER) z = (c + min(c, other.ceilingplane.ZatPoint(mid))) / 2;
		Burst((mid + n * 6, z), to, false, false);
	}

	// Chips of the new block fly out where it appears, with the "place block" sound (near the player only).
	void Burst(Vector3 at, TextureID tex, bool up, bool down)
	{
		let mo = players[consoleplayer].mo;
		if (!mo || burstsThisTic >= BURSTS || (at.xy - mo.pos.xy).Length() > 700) return;
		burstsThisTic++;
		let p = MCPlacePop(Actor.Spawn("MCPlacePop", at));
		if (p) { p.tex = tex; p.up = up; p.down = down; }
	}
}

// Invisible: a puff of little block chips (the block's own texture) and the place sound, then gone.
class MCPlacePop : Actor
{
	TextureID tex;
	bool up, down;

	Default { +NOINTERACTION +NOBLOCKMAP +NOGRAVITY RenderStyle "None"; }

	void Chips()
	{
		A_StartSound("mc/place", CHAN_BODY, CHANF_DEFAULT, 0.7, ATTN_NORM);
		for (int i = 0; i < 12; i++)
		{
			double vz = up ? frandom(1.5, 4.5) : (down ? frandom(-3, -0.5) : frandom(-0.5, 3));
			A_SpawnParticleEx(0xFFFFFF, tex, STYLE_Normal, SPF_ROLL | SPF_FULLBRIGHT, random(22, 36), frandom(7, 11), 0,
				frandom(-16, 16), frandom(-16, 16), frandom(-4, 4), frandom(-2, 2), frandom(-2, 2), vz,
				0, 0, -0.25, 1, 0.02, -0.08, frandom(0, 360), frandom(-8, 8));
		}
	}

	States
	{
	Spawn:
		TNT1 A 1 NoDelay Chips();
		TNT1 A 30;
		Stop;
	}
}
