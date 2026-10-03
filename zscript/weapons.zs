// The player's Minecraft gear: a diamond sword, a bow, a multishot crossbow and throwable TNT, held by a blocky arm.
class MCPlayer : DoomPlayer
{
	Default
	{
		Player.StartItem "MCBow";
		Player.StartItem "MCSword";
		Player.StartItem "Clip", 64;
		Player.WeaponSlot 1, "MCSword";
		Player.WeaponSlot 2, "MCBow";
		Player.WeaponSlot 3, "MCCrossbow";
		Player.WeaponSlot 5, "MCTNT";
	}
}

class MCSword : Weapon replaces Fist
{
	mixin MCDisguise;
	Default
	{
		Weapon.SlotNumber 1;
		Weapon.SelectionOrder 3700;
		Weapon.Kickback 140;
		+WEAPON.MELEEWEAPON
		+WEAPON.WIMPY_WEAPON
		Tag "Diamond Sword";
		Inventory.PickupMessage "Diamond Sword";
		Obituary "%o was slain by %k's diamond sword.";
	}
	States
	{
	Ready:
		SWRD A 1 A_WeaponReady;
		Loop;
	Deselect:
		SWRD A 1 A_Lower(12);
		Loop;
	Select:
		SWRD A 1 A_Raise(12);
		Loop;
	Fire:
		SWRD B 3;
		SWRD C 2 { A_StartSound("mc/swing", CHAN_WEAPON); A_CustomPunch(random(22, 34), true, 0, "MCSwordPuff", 84, 0, 0, "ArmorBonus", "mc/punch", ""); }
		SWRD D 4;
		SWRD A 5 A_ReFire;
		Goto Ready;
	Spawn:
		ITEM G -1;
		Stop;
	}
}

class MCBow : Weapon replaces Pistol
{
	Default
	{
		Weapon.SlotNumber 2;
		Weapon.SelectionOrder 1900;
		Weapon.AmmoType "Clip";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 20;
		Tag "Bow";
		Inventory.PickupMessage "Bow";
		Obituary "%o was shot by %k.";
	}
	States
	{
	Ready:
		BOWW A 1 A_WeaponReady;
		Loop;
	Deselect:
		BOWW A 1 A_Lower(12);
		Loop;
	Select:
		BOWW A 1 A_Raise(12);
		Loop;
	Fire:
		BOWW B 4 A_StartSound("mc/bow/draw", CHAN_WEAPON);
		BOWW C 4;
		BOWW D 5;
		BOWW A 0 { A_StartSound("mc/bow/shoot", CHAN_WEAPON, CHANF_OVERLAP); A_FireProjectile("MCPlayerArrow", 0, true, 0, 0, 0, -1.5); }
		BOWW A 7 A_ReFire;
		Goto Ready;
	Spawn:
		ITEM H -1;
		Stop;
	}
}

// Multishot: three arrows in a fan, then the crank reload.
class MCCrossbow : Weapon
{
	mixin MCDisguise;
	Default
	{
		Weapon.SlotNumber 3;
		Weapon.SelectionOrder 1300;
		Weapon.AmmoType "Shell";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 12;
		Tag "Crossbow";
		Inventory.PickupMessage "Crossbow (multishot)";
		Obituary "%o was skewered by %k's crossbow.";
	}
	States
	{
	Ready:
		XBOW A 1 A_WeaponReady;
		Loop;
	Deselect:
		XBOW A 1 A_Lower(12);
		Loop;
	Select:
		XBOW A 1 A_Raise(12);
		Loop;
	Fire:
		XBOW B 4
		{
			A_StartSound("mc/bow/shoot", CHAN_WEAPON);
			A_FireProjectile("MCBolt", 0, true, 0, 0, 0, -1);
			A_FireProjectile("MCBolt", 7, false, 0, 0, 0, -1);
			A_FireProjectile("MCBolt", -7, false, 0, 0, 0, -1);
		}
		XBOW C 7 A_StartSound("mc/xbow/load", CHAN_WEAPON, CHANF_OVERLAP);
		XBOW D 7;
		XBOW A 5 A_ReFire;
		Goto Ready;
	Spawn:
		ITEM I -1;
		Stop;
	}
}
class MCShotgunSpot : MCCrossbow replaces Shotgun {}
class MCSuperShotgunSpot : MCCrossbow replaces SuperShotgun {}
class MCChaingunSpot : MCCrossbow replaces Chaingun {}
class MCPlasmaSpot : MCCrossbow replaces PlasmaRifle {}
class MCChainsawSpot : MCSword replaces Chainsaw {}

