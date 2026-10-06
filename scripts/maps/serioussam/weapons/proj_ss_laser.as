class proj_ss_laser : ScriptBaseEntity
{
	void Spawn()
	{
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		
		g_EntityFuncs.SetModel( self, LASER_MODEL_PROJECTILE );
		g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );
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
	
		if ( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() == true )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg, g_Engine.v_forward, tr, DMG_ENERGYBEAM | DMG_NEVERGIB ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
			
		}
		
		g_EntityFuncs.Remove( self );
	}
}

proj_ss_laser@ ShootLaser( EHandle &in eOwner, Vector vecStart, Vector vecVelocity, int damage )
{
	CBaseEntity@ pevOwner = eOwner.GetEntity();
	CBaseEntity@ cbeSSLaser = g_EntityFuncs.CreateEntity( "proj_ss_laser", null,  false);
	
	proj_ss_laser@ pLaser = cast<proj_ss_laser@>(CastToScriptClass(cbeSSLaser));
	
	g_EntityFuncs.DispatchSpawn( pLaser.self.edict() );
	g_EntityFuncs.SetOrigin( pLaser.self, vecStart );
	
	@pLaser.pev.owner = pevOwner.edict();
	pLaser.pev.velocity = vecVelocity;
	pLaser.pev.angles = Math.VecToAngles( pLaser.pev.velocity );
	pLaser.pev.dmg = damage;
	
	pLaser.SetTouch( TouchFunction( pLaser.ExplodeTouch ) );
	
	return pLaser;
}

void RegisterSSLASER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_laser", "proj_ss_laser" );
}