const int HUD_POWERUP_SLOTS = 4;

void NextFreeHud(CBasePlayer@ pPlayer, int &out channel, float &out position)
{
	int slot = 0;
	
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if(!pCustom.GetKeyvalue("$i_sspslot0").Exists())
		for(int i = 0; i < HUD_POWERUP_SLOTS; i++)
			pCustom.SetKeyvalue("$i_sspslot"+string(i), 0);
			
	for(int i = 0; i < HUD_POWERUP_SLOTS; i++)
	{
		if(pCustom.GetKeyvalue("$i_sspslot"+string(i)).GetInteger() == 0)
		{
			slot = i;
			break;
		}
	}
	
	pCustom.SetKeyvalue("$i_sspslot"+string(slot), 1);
	
	/*if( !(pPlayer.HasNamedPlayerItem("item_ss_seriousdamage") is null) )
		count++;
	if( !(pPlayer.HasNamedPlayerItem("item_ss_seriousspeed") is null) )
		count++;
	if( !(pPlayer.HasNamedPlayerItem("item_ss_seriousinvuln") is null) )
		count++;
	if( !(pPlayer.HasNamedPlayerItem("item_ss_seriousjump") is null) )
		count++;*/

	channel = slot;
	int off = 64 + 24;
	position = -(off+off/2) + (off*slot);
}

abstract class SeriousPowerup : ScriptBasePlayerItemEntity
{
	CScheduledFunction@ m_pEndFunc;
	int hudChan = 0;
	float hudPos = 0.0f;
	int warns = 0;
	protected CBasePlayer@ m_pPlayer = null;
	
	int holdTime = 10;
	string model = "models/serioussam/items/seriousdamage.mdl";
	string sprite = "serioussam/seriousdamage.spr";
	
	void RemoveSeriousEffect() { g_Game.AlertMessage( at_console, "warning: unimplemented: seriouspowerup->RemoveSeriousEffect\n"); }
	void AddSeriousEffect() { g_Game.AlertMessage( at_console, "warning: unimplemented: seriouspowerup->AddSeriousEffect\n"); }
	
	void SeriousSpawn()
	{
		BaseClass.Spawn();
		self.FallInit();
		
		g_EntityFuncs.SetModel( self, model );
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.scale = 1.0f;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		self.pev.framerate = 1.0;
		
		@m_pEndFunc = null;

		TraceResult tr;
		
		Vector vecStart = self.pev.origin;
		Vector vecEnd = vecStart + g_Engine.v_up * -16;
		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr );
			
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 16;
			}
		}
	}
	
	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		NextFreeHud(pPlayer, hudChan, hudPos);
	
		HUDNumDisplayParams timerParams;
		
		timerParams.channel = hudChan*2;
		timerParams.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_TIME_SECONDS | HUD_TIME_COUNT_DOWN | HUD_TIME_RIGHT_ALIGN | HUD_ELEM_EFFECT_ONCE;
		timerParams.effect = HUD_EFFECT_RAMP_DOWN;
		timerParams.fxTime = 0.5f;
		timerParams.value = holdTime;
		timerParams.x = 0.9;
		timerParams.y = hudPos;
		timerParams.color1 = RGBA(255, 255, 255, 255);
		timerParams.color2 = RGBA(0, 255, 0, 255);
		timerParams.spritename = "serioussam/null.spr";
		g_PlayerFuncs.HudTimeDisplay(pPlayer, timerParams);
		
		HUDSpriteParams spriteParams;
		spriteParams.channel = hudChan*2+1;
		spriteParams.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_EFFECT_ONCE | HUD_SPR_MASKED;
		spriteParams.effect = HUD_EFFECT_RAMP_DOWN;
		spriteParams.fxTime = 0.5f;
		spriteParams.x = 0.9333;
		spriteParams.y = hudPos;
		spriteParams.color1 = RGBA(255, 255, 255, 255);
		spriteParams.color2 = RGBA(0, 255, 0, 255);
		spriteParams.spritename = sprite;
		g_PlayerFuncs.HudCustomSprite(pPlayer, spriteParams);
		
		@m_pPlayer = pPlayer;
		
		this.AddSeriousEffect();
		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "Warn", holdTime-5 );

		return true;
	}

	void Warn()
	{
		if( m_pPlayer is null ) return;

		HUDSpriteParams spriteParams;
		spriteParams.channel = hudChan*2+1;
		spriteParams.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_EFFECT_ONCE | HUD_SPR_MASKED;
		spriteParams.effect = HUD_EFFECT_TOGGLE;
		spriteParams.fxTime = 0.5f;
		spriteParams.x = 0.9333;
		spriteParams.y = hudPos;
		spriteParams.color1 = RGBA(255, 255, 255, 0);
		spriteParams.color2 = RGBA(255, 255, 255, 255);
		spriteParams.spritename = sprite;
		g_PlayerFuncs.HudCustomSprite(m_pPlayer, spriteParams);
		
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "serioussam/items/powerupbeep.ogg", 1.0f, ATTN_NORM );
		warns++;
		if(warns >= 10)
		{
			@m_pEndFunc = @g_Scheduler.SetTimeout( this, "RemoveEffects", 0.5f );
		}else{
			@m_pEndFunc = @g_Scheduler.SetTimeout( this, "Warn", 0.5f );
		}
	}

	void RemoveEffects()
	{
		if( m_pPlayer is null || !m_pPlayer.HasPlayerItem(self) ) return;
		
		g_PlayerFuncs.HudToggleElement(null, hudChan*2, false);
		g_PlayerFuncs.HudToggleElement(null, hudChan*2+1, false);
		
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();		
		pCustom.SetKeyvalue("$i_sspslot"+string(hudChan), 0);
		
		KillSelf();
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;
		
			if( ApplyEffects(pPlayer) )
			{
				NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
					message.WriteString( self.pszName() );
				message.End();
				
				ScheduleSeriousItemSound(pPlayer, "serioussam/items/powerup.ogg" );
				
				return true;
			}
			else
				return false;
	}

	void UpdateOnRemove()
	{
		if( !(m_pEndFunc is null) )
			g_Scheduler.RemoveTimer( m_pEndFunc );

		this.RemoveSeriousEffect();
		BaseClass.UpdateOnRemove();
	}

	void KillSelf()
	{
		if( m_pPlayer.HasPlayerItem(self) )
			m_pPlayer.RemovePlayerItem( self );

		g_EntityFuncs.Remove( self );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;

		return true;
	}
}

