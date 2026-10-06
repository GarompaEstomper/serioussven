class proj_ss_rocket : ScriptBaseEntity
{
	private int m_iSmoke, m_iZbeam1, m_iExplosion, m_iExplosion2;
	
	void Spawn()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/projectilefly.ogg", 1, ATTN_NORM );
		
		m_iSmoke = g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_SMOKE  );
		m_iZbeam1 = g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_ZBEAM1 );
		m_iExplosion = g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_EXPLOSION );
		m_iExplosion2 = g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_EXPLOSION2 );
		
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		self.pev.scale = 1.5;
		
		g_EntityFuncs.SetModel( self, SS_ROCKETLAUNCHER::ROCKET_MODEL_PROJECTILE );
		g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );	
	}
	
	void TrailThink()
	{		
		int r=200, g=200, b=200, br=128;
		
		NetworkMessage ntrail1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			ntrail1.WriteByte( TE_BEAMFOLLOW );
			ntrail1.WriteShort( self.entindex() );
			ntrail1.WriteShort( m_iSmoke  );
			ntrail1.WriteByte( 30 );//Life
			ntrail1.WriteByte( 7 );//Width
			ntrail1.WriteByte( int(r) );
			ntrail1.WriteByte( int(g) );
			ntrail1.WriteByte( int(b) );
			ntrail1.WriteByte( int(br) );
		ntrail1.End();
	}
	
	void ExplosionEffect( Vector origin )
	{
		NetworkMessage explosion( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			explosion.WriteByte(TE_EXPLOSION);
			explosion.WriteCoord(origin.x);
			explosion.WriteCoord(origin.y);
			explosion.WriteCoord(origin.z);
			explosion.WriteShort(m_iExplosion); // explosion sprite
			explosion.WriteByte(60);
			explosion.WriteByte(20);
			explosion.WriteByte(4);
		explosion.End();
		
		NetworkMessage explosion2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			explosion2.WriteByte(TE_EXPLOSION);
			explosion2.WriteCoord(origin.x);
			explosion2.WriteCoord(origin.y);
			explosion2.WriteCoord(origin.z);
			explosion2.WriteShort( m_iExplosion2 ); // explosion sprite2
			explosion2.WriteByte(60);
			explosion2.WriteByte(20);
			explosion2.WriteByte(4);
		explosion2.End();
	}
	
	void ExplodeTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		TraceResult tr;
		
		Vector vecSpot = self.pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + pev.velocity.Normalize() * 64;
		
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		entvars_t@ pevOwner = self.pev.owner.vars;
		
		g_WeaponFuncs.RadiusDamage(	self.pev.origin, self.pev, pevOwner, self.pev.dmg * 0.75, 200, CLASS_NONE, DMG_BLAST );
		
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/explosion01.ogg", 0.8, 0.3 );
		
		int r = 240, g = 180, b = 0, decay = 50;
	
		int8 dynlife = 10;
		
		NetworkMessage dynlight( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			dynlight.WriteByte( TE_DLIGHT );
			dynlight.WriteCoord( self.pev.origin.x );
			dynlight.WriteCoord( self.pev.origin.y );
			dynlight.WriteCoord( self.pev.origin.z );
			dynlight.WriteByte( 32 );
			dynlight.WriteByte( int(r) );
			dynlight.WriteByte( int(g) );
			dynlight.WriteByte( int(b) );
			dynlight.WriteByte( dynlife );
			dynlight.WriteByte( decay );
		dynlight.End();
	
		ExplosionEffect( self.pev.origin );
		
		if ( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() == true )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg * 1.75, g_Engine.v_forward, tr, DMG_BLAST ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
		}
		
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
		g_EntityFuncs.Remove( self );
	}
}

proj_ss_rocket@ ShootRocket( EHandle &in eOwner, Vector vecStart, Vector vecVelocity, int damage )
{
	CBaseEntity@ pevOwner = eOwner.GetEntity();
	CBaseEntity@ cbeSSRocket = g_EntityFuncs.CreateEntity( "proj_ss_rocket", null,  false);
	
	proj_ss_rocket@ pRocket = cast<proj_ss_rocket@>(CastToScriptClass(cbeSSRocket));
	
	g_EntityFuncs.SetOrigin( pRocket.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pRocket.self.edict() );
	
	pRocket.pev.velocity = vecVelocity;
	pRocket.pev.angles = Math.VecToAngles( pRocket.pev.velocity );
	@pRocket.pev.owner = pevOwner.edict();
	pRocket.SetTouch( TouchFunction( pRocket.ExplodeTouch ) );
	
	pRocket.pev.dmg = damage;
	
	pRocket.SetThink( ThinkFunction( pRocket.TrailThink ) );
	pRocket.pev.nextthink = 0.1;
	
	//g_Game.AlertMessage( at_console, "Damage: %1\n", pRocket.pev.dmg );
	
	return pRocket;
}

void RegisterSSROCKET()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_rocket", "proj_ss_rocket" );
}