// Minecraft mobs replacing Doom's monsters. Each one is a box model rendered from 8 angles: walk, attack,
// a red hurt frame on every hit, a hop of knockback, and the Minecraft death: it turns red, falls on its
// side and vanishes in a puff of smoke that drops experience orbs and an item.
class MCMob : Actor
{
	mixin MCDisguise;
	int xpDrop;
	Class<Actor> itemDrop;
	property XP: xpDrop;
	property Item: itemDrop;

	Default
	{
		Monster;
		+FLOORCLIP
		+DONTGIB
		Scale 0.5;
		Mass 80;
		PainChance 255;
		MCMob.XP 3;
		BloodType "MCHitSpark";
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		int dealt = Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
		if (dealt > 0 && health > 0)
		{
			// Minecraft knockback: pushed away and a little hop
			Actor from = inflictor ? inflictor : source;
			if (from && from != self && !bNoGravity)
			{
				Thrust(clamp(dealt * 0.35, 3, 9), from.AngleTo(self));
				if (pos.z <= floorz + 1) vel.z += 3.5;
			}
			if (!InStateSequence(CurState, FindState("Pain"))) A_StartSound(PainSound, CHAN_BODY, CHANF_OVERLAP);
		}
		return dealt;
	}

	// The end of the death: smoke puff, experience orbs, the mob's item.
	void A_MCPoof()
	{
		A_StartSound("mc/punch", CHAN_AUTO, CHANF_DEFAULT, 0.5);
		for (int i = 0; i < 14; i++)
		{
			let p = Spawn("MCPoofSmoke", pos + (frandom(-radius, radius), frandom(-radius, radius), frandom(0, height * 0.7)));
			if (p) p.vel = (frandom(-1.2, 1.2), frandom(-1.2, 1.2), frandom(0.3, 1.6));
		}
		for (int i = 0; i < xpDrop; i++)
		{
			let o = Spawn("MCXPOrb", pos + (0, 0, 12));
			if (o) o.vel = (frandom(-3, 3), frandom(-3, 3), frandom(3, 6));
		}
		if (itemDrop)
		{
			let d = Spawn(itemDrop, pos + (0, 0, 8));
			if (d) d.vel = (frandom(-2, 2), frandom(-2, 2), 4);
		}
	}
}

class MCZombie : MCMob replaces ZombieMan
{
	Default
	{
		Health 45;
		Radius 16;
		Height 60;
		Speed 8;
		MeleeRange 52;
		SeeSound "mc/zombie/say";
		ActiveSound "mc/zombie/say";
		PainSound "mc/zombie/hurt";
		DeathSound "mc/zombie/death";
		Obituary "%o was slain by a Zombie.";
		Tag "Zombie";
		DropItem "Clip";
		MCMob.XP 3;
		MCMob.Item "MCDropFlesh";
	}
	States
	{
	Spawn:
		ZOMB A 10 A_Look;
		Loop;
	See:
		ZOMB AABBCCDD 3 A_Chase;
		Loop;
	Melee:
		ZOMB E 7 A_FaceTarget;
		ZOMB F 6 A_CustomMeleeAttack(random(4, 9), "mc/punch", "", "Melee");
		ZOMB A 4;
		Goto See;
	Pain:
		ZOMB G 4;
		ZOMB G 4 A_Pain;
		Goto See;
	Death:
		ZOMB H 4 A_Scream;
		ZOMB I 4 A_NoBlocking;
		ZOMB JK 4;
		ZOMB L 14;
		TNT1 A 1 A_MCPoof;
		Stop;
	}
}

class MCSkeleton : MCMob replaces ShotgunGuy
{
	Default
	{
		Health 45;
		Radius 16;
		Height 60;
		Speed 8;
		SeeSound "mc/skeleton/say";
		ActiveSound "mc/skeleton/say";
		PainSound "mc/skeleton/hurt";
		DeathSound "mc/skeleton/death";
		Obituary "%o was shot by a Skeleton.";
		Tag "Skeleton";
		DropItem "Shotgun";
		MCMob.XP 4;
		MCMob.Item "MCDropBone";
	}
	States
	{
	Spawn:
		SKEL A 10 A_Look;
		Loop;
	See:
		SKEL AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		SKEL E 8 A_FaceTarget;
		SKEL F 10 { A_FaceTarget(); A_StartSound("mc/bow/draw", CHAN_WEAPON); }
		SKEL F 2 { A_StartSound("mc/bow/shoot", CHAN_WEAPON); A_SpawnProjectile("MCArrow", 42); }
		SKEL E 6;
		Goto See;
	Pain:
		SKEL G 4;
		SKEL G 4 A_Pain;
		Goto See;
	Death:
		SKEL H 4 A_Scream;
		SKEL I 4 A_NoBlocking;
		SKEL JK 4;
		SKEL L 14;
		TNT1 A 1 A_MCPoof;
		Stop;
	}
}