// Throw a lit TNT block: it bounces, blinks white, and blows up.
class MCTNT : Weapon replaces RocketLauncher
{
	mixin MCDisguise;
	Default
	{
		Weapon.SlotNumber 5;
		Weapon.SelectionOrder 2500;
		Weapon.AmmoType "RocketAmmo";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 6;
		+WEAPON.NOAUTOFIRE
		Tag "TNT";
		Inventory.PickupMessage "TNT!";
		Scale 0.5;
		Obituary "%o was blown up by %k's TNT.";
	}
	States
	{
	Ready:
		TNTH A 1 A_WeaponReady;
		Loop;
	Deselect:
		TNTH A 1 A_Lower(12);
		Loop;
	Select:
		TNTH A 1 A_Raise(12);
		Loop;
	Fire:
		TNTH B 6 A_StartSound("mc/tnt/ignite", CHAN_WEAPON);
		TNTH C 4 A_FireProjectile("MCThrownTNT", 0, true, 0, 0, 0, -12);
		TNTH D 8;
		TNTH A 10 A_ReFire;
		Goto Ready;
	Spawn:
		TNTB A -1;
		Stop;
	}
}
class MCBFGSpot : MCTNT replaces BFG9000 {}

class MCPlayerArrow : MCArrow
{
	Default
	{
		Speed 46;
		DamageFunction (random(14, 22));
		-NOGRAVITY
		Gravity 0.12;
		Obituary "%o was shot by %k.";
	}
	States
	{
	Spawn:
		ARRW A 1 A_SpawnItemEx("MCCritStar", -6, 0, 0, frandom(-0.3, 0.3), frandom(-0.3, 0.3), frandom(-0.3, 0.3), 0, SXF_NOCHECKPOSITION, 120);
		Loop;
	}
}

class MCBolt : MCPlayerArrow
{
	Default { DamageFunction (random(10, 15)); Obituary "%o was skewered by %k's crossbow."; }
}

class MCThrownTNT : Actor
{
	int fuse;
	Default
	{
		Projectile;
		-NOGRAVITY
		Gravity 0.7;
		Radius 10;
		Height 16;
		Speed 20;
		Damage 0;
		Scale 0.5;
		BounceType "Doom";
		BounceFactor 0.35;
		WallBounceFactor 0.4;
		+BOUNCEONACTORS
		+CANBOUNCEWATER
		-NOBLOCKMAP
		BounceSound "mc/place";
	}
	override void Tick()
	{
		Super.Tick();
		if (isFrozen()) return;
		if (++fuse >= 46)
		{
			A_Explode(150, 200, XF_HURTSOURCE);
			Spawn("MCExplosion", pos + (0, 0, 8));
			Destroy();
		}
	}
	States
	{
	Spawn:
		TNTB A 4;
		TNTB B 4;
		Loop;
	Death:
		TNTB A 4;
		TNTB B 4;
		Loop;
	}
}

// Barrels are TNT blocks: shoot one and it lights, blinks, and explodes a moment later (chains included).
class MCTNTBlock : Actor replaces ExplosiveBarrel
{
	mixin MCDisguise;
	Default
	{
		Health 20;
		Radius 15;
		Height 32;
		Scale 0.5;
		+SOLID
		+SHOOTABLE
		+NOBLOOD
		+ACTIVATEMCROSS
		+DONTGIB
		+NOICEDEATH
		+OLDRADIUSDMG
		DeathSound "mc/tnt/ignite";
		Obituary "%o went boom with the TNT.";
		Tag "TNT";
	}
	States
	{
	Spawn:
		TNTB A -1;
		Stop;
	Death:
		TNTB B 4 A_Scream;
		TNTB A 4;
		TNTB B 4;
		TNTB A 4;
		TNTB B 4;
		TNTB A 3;
		TNTB B 3;
		TNTB A 3 A_NoBlocking;
		TNTB B 2 { A_Explode(128, 192); Spawn("MCExplosion", pos + (0, 0, 16)); }
		TNT1 A 1050 A_BarrelDestroy;
		TNT1 A 5 A_Respawn;
		Wait;
	}
}

// Sword hits: crit stars on mobs, block chips on walls.
class MCSwordPuff : Actor
{
	Default { +NOINTERACTION +PUFFONACTORS +PUFFGETSOWNER RenderStyle "None"; AttackSound "mc/punch"; }
	States
	{
	Spawn:
		TNT1 A 1 NoDelay { MCImpact.PuffChips(self); }
		Stop;
	Crash:
		TNT1 A 1 { MCImpact.PuffChips(self); }
		Stop;
	}
}

// Bullets of the other weapons: chips of the block that was hit.
class MCBulletPuff : BulletPuff replaces BulletPuff
{
	States
	{
	Spawn:
		TNT1 A 0 NoDelay { MCImpact.PuffChips(self); }
		CRIT A 4 Bright;
		Stop;
	}
}
