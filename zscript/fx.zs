// Minecraft effects: smoke poof, experience orbs, hit sparks, arrows, fire charges, explosions, item drops.

// Grey smoke that shrinks away (the death poof).
class MCPoofSmoke : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP Scale 0.8; }
	States
	{
	Spawn:
		POOF ABCDEFGH 3;
		Stop;
	}
}

// What a hit shows on a mob: a few white crit stars.
class MCHitSpark : Blood replaces Blood
{
	Default { +NOINTERACTION Scale 0.5; }
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		for (int i = 0; i < 4; i++)
		{
			let s = Spawn("MCCritStar", pos);
			if (s) s.vel = (frandom(-2.5, 2.5), frandom(-2.5, 2.5), frandom(0.5, 3.5));
		}
	}
	States
	{
	Spawn:
		CRIT A 6 Bright;
		Stop;
	}
}

class MCCritStar : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP Scale 0.35; Gravity 0.3; }
	States
	{
	Spawn:
		CRIT A 1 Bright { vel.z -= 0.25; A_FadeOut(0.06); scale *= 0.97; }
		Loop;
	}
}

// Experience orb: pops out, bounces, then flies to the player; the counter on the HUD goes up.
class MCXPOrb : Actor
{
	int age;
	Default
	{
		Radius 4;
		Height 8;
		Scale 0.36;
		Gravity 0.6;
		BounceType "Doom";
		BounceFactor 0.4;
		+NOBLOCKMAP
		+DROPOFF
		+NOTELEPORT
		+BRIGHT
		-SOLID
	}
	override void Tick()
	{
		Super.Tick();
		if (isFrozen()) return;
		age++;
		let mo = players[consoleplayer].mo;
		if (!mo || age < 18) return;
		Vector3 to = mo.pos + (0, 0, 10) - pos;   // into the player's feet, not the camera
		double d = to.Length();
		if (d < 44)
		{
			MCStats.AddXP(1);
			mo.A_StartSound("mc/xp", CHAN_AUTO, CHANF_OVERLAP, 0.55, ATTN_NONE, frandom(0.8, 1.25));
			Destroy();
			return;
		}
		if (d < 900)
		{
			bNoGravity = true;
			vel = to.Unit() * min(18, 5 + age * 0.4);
		}
	}
	States
	{
	Spawn:
		XPOR ABCDEFGHIJKLMN 3;
		Loop;
	}
}

// Dropped items: they hop out of the poof and spin on the floor for a while.
class MCDrop : Actor
{
	Default { Radius 6; Height 8; Scale 0.6; +NOBLOCKMAP +DROPOFF -SOLID Gravity 0.7; }
	States
	{
	Spawn:
		DROP A 350;
		DROP A 1 A_FadeOut(0.05);
		Wait;
	}
}
class MCDropFlesh : MCDrop { States { Spawn: DROP A 350; DROP A 1 A_FadeOut(0.05); Wait; } }
class MCDropBone : MCDrop { States { Spawn: DROP B 350; DROP B 1 A_FadeOut(0.05); Wait; } }
class MCDropGunpowder : MCDrop { States { Spawn: DROP C 350; DROP C 1 A_FadeOut(0.05); Wait; } }
class MCDropString : MCDrop { States { Spawn: DROP D 350; DROP D 1 A_FadeOut(0.05); Wait; } }
class MCDropTear : MCDrop { States { Spawn: DROP E 350; DROP E 1 A_FadeOut(0.05); Wait; } }

