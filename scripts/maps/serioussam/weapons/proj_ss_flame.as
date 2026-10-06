class proj_ss_flame : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "sprites/serioussam/ssflame.spr" );
		
		self.pev.rendermode = kRenderTransAdd;
		self.pev.renderamt = 250;  
		self.pev.scale = 0.3;
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid    = SOLID_BBOX;
		self.pev.frame = 0;
		
		SetThink( ThinkFunction( this.AnimateThink ) );
		self.pev.nextthink = g_Engine.time + 0.1;
		
		SetTouch( TouchFunction( this.FlameTouch ) );
	
		g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) );
	}
	
	void FlameTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_WATER)
		{
			g_EntityFuncs.Remove( self );
			return;
		}
	
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		if ( pOther.edict() is self.pev.owner )
			return;
		
		if ( pOther.pev.classname == "proj_ss_flame" )
		{
			self.pev.solid = SOLID_NOT;
			self.pev.movetype = MOVETYPE_NONE;
			return;
		}
			
		if ( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() == true )
		{
			// Heh, cleansuit scientists are immune to DMG_POISON in svencoop, go figure...
			if ( pOther.pev.classname == "monster_cleansuit_scientist" || pOther.IsMonster() == false )
				pOther.TakeDamage( pevOwner, pevOwner, self.pev.dmg, DMG_BURN | DMG_NEVERGIB );
			else
				pOther.TakeDamage( pevOwner, pevOwner, self.pev.dmg, DMG_BURN | DMG_POISON | DMG_NEVERGIB );
		}
		
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
		SetTouch(null);
	}

	void AnimateThink()
	{
		self.pev.nextthink = g_Engine.time + 0.03;
		
		self.pev.frame+= 1.0;
		self.pev.scale+= 0.12;
		
		if( self.pev.frame > 15 )
		{
			self.pev.frame = 0;
			g_EntityFuncs.Remove( self );
			return;
		}
	}
}

proj_ss_flame@ CreateFlameEffect( EHandle &in eOwner, Vector vecStart, Vector vecVelocity, int damage )
{
	CBaseEntity@ pevOwner = eOwner.GetEntity();
	
	CBaseEntity@ cbeSSFlame = g_EntityFuncs.CreateEntity( "proj_ss_flame", null,  false);
	proj_ss_flame@ pFlame = cast<proj_ss_flame@>(CastToScriptClass(cbeSSFlame));
	
	g_EntityFuncs.SetOrigin( pFlame.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pFlame.self.edict() );
	
	@pFlame.pev.owner = pevOwner.edict();
	pFlame.pev.velocity = vecVelocity + g_Engine.v_right * Math.RandomFloat(-30,30) + g_Engine.v_up * Math.RandomFloat(-30,30);
	pFlame.pev.angles = Math.VecToAngles( pFlame.pev.velocity );
	pFlame.pev.dmg = damage;
	return pFlame;
}

void RegisterSSFLAME()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "proj_ss_flame", "proj_ss_flame" );
}