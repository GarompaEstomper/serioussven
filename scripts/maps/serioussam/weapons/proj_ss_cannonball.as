
array<string> g_Explodeonthis = 
{
	"monster_babygarg",
	"monster_apache",
	"monster_gargantua"
};

class proj_ss_cannonball : ScriptBaseEntity
{
	private int m_iSmoke, m_iExplosion;
	private float m_fAirTime, m_fNextDamageTime;
	
	void Think()
	{
		int classass;
		entvars_t@ pevOwner = self.pev.owner.vars;
		CBaseEntity@ pOther = g_EntityFuncs.Instance(self.pev.owner);
		self.pev.angles.z = -Math.VecToAngles( self.pev.velocity ).x;
		
		classass = pOther.Classify();
		m_fAirTime = g_Engine.time + 3.0;
		
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		if( self.pev.velocity.Length()  > 32.0f  )
		{
			g_WeaponFuncs.RadiusDamage(	self.pev.origin, self.pev, pevOwner, self.pev.dmg, 75, classass, DMG_CRUSH | DMG_ALWAYSGIB );
		}
		
		if( self.pev.velocity.Length()  <= 10.0f )
		{
			SetThink( ThinkFunction( TickThink ));
			SetTouch(null);
			self.pev.nextthink = g_Engine.time;
		}
		
		if( self.pev.velocity.Length()  > 5000.0f )
		self.pev.gravity = 3.0;
	
		self.pev.nextthink = g_Engine.time + 0.04f;
	}
	
	void TickThink()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		self.pev.nextthink = g_Engine.time + 0.1;
		
		if ( m_fAirTime <= g_Engine.time )
		{
			Explode( self.pev.origin );
		}
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		if ( pOther.pev.ClassNameIs("proj_ss_cannonball") || pOther is g_EntityFuncs.Instance(self.pev.owner) )
		{
			return;
		}
		
		m_fNextDamageTime = g_Engine.time + 1.0;
		
		TraceResult tr;
		
		Vector vecSpot = self.pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + pev.velocity.Normalize() * 64;
		
		g_Utility.TraceLine( vecSpot, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		Vector vecVelocity = self.pev.velocity * 0.7f;
		self.pev.velocity = vecVelocity;
		self.pev.gravity = 1.0;
		
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		if (pOther is null || pOther.IsBSPModel() || pOther.edict() is self.pev.owner ) 
		{
			if (self.pev.velocity.Length() > 15.0) 
			{
				g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "serioussam/weapons/cannon/bounce.ogg", 1.0, ATTN_NORM, 0, 100);
			}
			
			if (self.pev.velocity.Length() > 4000.0) 
			{
				vecVelocity = self.pev.velocity * 0.7f;
				g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "serioussam/weapons/cannon/bounce.ogg", 1.0, ATTN_NORM, 0, 100);
			} 
		}
				
		if ( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() )
		{
			for( uint i = 0; i < g_Explodeonthis.length(); i++ )
			{
				if ( pOther.pev.classname == g_Explodeonthis [ i ] && self.pev.velocity.Length() > 1000.0 )
				{
					Explode( self.pev.origin );
				}
			}
			
			pOther.pev.velocity = pOther.pev.velocity + ( self.pev.origin - pOther.pev.origin ).Normalize() * -100;
		}
	}
	
	void Explode( Vector origin )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		CannonBallExplosion( self.pev.origin, SS_CANNON::CANNONBALL_SPRITE_EXPLOSION, 90, 30, 4 );
		CannonBallExplosion( self.pev.origin, SS_CANNON::CANNONBALL_SPRITE_EXPLOSION2, 90, 30, 4 );
		
		TraceResult tr;
		
		g_Utility.TraceLine( self.pev.origin, self.pev.origin + Vector( 0, 0, -32 ),  dont_ignore_monsters, self.edict(), tr );
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
		
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "serioussam/weapons/explosion02.ogg", 0.8, 0.3 );
		
		g_WeaponFuncs.RadiusDamage(	self.pev.origin, self.pev, pevOwner, 200, 150, CLASS_NONE, DMG_BLAST | DMG_NEVERGIB );
		
		g_EntityFuncs.Remove( self );
	}
	
	void Spawn()
	{
		m_iExplosion = g_Game.PrecacheModel("sprites/zerogxplode.spr");
		
		self.pev.solid = SOLID_TRIGGER;
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.friction = 0;
		
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/cannonball.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector( -17, -17, -28 ), Vector( 17, 17, 28 ) );
	}
	
	void CannonBallExplosion( Vector origin, string sprite, int scale, int frameRate, int flags )
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

proj_ss_cannonball@ ShootCannonBall( EHandle &in eOwner, Vector vecStart, Vector vecVelocity, float damagescale )
{
	CBaseEntity@ pevOwner = eOwner.GetEntity();
	CBaseEntity@ cbeSSCannonBall = g_EntityFuncs.CreateEntity( "proj_ss_cannonball", null,  false);
	
	proj_ss_cannonball@ pCannonBall = cast<proj_ss_cannonball@>(CastToScriptClass(cbeSSCannonBall));
	
	g_EntityFuncs.DispatchSpawn( pCannonBall.self.edict() );
	g_EntityFuncs.SetOrigin( pCannonBall.self, vecStart );
	
	@pCannonBall.pev.owner = pevOwner.edict();
	pCannonBall.pev.velocity = vecVelocity;
	pCannonBall.pev.angles = Math.VecToAngles( pCannonBall.pev.velocity );
	pCannonBall.pev.dmg = damagescale;
		
	pCannonBall.SetTouch( TouchFunction( pCannonBall.Touch) );
	pCannonBall.SetThink( ThinkFunction( pCannonBall.Think ) );
	pCannonBall.pev.nextthink =  0.1;
	
	//g_Game.AlertMessage( at_console, "Damage: %1\n", pCannonBall.pev.dmg );
	
	return pCannonBall;
}


void RegisterSSCannonBall()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_cannonball", "proj_ss_cannonball" );
}