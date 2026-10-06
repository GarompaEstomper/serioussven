int PLASMA_DAMAGE = 30;

class proj_ss_plasma : ScriptBaseEntity
{
	void Spawn()
	{
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		self.pev.scale = 1.0;
		self.pev.skin = 1; //use red laser skin
		
		g_EntityFuncs.SetModel( self, SS_PLASMATHROWER::LASER_MODEL_PROJECTILE2 );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );	
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
		
		g_WeaponFuncs.RadiusDamage(	self.pev.origin, self.pev, pevOwner, PLASMA_DAMAGE, 96, CLASS_NONE, DMG_BLAST );
		
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/plasmathrower/explosion.ogg", 0.8, 0.3 );
		
		NetworkMessage explosion( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			explosion.WriteByte(TE_EXPLOSION);
			explosion.WriteCoord(self.pev.origin.x);
			explosion.WriteCoord(self.pev.origin.y);
			explosion.WriteCoord(self.pev.origin.z);
			explosion.WriteShort( g_EngineFuncs.ModelIndex( SS_PLASMATHROWER::PLASMATHROWER_SPRITE_EXPLOSION ) ); // explosion sprite
			explosion.WriteByte(20);
			explosion.WriteByte(30);
			explosion.WriteByte(4);
		explosion.End();
		
		int r = 0, g = 255, b = 0, decay = 50;
	
		int8 dynlife = 10;
		
		NetworkMessage dynlight( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			dynlight.WriteByte( TE_DLIGHT );
			dynlight.WriteCoord( self.pev.origin.x );
			dynlight.WriteCoord( self.pev.origin.y );
			dynlight.WriteCoord( self.pev.origin.z );
			dynlight.WriteByte( 8 );
			dynlight.WriteByte( int(r) );
			dynlight.WriteByte( int(g) );
			dynlight.WriteByte( int(b) );
			dynlight.WriteByte( dynlife );
			dynlight.WriteByte( decay );
		dynlight.End();
	
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
		
		if ( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() == true )
		{
			g_WeaponFuncs.ClearMultiDamage();
			
			pOther.TraceAttack( pevOwner, PLASMA_DAMAGE, g_Engine.v_forward, tr, DMG_ENERGYBEAM | DMG_NEVERGIB ); 
			
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
			
		}
		
		g_EntityFuncs.Remove( self );
	}
}



proj_ss_plasma@ ShootPlasma( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeSSPlasma = g_EntityFuncs.CreateEntity( "proj_ss_plasma", null,  false);
	
	proj_ss_plasma@ pPlasma = cast<proj_ss_plasma@>(CastToScriptClass(cbeSSPlasma));
	
	g_EntityFuncs.DispatchSpawn( pPlasma.self.edict() );
	
	g_EntityFuncs.SetOrigin( pPlasma.self, vecStart );
	
	pPlasma.pev.velocity = vecVelocity;
	pPlasma.pev.angles = Math.VecToAngles( pPlasma.pev.velocity );
	
	@pPlasma.pev.owner = pevOwner.pContainingEntity;
	pPlasma.SetTouch( TouchFunction( pPlasma.ExplodeTouch ) );
	
	pPlasma.pev.dmg = PLASMA_DAMAGE;
	
	int r=242, g=186, b=90, br=200;
		
		NetworkMessage ntrail1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			ntrail1.WriteByte( TE_BEAMFOLLOW );
			ntrail1.WriteShort( pPlasma.self.entindex() );
			ntrail1.WriteShort( g_EngineFuncs.ModelIndex( "sprites/smoke.spr" )  );
			ntrail1.WriteByte( 30 );//Life
			ntrail1.WriteByte( 3 );//Width
			ntrail1.WriteByte( int(r) );
			ntrail1.WriteByte( int(g) );
			ntrail1.WriteByte( int(b) );
			ntrail1.WriteByte( int(br) );
		ntrail1.End();
		
	return pPlasma;
}

void RegisterSSPLASMA()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_plasma", "proj_ss_plasma" );
}