// Doom's pickups as Minecraft items: apples heal, chestplates are armor, arrows and TNT are the ammo.
class MCApple : Stimpack replaces Stimpack
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Apple (+10 health)"; Inventory.PickupSound "mc/eat"; Scale 0.8; }
	States { Spawn: ITEM A -1; Stop; }
}
class MCGoldenApple : Medikit replaces Medikit
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Golden Apple (+25 health)"; Inventory.PickupSound "mc/eat"; Scale 0.8; }
	States { Spawn: ITEM B -1 Bright; Stop; }
}
class MCGoldNugget : HealthBonus replaces HealthBonus
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Glistering nugget (+1 health)"; Scale 0.6; }
	States { Spawn: ITEM K -1 Bright; Stop; }
}
class MCIronNugget : ArmorBonus replaces ArmorBonus
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Iron nugget (+1 armor)"; Scale 0.6; }
	States { Spawn: ITEM F -1; Stop; }
}
class MCIronChestplate : GreenArmor replaces GreenArmor
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Iron Chestplate"; Scale 0.8; }
	States { Spawn: ITEM C -1; Stop; }
}
class MCDiamondChestplate : BlueArmor replaces BlueArmor
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Diamond Chestplate"; Scale 0.8; }
	States { Spawn: ITEM D -1 Bright; Stop; }
}
class MCDiamond : Soulsphere replaces Soulsphere
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "A diamond! (+100 health)"; Scale 0.9; }
	States { Spawn: ITEM J 6 Bright; ITEM J 6; Loop; }
}
class MCArrowsSmall : Clip replaces Clip
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Arrows"; Scale 0.7; }
	States { Spawn: ITEM E -1; Stop; }
}
class MCArrowsBox : ClipBox replaces ClipBox
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "A bundle of arrows"; Scale 0.9; }
	States { Spawn: ITEM E -1; Stop; }
}
class MCBolts : Shell replaces Shell
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "Crossbow bolts"; Scale 0.7; }
	States { Spawn: ITEM E -1; Stop; }
}
class MCBoltsBox : ShellBox replaces ShellBox
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "A quiver of bolts"; Scale 0.9; }
	States { Spawn: ITEM E -1; Stop; }
}
class MCTNTAmmo : RocketAmmo replaces RocketAmmo
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "TNT"; Scale 0.35; }
	States { Spawn: TNTB A -1; Stop; }
}
class MCTNTCrate : RocketBox replaces RocketBox
{
	mixin MCDisguise;
	Default { Inventory.PickupMessage "A stack of TNT"; Scale 0.45; }
	States { Spawn: TNTB A -1; Stop; }
}
