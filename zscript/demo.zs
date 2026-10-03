// The stream demo (demo.cfg sets mc_demo): the player starts in MAP01's open field, then mobs come in small
// waves in front of the player and the gear changes, so every feature shows within a minute.
class MCDemo : EventHandler
{
	static const int WAVE_AT[] = { 1, 200, 420, 640, 840, 1120, 1560, 1760, 1960, 2200, 2450 };
	static const double AREA[] = { 700, 1700, -720, -330 };   // MAP01's central courtyard (x from, to, y from, to)

	// Start outdoors in the open field north of the plant: of a grid of outdoor spots and 8 headings, the view
	// with the most open space and the most trees ahead.
	static void PlaceStart()
	{
		let mo = players[consoleplayer].mo;
		if (!mo) return;
		Vector3 home = mo.pos;
		double home_a = mo.angle;
		double best = -1;
		Vector3 bestPos;
		double bestAng;
		for (double x = MCDemo.AREA[0]; x <= MCDemo.AREA[1]; x += 64)
		{
			for (double y = MCDemo.AREA[2]; y <= MCDemo.AREA[3]; y += 64)
			{
				Vector2 p = (x, y);
				Sector s = level.PointInSector(p);
				if (!MCWorld.Outdoor(s)) continue;
				mo.SetOrigin((p, s.floorplane.ZatPoint(p)), false);
				if (!mo.TestMobjLocation()) continue;
				for (int k = 0; k < 8; k++)
				{
					double a = k * 45;
					FLineTraceData d;
					double free = mo.LineTrace(a, 1400, 0, TRF_THRUACTORS, mo.height * 0.5, data: d) ? d.Distance : 1400;
					double around = 1000;
					for (int j = -1; j <= 1; j += 2)
						around = min(around, mo.LineTrace(a + j * 30, 1000, 0, TRF_THRUACTORS, mo.height * 0.5, data: d) ? d.Distance : 1000);
					double score = min(free, 1400) * 1.2 + min(around, 600) * 0.5 + 140 * TreesAhead(mo, a);
					if (score > best) { best = score; bestPos = mo.pos; bestAng = a; }
				}
			}
		}
		if (best < 0) { mo.SetOrigin(home, false); mo.angle = home_a; return; }
		mo.SetOrigin(bestPos, false);
		mo.angle = bestAng;
		mo.player.cheats |= CF_GODMODE;
	}

	static int TreesAhead(Actor mo, double a)
	{
		int n = 0;
		let it = ThinkerIterator.Create("Actor");
		Actor t;
		while (t = Actor(it.Next()))
		{
			if (!(t is "MCTree" || t is "MCMob" || t is "MCTNTBlock" || t is "MCGlowPost" || t is "MCRedstoneLamp")) continue;
			double d = mo.Distance2D(t);
			if (abs(Actor.deltaangle(a, mo.AngleTo(t))) > 35 || !mo.CheckSight(t)) continue;
			if (d < 260) n -= 3;   // a trunk right in front hides everything
			else if (d < 900) n++;
		}
		return min(n, 5);
	}

	override void WorldTick()
	{
		if (!mc_demo) return;
		let mo = players[consoleplayer].mo;
		if (!mo) return;
		int t = level.maptime;
		mo.player.cheats |= CF_GODMODE;   // the stream player shows the mod, it never dies
		for (int w = 0; w < MCDemo.WAVE_AT.Size(); w++) if (MCDemo.WAVE_AT[w] == t) Wave(mo, w);
	}

	void Wave(PlayerPawn mo, int w)
	{
		switch (w)
		{
		case 0: Put(mo, "MCCreeper", 380, 0); Put(mo, "MCZombie", 460, -14); Put(mo, "MCZombie", 460, 14); break;
		case 1: Put(mo, "MCZombie", 420, 10); Put(mo, "MCSkeleton", 520, -15); break;
		case 2: Put(mo, "MCCreeper", 300, 0); Put(mo, "MCZombie", 330, 8); Put(mo, "MCZombie", 340, -8); break;
		case 3: Gear(mo, "MCTNT", "RocketAmmo", 12); Put(mo, "MCZombie", 420, 0); Put(mo, "MCZombie", 440, 10); Put(mo, "MCTNTBlock", 400, 5); break;
		case 4: Put(mo, "MCSpider", 480, 0); Put(mo, "MCZombie", 520, 15); break;
		case 5: Gear(mo, "MCCrossbow", "Shell", 40); Put(mo, "MCGhast", 480, 0, 40); break;
		case 6: Put(mo, "MCSkeleton", 460, -12); Put(mo, "MCSkeleton", 480, 12); break;
		case 7: Put(mo, "MCCreeper", 320, 0); Put(mo, "MCSpider", 520, 10); break;
		case 8: Gear(mo, "MCSword", "", 0); Put(mo, "MCZombie", 260, 0); Put(mo, "MCZombie", 300, 12); break;
		case 9: Gear(mo, "MCBow", "Clip", 40); Put(mo, "MCSkeleton", 480, 0); Put(mo, "MCCreeper", 380, 12); break;
		case 10: Gear(mo, "MCTNT", "RocketAmmo", 10); Put(mo, "MCZombie", 450, 0); Put(mo, "MCZombie", 470, -10); Put(mo, "MCTNTBlock", 430, -4); break;
		}
	}

	void Gear(PlayerPawn mo, Class<Weapon> w, Class<Ammo> ammo, int n)
	{
		if (!mo.FindInventory(w)) mo.GiveInventory(w, 1);
		if (ammo) mo.GiveInventory(ammo, n);
		mo.A_SelectWeapon(w);
	}

	// Spawns a thing in view, roughly ahead of the player: tries spots around the wanted distance and angle.
	void Put(PlayerPawn mo, Class<Actor> cls, double dist, double ang, double up = 0)
	{
		for (int i = 0; i < 40; i++)
		{
			double a = mo.angle + ang + frandom(-1, 1) * (8 + i * 2);
			double d = dist * frandom(0.6, 0.8) - i * 3;
			if (d < 160) d = 160;
			Vector2 xy = mo.Vec2Angle(d, a);
			Sector s = level.PointInSector(xy);
			double z = s.floorplane.ZatPoint(xy);
			if (abs(z - mo.pos.z) > 72) continue;
			let m = Actor.Spawn(cls, (xy, z + up), ALLOW_REPLACE);
			if (!m) continue;
			if (!m.TestMobjLocation() || !m.CheckSight(mo) || (up > 0 && m.pos.z + m.height > m.ceilingz))
			{
				m.Destroy();
				continue;
			}
			m.angle = m.AngleTo(mo);
			if (m.bIsMonster)
			{
				m.target = mo;
				if (level.maptime > 2)
				{
					MCWorld.PopInto(m);
					if (m.SeeState) m.SetState(m.SeeState);
				}
			}
			return;
		}
	}
}