// Chips of the block a projectile hit, flying off the wall or floor (Minecraft's breaking particles).
class MCImpact play
{
	static TextureID HitTexture(Actor mo)
	{
		TextureID none;
		if (mo.BlockingLine)
		{
			Line ln = mo.BlockingLine;
			int sidenum = (ln.sidedef[1] && Actor.deltaangle(mo.angle, VectorAngle(ln.delta.x, ln.delta.y)) > 0) ? 1 : 0;
			Side sd = ln.sidedef[sidenum] ? ln.sidedef[sidenum] : ln.sidedef[0];
			TextureID t = sd.GetTexture(Side.mid);
			if (ln.backsector)
			{
				Sector other = sd.sector == ln.frontsector ? ln.backsector : ln.frontsector;
				if (mo.pos.z < other.floorplane.ZatPoint(mo.pos.xy)) t = sd.GetTexture(Side.bottom);
				else if (mo.pos.z > other.ceilingplane.ZatPoint(mo.pos.xy)) t = sd.GetTexture(Side.top);
			}
			if (t.IsValid()) return t;
		}
		if (mo.pos.z <= mo.floorz + 4) return mo.floorsector.GetTexture(Sector.floor);
		if (mo.pos.z + mo.height >= mo.ceilingz - 4) return mo.ceilingsector.GetTexture(Sector.ceiling);
		return none;
	}

	static void Chips(Actor mo, int n = 8, double speed = 2.5)
	{
		ChipsTex(mo, HitTexture(mo), n, speed);
	}

	// A hitscan puff does not know what it hit: look for the wall just around it.
	static void PuffChips(Actor p)
	{
		TextureID t;
		if (p.pos.z <= p.floorz + 3) t = p.floorsector.GetTexture(Sector.floor);
		else if (p.pos.z >= p.ceilingz - 3) t = p.ceilingsector.GetTexture(Sector.ceiling);
		else
		{
			FLineTraceData d;
			for (int k = 0; k < 2 && !t.IsValid(); k++)
			{
				if (p.LineTrace(p.angle + k * 180, 24, 0, TRF_THRUACTORS, 0, -8, 0, d) && d.HitType == TRACE_HitWall)
					t = d.HitTexture;
			}
		}
		ChipsTex(p, t, 7, 2.2);
	}

	static void ChipsTex(Actor mo, TextureID t, int n, double speed)
	{
		if (!t.IsValid() || t == skyflatnum) return;
		String name = TexMan.GetName(t);
		bool soft = name == "MCDIRT" || name == "MCGRASS" || name == "MCGRSID" || name == "MCGRAVL" || name == "MCSAND" || name.Left(6) == "MCPLAN";
		mo.A_StartSound(soft ? "mc/dig/dirt" : "mc/dig/stone", CHAN_AUTO, CHANF_OVERLAP, 0.8);
		for (int i = 0; i < n; i++)
		{
			mo.A_SpawnParticleEx(0xFFFFFF, t, STYLE_Normal, SPF_ROLL, random(20, 34), frandom(3, 6), 0,
				frandom(-4, 4), frandom(-4, 4), frandom(-4, 4), frandom(-speed, speed), frandom(-speed, speed), frandom(0, speed * 1.4),
				0, 0, -0.3, 1, 0.01, -0.05, frandom(0, 360), frandom(-10, 10));
		}
	}
}

// Skeleton arrow: flies straight, sticks in the wall it hits (and leaves chips of the block).
class MCArrow : Actor
{
	Default
	{
		Projectile;
		Radius 4;
		Height 4;
		Speed 30;
		DamageFunction (random(5, 9));
		Scale 0.6;
		+BLOODSPLATTER
		SeeSound "";
		DeathSound "";
		Obituary "%o was shot by a Skeleton.";
	}
	States
	{
	Spawn:
		ARRW A 1;
		Loop;
	Death:
		ARRW A 0 { A_StartSound("mc/arrow/hit", CHAN_BODY); MCImpact.Chips(self, 6, 2); }
		ARRW A 140;
		ARRW A 1 A_FadeOut(0.05);
		Wait;
	XDeath:
	Crash:
		TNT1 A 1 A_StartSound("mc/arrow/hit", CHAN_BODY);
		Stop;
	}
}

