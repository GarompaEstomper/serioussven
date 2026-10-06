class proj_ss_grenade : ScriptBaseMonsterEntity
{
	private float m_fAirTime;
	
	void Spawn()
	{
		m_fAirTime = g_Engine.time + 3.0;
		
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;
		
		g_EntityFuncs.SetModel( self, SS_GRENADELAUNCHER::SSGRENADE_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -6, -6, -4 ), Vector( 6, 6, 4 ) );
	}

	void Think()
	{
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		if ( m_fAirTime <= g_Engine.time )
		{
			Explode( false );
		}
		
		if( self.pev.velocity.Length()  > 5000.0f )
		self.pev.gravity = 1.7;
	
		self.pev.nextthink = g_Engine.time + 0.01;
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		Vector vecVelocity = self.pev.velocity * 0.6f;
		self.pev.velocity = vecVelocity;
				
		if (pOther is null || pOther.IsBSPModel() || pOther.edict() is self.pev.owner) 
		{
			if (self.pev.velocity.Length() > 15.0) 
			{
				g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "serioussam/weapons/grenadelauncher/bounce.ogg", 1.0, ATTN_NORM, 0, 100);
			} 
		}
				
		//explode on impact with monster
		if( pOther.IsMonster() && pOther.IsAlive())
		{
			Explode( true );
		}
	}
	
	void Explode( bool bContact )
	{
		TraceResult tr;
		g_Utility.TraceLine( self.pev.origin, self.pev.origin + Vector( 0, 0, -32 ),  ignore_monsters, self.edict(), tr );
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
		
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		GrenadeExplosion( self.pev.origin, SS_GRENADELAUNCHER::SSGRENADE_SPRITE_EXPLOSION, 64, 30, 4 );
		GrenadeExplosion( self.pev.origin, SS_GRENADELAUNCHER::SSGRENADE_SPRITE_EXPLOSION2, 64, 30, 4 );
		
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, ( bContact == true ? SS_GRENADELAUNCHER::SSGRENADE_DAMAGE_DIRECT + int(self.pev.dmg) : int(self.pev.dmg) ), 300, CLASS_NONE, DMG_BLAST );
		
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/explosion01.ogg", 0.8, 0.3 );
		g_EntityFuncs.Remove( self );
	}
	
	void GrenadeExplosion( Vector origin, string sprite, int scale, int frameRate, int flags )
	{
		NetworkMessage exp1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			exp1.WriteByte( TE_EXPLOSION );
			exp1.WriteCoord( origin.x );
			exp1.WriteCoord( origin.y );
			exp1.WriteCoord( origin.z );
			exp1.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
			exp1.WriteByte( int((scale)) );
			exp1.WriteByte( frameRate );
			exp1.WriteByte( flags );
		exp1.End();
	}
}

proj_ss_grenade ShootGrenade( EHandle &in eOwner, Vector vecStart, Vector vecVelocity, int damagescale )
{
	CBaseEntity@ pevOwner = eOwner.GetEntity();
	
	CBaseEntity@ cbeSSGrenade = g_EntityFuncs.CreateEntity( "proj_ss_grenade", null,  false);
	proj_ss_grenade@ pGrenade = cast<proj_ss_grenade@>(CastToScriptClass(cbeSSGrenade));
	
	g_EntityFuncs.SetOrigin( pGrenade.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );
	
	pGrenade.pev.gravity = 0.7f;
	pGrenade.pev.scale = 2.0f;
	
	@pGrenade.pev.owner = pevOwner.edict();
	pGrenade.pev.velocity = vecVelocity;
	pGrenade.pev.angles = Math.VecToAngles( pGrenade.pev.velocity );
	const Vector vecAngles = Math.VecToAngles( pGrenade.pev.velocity );
    pGrenade.pev.angles.x = vecAngles.z;
    pGrenade.pev.angles.y = vecAngles.y;
    pGrenade.pev.angles.z = vecAngles.x;
	pGrenade.SetThink( ThinkFunction( pGrenade.Think ) );
	pGrenade.pev.nextthink = g_Engine.time + 0.01;
	pGrenade.SetTouch( TouchFunction( pGrenade.Touch ) );
	pGrenade.pev.dmg = damagescale;
	
	//g_Game.AlertMessage( at_console, "Damage: %1\n", pGrenade.pev.dmg );
	
	return pGrenade;
}

void RegisterSSGrenade()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_grenade", "proj_ss_grenade" );
}