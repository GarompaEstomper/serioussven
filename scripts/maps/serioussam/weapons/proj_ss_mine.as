
int MINE_DAMAGE = 200;

class proj_ss_mine : ScriptBaseMonsterEntity
{
	private float m_fAirTime;
	private float m_flArmDelay;
	private CSprite@ glow;
	
	private bool m_bArmed;
	
	void Spawn()
	{
		@glow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", self.pev.origin, false ); 
		glow.SetTransparency( 3, 0, 255, 0, 255, 14 );
		glow.SetScale( 0.2 );
		glow.SetAttachment( self.edict(), 1 );
		glow.SetBrightness( 255 );
		
		m_bArmed = false;
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_SLIDEBOX;
		
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/mine.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
	}

	void SpawnedThink()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		m_fAirTime = g_Engine.time + 0.25;
		
		if( self.pev.velocity.Length()  <= 1.0f && m_bArmed == false )
		{
			SetThink( ThinkFunction( TimeToArm ));
			self.pev.nextthink = g_Engine.time;
		}
		
		self.pev.nextthink = g_Engine.time + 0.01;
	}
	
	void TimeToArm()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		self.pev.nextthink = g_Engine.time + 0.1;
		
		if ( m_fAirTime <= g_Engine.time )
		{
			ArmMine();
			return;
		}
	}
	
	void DetonateUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		Detonate();
	}
	
	void Detonate()
	{	
		g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "serioussam/weapons/minelayer/detonating.ogg", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		self.pev.nextthink = g_Engine.time + 0.5;
		SetThink( ThinkFunction( this.Explode ) );
	}
	
	void Explode()
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		te_explosion( self.pev.origin, SS_MINELAYER::MINELAYER_SPRITE_EXPLOSION, 100, 30, 4 );
		te_explosion( self.pev.origin, SS_MINELAYER::MINELAYER_SPRITE_EXPLOSION2, 100, 30, 4 );
		
		TraceResult tr;
		
		g_Utility.TraceLine( self.pev.origin, self.pev.origin + Vector( 0, 0, -32 ),  dont_ignore_monsters, self.edict(), tr );
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
		
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/explosion01.ogg", 0.8, 0.3 );
		
		g_WeaponFuncs.RadiusDamage(	self.pev.origin, self.pev, pevOwner, self.pev.dmg, 192, CLASS_NONE, DMG_BLAST | DMG_NEVERGIB );
		
		g_EntityFuncs.Remove( glow );
		g_EntityFuncs.Remove( self );
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( glow );
			g_EntityFuncs.Remove( self );
			return;
		}
		
		Vector vecVelocity = self.pev.velocity * 0.6f;
		self.pev.velocity = vecVelocity;
	}
	
	void te_explosion( Vector origin, string sprite, int scale, int frameRate, int flags )
	{
		NetworkMessage exp1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			exp1.WriteByte( TE_EXPLOSION );
			exp1.WriteCoord( origin.x );
			exp1.WriteCoord( origin.y );
			exp1.WriteCoord( origin.z );
			exp1.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
			exp1.WriteByte( int((scale-50) * .90) );
			exp1.WriteByte( frameRate );
			exp1.WriteByte( flags );
		exp1.End();
	}

	void ArmMine()
	{
		glow.SetColor( 255 , 0 , 0 );
		
		m_bArmed = true;
		self.pev.iuser1 = 1;
		self.pev.movetype = MOVETYPE_NONE;
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/minelayer/arm.ogg", 0.8, 0.3 );
		
		SetUpProx();
	}
	
	void SetUpProx()
	{
		//slight delay so we have time to run the fuck away from it
		m_flArmDelay = g_Engine.time + 1.0;
			
		SetThink( ThinkFunction( this.ProxThink ) );
		self.pev.nextthink = g_Engine.time + 0.1;
	}
	
	void ProxThink()
	{
		CBaseEntity@ ents = null;
		if ( m_flArmDelay < g_Engine.time )
		{
		// using FindEntityInSphere until I figure out how to do it the proper way :P
		while( ( @ents = g_EntityFuncs.FindEntityInSphere( ents, self.GetOrigin(), 96, "*", "classname" ) ) !is null )
			{
				EHandle g_ehandle = ents;
				if( g_ehandle.GetEntity().IsMonster()   ) 
				{
					if( g_ehandle.GetEntity().pev.takedamage == DAMAGE_NO || g_ehandle.GetEntity().pev.classname == "proj_ss_mine" || g_ehandle.GetEntity().IsPlayer() == true  )
						continue;
					
					Detonate();
				}
			}
		}
		
		self.pev.nextthink = g_Engine.time + 0.5;
	}
}

proj_ss_mine ShootMine( EHandle &in eOwner, Vector vecStart, Vector vecVelocity, int damage )
{
	CBaseEntity@ pevOwner = eOwner.GetEntity();
	
	CBaseEntity@ cbeSSMine = g_EntityFuncs.CreateEntity( "proj_ss_mine", null,  false);
	proj_ss_mine@ pMine = cast<proj_ss_mine@>(CastToScriptClass(cbeSSMine));
	
	g_EntityFuncs.SetOrigin( pMine.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pMine.self.edict() );
	
	pMine.pev.scale = 1.2f;
	
	@pMine.pev.owner = pevOwner.edict();
	pMine.pev.velocity = vecVelocity;
	pMine.SetThink( ThinkFunction( pMine.SpawnedThink ) );
	pMine.pev.nextthink = g_Engine.time + 0.01;
	pMine.SetTouch( TouchFunction( pMine.Touch ) );
	pMine.SetUse( UseFunction( pMine.DetonateUse ) );
	pMine.pev.dmg = damage;
	
	return pMine;
}

void RegisterSSMINE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_mine", "proj_ss_mine" );
}