// Ghast fire charge: a flaming ball with a smoke and flame trail that bursts into fire.
class MCFireCharge : Actor
{
	Default
	{
		Projectile;
		Radius 8;
		Height 12;
		Speed 13;
		DamageFunction (random(14, 22));
		Scale 0.9;
		+BRIGHT
		+FORCEXYBILLBOARD
		Obituary "%o was fireballed by a Ghast.";
	}
	States
	{
	Spawn:
		FIRB A 2 Bright
		{
			A_SpawnItemEx("MCFlame", frandom(-4, 4), frandom(-4, 4), frandom(0, 8), frandom(-0.5, 0.5), frandom(-0.5, 0.5), frandom(0.5, 1.5), 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("MCPoofSmoke", -8, frandom(-3, 3), frandom(2, 8), 0, 0, 0.8, 0, SXF_NOCHECKPOSITION);
		}
		Loop;
	Death:
		TNT1 A 0
		{
			A_StartSound("mc/explode", CHAN_BODY, CHANF_DEFAULT, 0.6);
			A_Explode(24, 72);
			for (int i = 0; i < 8; i++) A_SpawnItemEx("MCFlame", 0, 0, 4, frandom(-3, 3), frandom(-3, 3), frandom(1, 4), 0, SXF_NOCHECKPOSITION);
			// fire on the floor where it lands (not in the face of whoever it hit)
			if (pos.z < floorz + 24)
				for (int i = 0; i < 3; i++) A_SpawnItemEx("MCGroundFire", frandom(-24, 24), frandom(-24, 24), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
			MCImpact.Chips(self, 10, 3);
		}
		TNT1 A 1;
		Stop;
	}
}

class MCFlame : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP +BRIGHT Scale 0.4; }
	States
	{
	Spawn:
		FLAM A 1 Bright { A_FadeOut(0.06); scale *= 0.94; }
		Loop;
	}
}

// Fire left on the floor for a few seconds; it hurts.
class MCGroundFire : Actor
{
	Default { +NOBLOCKMAP +BRIGHT +DROPOFF Scale 0.7; }
	States
	{
	Spawn:
		FIRE ABCDEFGH 3 Bright A_Explode(2, 20, 0);
		FIRE ABCDEFGH 3 Bright;
		FIRE ABCDEFGH 3 Bright A_Explode(2, 20, 0);
		FIRE ABCDEFGH 3 Bright A_FadeOut(0.12);
		Stop;
	}
}

// Minecraft explosion: a white flash and a cloud of grey puffs, chips of the floor, the screen shakes.
class MCExplosion : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP RenderStyle "None"; }
	States
	{
	Spawn:
		TNT1 A 1 NoDelay
		{
			A_StartSound("mc/explode", CHAN_BODY, CHANF_DEFAULT, 1.0, 0.6);
			A_QuakeEx(3, 3, 2, 18, 0, 700, "", QF_SCALEDOWN);
			let eye = players[consoleplayer].mo;
			for (int i = 0; i < 22; i++)
			{
				Vector3 at = pos + (frandom(-60, 60), frandom(-60, 60), frandom(-20, 50));
				// no smoke right in the player's face: the screen would just go white
				if (eye && (at - (eye.pos + (0, 0, eye.player.viewheight))).Length() < 80) continue;
				let p = Spawn("MCBoomPuff", at);
				if (p) { p.vel = (frandom(-2, 2), frandom(-2, 2), frandom(0, 2)); p.scale *= frandom(0.7, 1.4); p.tics += random(0, 6); }
			}
			Spawn("MCBoomFlash", pos);
			SetZ(floorz + 2);
			MCImpact.Chips(self, 16, 4);
		}
		Stop;
	}
}

class MCBoomPuff : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP Scale 1.1; }
	override void Tick()
	{
		Super.Tick();
		if (!isFrozen()) vel *= 0.9;
	}
	States
	{
	Spawn:
		BOOM C 3 Bright;
		BOOM D 4;
		BOOM E 5;
		BOOM F 4;
		BOOM F 1 { A_FadeOut(0.1); scale *= 1.02; }
		Wait;
	}
}

class MCBoomFlash : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP RenderStyle "Add"; Scale 1.6; Alpha 0.5; }
	States
	{
	Spawn:
		BOOM C 1 Bright { A_FadeOut(0.12); scale *= 1.1; }
		Loop;
	}
}