class item_ss_seriousdamage : SeriousPowerup
{
	void Spawn()
	{
		holdTime = 40;
		model = "models/serioussam/items/seriousdamage.mdl";
		sprite = "serioussam/seriousdamage.spr";
	
		SeriousSpawn();
	}
	
	void AddSeriousEffect()
	{
		m_pPlayer.m_flEffectDamage = 2.5f;
		m_pPlayer.ApplyEffects();
		
		g_Game.AlertMessage( at_console, "add serious effect\n");
	}
	
	void RemoveSeriousEffect()
	{
		m_pPlayer.m_flEffectDamage = 1.0f;
		m_pPlayer.ApplyEffects();
		
		g_Game.AlertMessage( at_console, "remove serious effect\n");
	}
}

void RegisterSSPowerUpSeriousDamage()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_seriousdamage", "item_ss_seriousdamage" );
	g_ItemRegistry.RegisterItem( "item_ss_seriousdamage", "serioussam/items" );
}

class item_ss_seriousspeed : SeriousPowerup
{
	void Spawn()
	{
		holdTime = 40;
		model = "models/serioussam/items/seriousspeed.mdl";
		sprite = "serioussam/seriousspeed.spr";
	
		SeriousSpawn();
	}
	
	void AddSeriousEffect()
	{
		m_pPlayer.m_flEffectSpeed = 2.5f;
		m_pPlayer.ApplyEffects();
		
		g_Game.AlertMessage( at_console, "add serious effect\n");
	}
	
	void RemoveSeriousEffect()
	{
		m_pPlayer.m_flEffectSpeed = 1.0f;
		m_pPlayer.ApplyEffects();
		
		g_Game.AlertMessage( at_console, "remove serious effect\n");
	}
}

void RegisterSSPowerUpSeriousSpeed()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_seriousspeed", "item_ss_seriousspeed" );
	g_ItemRegistry.RegisterItem( "item_ss_seriousspeed", "serioussam/items" );
}

class item_ss_seriousinvuln : SeriousPowerup
{
	void Spawn()
	{
		holdTime = 40;
		model = "models/serioussam/items/seriousinvuln.mdl";
		sprite = "serioussam/seriousinvuln.spr";
	
		SeriousSpawn();
	}
	
	void AddSeriousEffect()
	{
		m_pPlayer.m_iEffectInvulnerable = 1;
		m_pPlayer.ApplyEffects();
			
		g_Game.AlertMessage( at_console, "add serious effect\n");
	}
	
	void RemoveSeriousEffect()
	{
		m_pPlayer.m_iEffectInvulnerable = 0;
		m_pPlayer.ApplyEffects();
			
		g_Game.AlertMessage( at_console, "remove serious effect\n");
	}
}

void RegisterSSPowerUpSeriousInvuln()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_seriousinvuln", "item_ss_seriousinvuln" );
	g_ItemRegistry.RegisterItem( "item_ss_seriousinvuln", "serioussam/items" );
}

class item_ss_seriousjump : SeriousPowerup
{
	void Spawn()
	{
		holdTime = 40;
		model = "models/serioussam/items/seriousjump.mdl";
		sprite = "serioussam/seriousjump.spr";
	
		SeriousSpawn();
	}
	
	void RemoveSeriousEffect()
	{
		m_pPlayer.m_flEffectGravity = 1.0f;
		m_pPlayer.ApplyEffects();
		g_Game.AlertMessage( at_console, "remove serious effect\n");
	}
	
	void AddSeriousEffect()
	{
		m_pPlayer.m_flEffectGravity = 0.25f;
		m_pPlayer.ApplyEffects();
		g_Game.AlertMessage( at_console, "add serious effect\n");
	}	
}

void RegisterSSPowerUpSeriousJump()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_seriousjump", "item_ss_seriousjump" );
	g_ItemRegistry.RegisterItem( "item_ss_seriousjump", "serioussam/items" );
}