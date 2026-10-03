// Until the block wave reaches them, the things of the map keep their Doom look; then they pop into their
// Minecraft version with a puff of smoke. Only things there at map start (the demo's first summons too).
class MCDisguiseTable
{
	static const Name CLS[] = {
		'MCZombie', 'MCSkeleton', 'MCCreeper', 'MCSpider', 'MCGhast',
		'MCTreeBig', 'MCTreeBurnt', 'MCTorchTallRed', 'MCTorchTallGreen', 'MCTorchTallBlue', 'MCTorchShortRed',
		'MCTorchShortGreen', 'MCTorchShortBlue', 'MCTorchCandle', 'MCTorchCandelabra', 'MCTorchBarrel', 'MCLampTech',
		'MCLampTech2', 'MCGlowColumn', 'MCGlowPillar', 'MCTNTBlock',
		'MCApple', 'MCGoldenApple', 'MCGoldNugget', 'MCIronNugget', 'MCIronChestplate', 'MCDiamondChestplate', 'MCDiamond',
		'MCArrowsSmall', 'MCArrowsBox', 'MCBolts', 'MCBoltsBox', 'MCTNTAmmo', 'MCTNTCrate',
		'MCShotgunSpot', 'MCSuperShotgunSpot', 'MCChaingunSpot', 'MCPlasmaSpot', 'MCChainsawSpot', 'MCTNT', 'MCBFGSpot'
	};
	static const Name SPR[] = {
		'POSS', 'SPOS', 'TROO', 'SARG', 'HEAD',
		'TRE2', 'TRE1', 'TRED', 'TGRN', 'TBLU', 'SMRT',
		'SMGT', 'SMBT', 'CAND', 'CBRA', 'FCAN', 'TLMP',
		'TLP2', 'COLU', 'ELEC', 'BAR1',
		'STIM', 'MEDI', 'BON1', 'BON2', 'ARM1', 'ARM2', 'SOUL',
		'CLIP', 'AMMO', 'SHEL', 'SBOX', 'ROCK', 'BROK',
		'SHOT', 'SGN2', 'MGUN', 'PLAS', 'CSAW', 'LAUN', 'BFUG'
	};
	static const int FRAMES[] = {
		4, 4, 4, 4, 1,
		1, 1, 4, 4, 4, 4,
		4, 4, 1, 1, 3, 4,
		4, 1, 1, 2,
		1, 1, 4, 4, 2, 2, 4,
		1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1
	};

	static Name, int Lookup(Name cls)
	{
		for (int i = 0; i < MCDisguiseTable.CLS.Size(); i++) if (MCDisguiseTable.CLS[i] == cls) return MCDisguiseTable.SPR[i], MCDisguiseTable.FRAMES[i];
		return 'NONE', 0;
	}
}

mixin class MCDisguise
{
	bool mcDisguised;
	int mcAt, mcFrames;
	SpriteID mcSprite;
	Vector2 mcScale;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (level.maptime > 3) return;
		Name spr;
		[spr, mcFrames] = MCDisguiseTable.Lookup(GetClassName());
		if (mcFrames <= 0) return;
		mcSprite = GetSpriteIndex(spr);
		mcScale = scale;
		mcAt = -1;
		mcDisguised = true;
		scale = (1, 1);
		sprite = mcSprite;
		frame = 0;
	}

	override void Tick()
	{
		Super.Tick();
		if (!mcDisguised || bDestroyed) return;
		if (self is 'Inventory' && Inventory(self).Owner) { mcDisguised = false; scale = mcScale; return; }
		if (mcAt < 0) mcAt = MCWorld.ArrivalTic(pos.xy);
		if (mcAt >= 0 && level.maptime >= mcAt)
		{
			mcDisguised = false;
			scale = mcScale;
			sprite = CurState.sprite;
			frame = CurState.Frame;
			MCWorld.PopInto(self);
			return;
		}
		sprite = mcSprite;
		frame = frame % mcFrames;
	}
}