// Walks up to you, hisses, swells while blinking white, and blows up. Shoot it in time, or run.
class MCCreeper : MCMob replaces DoomImp
{
	int fuse;

	Default
	{
		Health 60;
		Radius 14;
		Height 52;
		Speed 9;
		MeleeRange 110;
		PainSound "mc/punch";
		DeathSound "mc/creeper/death";
		Obituary "%o was blown up by a Creeper.";
		Tag "Creeper";
		MCMob.XP 5;
		MCMob.Item "MCDropGunpowder";
	}

	void A_Fuse()
	{
		A_FaceTarget();
		fuse += 4;
		if (!target || target.health <= 0 || Distance3D(target) > 300)
		{
			fuse = 0;
			A_StopSound(CHAN_WEAPON);
			SetStateLabel("See");
			return;
		}
		if (fuse >= 36) A_Die("Boom");
	}

	States
	{
	Spawn:
		CREP A 10 A_Look;
		Loop;
	See:
		CREP AABBCCDD 3 A_Chase("Melee", null);
		Loop;
	Melee:
		CREP E 0 { fuse = 0; A_StartSound("mc/creeper/fuse", CHAN_WEAPON); }
	Fusing:
		CREP E 2 A_Fuse;
		CREP F 2;
		Loop;
	Pain:
		CREP G 4;
		CREP G 4 A_Pain;
		Goto See;
	Death:
		CREP H 4 A_Scream;
		CREP I 4 A_NoBlocking;
		CREP JK 4;
		CREP L 14;
		TNT1 A 1 A_MCPoof;
		Stop;
	Death.Boom:
		TNT1 A 0 { A_StopSound(CHAN_WEAPON); A_NoBlocking(); }
		TNT1 A 1 { A_Explode(90, 170, XF_HURTSOURCE); Spawn("MCExplosion", pos + (0, 0, 24)); }
		Stop;
	}
}

// Fast, low and wide; leaps at you from a distance, bites up close.
class MCSpider : MCMob replaces Demon
{
	Default
	{
		Health 150;
		Radius 28;
		Height 32;
		Speed 11;
		Mass 200;
		PainChance 160;
		MeleeRange 56;
		MinMissileChance 160;
		SeeSound "mc/spider/say";
		ActiveSound "mc/spider/say";
		PainSound "mc/spider/hurt";
		DeathSound "mc/spider/death";
		Obituary "%o was bitten by a Spider.";
		Tag "Spider";
		MCMob.XP 6;
		MCMob.Item "MCDropString";
	}
	States
	{
	Spawn:
		SPID A 10 A_Look;
		Loop;
	See:
		SPID AABBCCDD 2 A_Chase;
		Loop;
	Melee:
		SPID E 5 A_FaceTarget;
		SPID F 6 A_CustomMeleeAttack(random(6, 12), "mc/spider/attack", "", "Melee");
		SPID A 4;
		Goto See;
	Missile:
		SPID A 0 A_JumpIfCloser(360, 1);
		Goto See;
		SPID E 8 A_FaceTarget;
		SPID F 0 { A_StartSound("mc/spider/attack", CHAN_VOICE); vel.xy = AngleToVector(angle, 14); vel.z = 6.5; }
		SPID F 12;
		SPID F 1 A_JumpIfCloser(64, "Melee");
		Goto See;
	Pain:
		SPID G 3;
		SPID G 3 A_Pain;
		Goto See;
	Death:
		SPID H 4 A_Scream;
		SPID I 4 A_NoBlocking;
		SPID JK 4;
		SPID L 14;
		TNT1 A 1 A_MCPoof;
		Stop;
	}
}

// A huge floating jellyfish; opens its eyes and shrieks before spitting a fire charge.
class MCGhast : MCMob replaces Cacodemon
{
	Default
	{
		Health 240;
		Radius 32;
		Height 84;
		Speed 7;
		Mass 400;
		Scale 0.6;
		PainChance 110;
		+FLOAT
		+NOGRAVITY
		-FLOORCLIP
		SeeSound "mc/ghast/shot";
		PainSound "mc/ghast/hurt";
		DeathSound "mc/ghast/death";
		Obituary "%o was fireballed by a Ghast.";
		Tag "Ghast";
		MCMob.XP 12;
		MCMob.Item "MCDropTear";
	}
	States
	{
	Spawn:
		GHST AABBCCDD 4 A_Look;
		Loop;
	See:
		GHST AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		GHST E 12 { A_FaceTarget(); A_StartSound("mc/ghast/shot", CHAN_VOICE); }
		GHST F 6 A_SpawnProjectile("MCFireCharge", 36);
		GHST F 6;
		Goto See;
	Pain:
		GHST G 4;
		GHST G 4 A_Pain;
		Goto See;
	Death:
		GHST H 5 A_Scream;
		GHST I 5 A_NoBlocking;
		GHST JK 5;
		GHST L 16;
		TNT1 A 1 A_MCPoof;
		Stop;
	}
}
