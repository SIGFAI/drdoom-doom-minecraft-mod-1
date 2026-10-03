// Doom's decorations as Minecraft things: oak trees, torches, redstone lamps and glowstone posts (they light the room).
class MCTree : Actor
{
	mixin MCDisguise;
	Default { Radius 16; Height 200; Scale 0.5; +SOLID; Tag "Oak Tree"; }
	States { Spawn: TREE A -1; Stop; }
}
class MCTreeBig : MCTree replaces BigTree {}
class MCTreeBurnt : MCTree replaces TorchTree {}

class MCTorch : Actor
{
	mixin MCDisguise;
	Default { Radius 8; Height 30; Scale 0.8; +SOLID; Tag "Torch"; }
	States { Spawn: TRCH ABCD 5 Bright; Loop; }
}
class MCTorchTallRed : MCTorch replaces RedTorch {}
class MCTorchTallGreen : MCTorch replaces GreenTorch {}
class MCTorchTallBlue : MCTorch replaces BlueTorch {}
class MCTorchShortRed : MCTorch replaces ShortRedTorch {}
class MCTorchShortGreen : MCTorch replaces ShortGreenTorch {}
class MCTorchShortBlue : MCTorch replaces ShortBlueTorch {}
class MCTorchCandle : MCTorch replaces Candlestick { Default { -SOLID Scale 0.6; } }
class MCTorchCandelabra : MCTorch replaces Candelabra {}
class MCTorchBarrel : MCTorch replaces BurningBarrel {}

class MCRedstoneLamp : Actor
{
	mixin MCDisguise;
	Default { Radius 16; Height 64; Scale 0.42; +SOLID; Tag "Redstone Lamp"; }
	States { Spawn: LAMP A -1 Bright; Stop; }
}
class MCLampTech : MCRedstoneLamp replaces TechLamp {}
class MCLampTech2 : MCRedstoneLamp replaces TechLamp2 { Default { Scale 0.34; Height 52; } }

class MCGlowPost : Actor
{
	mixin MCDisguise;
	Default { Radius 16; Height 60; Scale 0.48; +SOLID; Tag "Glowstone"; }
	States { Spawn: POST A -1 Bright; Stop; }
}
class MCGlowColumn : MCGlowPost replaces Column {}
class MCGlowPillar : MCGlowPost replaces TechPillar { Default { Scale 0.55; Height 70; } }
