// kamikaze
// code is a mess. totally hacked together monster :P

void RegisterMonsterKamikaze()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_kamikaze", "monster_kamikaze" );
}

void makeKamikazeExplosion(Vector &in origin)
{
	CBaseEntity@ pWorld = g_EntityFuncs.Instance(0);
	g_WeaponFuncs.RadiusDamage(	origin, pWorld.pev, pWorld.pev, 30, 120, CLASS_NONE, DMG_BLAST );
	NetworkMessage exp1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
		exp1.WriteByte( TE_EXPLOSION );
		exp1.WriteCoord( origin.x );
		exp1.WriteCoord( origin.y );
		exp1.WriteCoord( origin.z+40 );
		exp1.WriteShort( g_EngineFuncs.ModelIndex("sprites/zerogxplode.spr") );
		exp1.WriteByte( 30 );
		exp1.WriteByte( 25 );
		exp1.WriteByte( 4 );
	exp1.End();
}

class monster_kamikaze : ScriptBaseMonsterEntity
{
	void Spawn(){
		Precache();
		g_EntityFuncs.SetModel(self, "models/serioussam/enemies/takecover.mdl");
		g_EntityFuncs.SetSize(self.pev, Vector(-20, -20, -0), Vector(20, 20, 60));
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = DONT_BLEED;
		self.pev.health = 25;
		self.pev.view_ofs = Vector(0, 0, 60);
		self.pev.yaw_speed = 180;
		self.m_flFieldOfView = VIEW_FIELD_WIDE;
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_afCapability = bits_CAP_HEAR | bits_CAP_MELEE_ATTACK1 | bits_CAP_MELEE_ATTACK2;
		self.m_FormattedName = "Kamikaze";
		//@this.m_Schedules = @gizmoSchedules;
		self.MonsterInit();
	}
	
	Vector BodyTarget( const Vector& in posSrc ) 
	{ 
		return Center();
	}
	
	Vector Center()
	{
		return self.pev.origin + Vector(0,0,40);
	}
	
	void Killed(entvars_t@ pevAttacker, int iGibbed)
	{
		Die();
	}
	
	void Die()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "serioussam/enemies/kamikaze/attack.ogg" );
		iShouting = 2;
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "serioussam/weapons/explosion02.ogg", 1.0f, ATTN_NORM);
		g_Scheduler.SetTimeout("makeKamikazeExplosion", 0.02f, self.pev.origin);
		g_EntityFuncs.Remove(self);
	}
	
	int Classify()
	{
		return CLASS_ALIEN_PREDATOR;
	}
	
	void Touch(CBaseEntity@ pOther)
	{
		if(pOther.pev.takedamage == DAMAGE_NO)
			return;
			
		if(pOther.Classify() == Classify())
			return;
			
		if(pOther.IsPlayer())
			Die();
			
		BaseClass.Touch(pOther);
	}
	
	void IdleSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "serioussam/enemies/kamikaze/idle.ogg", 0.9, ATTN_NORM, 0,  94+Math.RandomLong(0,16) );
	}
	
	void StartShouting()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "serioussam/enemies/kamikaze/attack.ogg", 0.4, ATTN_NORM, SND_FORCE_LOOP, 94+Math.RandomLong(0,16) );
		iShouting = 1;
	}
	
	void StopShouting()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "serioussam/enemies/kamikaze/attack.ogg" );
		iShouting = 0;
	}
	
	int iShouting = 0;
	
	void PrescheduleThink()
	{
		if(self.m_MonsterState == MONSTERSTATE_COMBAT && iShouting == 0)
			StartShouting();
		else if (self.m_MonsterState != MONSTERSTATE_COMBAT && iShouting == 1)
			StopShouting();
		else if(self.m_MonsterState != MONSTERSTATE_COMBAT && Math.RandomFloat(0, 5) < 0.1f && iShouting == 0)
			IdleSound();
			
		if(self.pev.waterlevel > 0)
			Die();
			
	}
	
	bool CheckRangeAttack1(float f,  float ff)	{ return false; }
	bool CheckRangeAttack1_move(float f,  float ff)	{ return false; }
	bool CheckRangeAttack2(float f,  float ff)	{ return false; }
	bool CheckRangeAttack2_move(float f,  float ff)	{ return false; }
	
	bool melee(float fDot, float fDist)
	{
		if(fDist <= 100)
		{
			Die();
			return true;
		}
		
		return false;
	}
	
	bool CheckMeleeAttack1(float f, float ff) { return melee(f, ff); }
	bool CheckMeleeAttack1_move(float f, float ff) { return melee(f, ff); }
	bool CheckMeleeAttack2(float f, float ff) { return melee(f, ff); }
	bool CheckMeleeAttack2_move(float f, float ff) { return melee(f, ff); }
	
	void TraceAttack(entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in traceResult, int bitsDamageType)
	{
		if( pevAttacker is null )
			return;
			
		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
		pAttacker.pev.frags = pAttacker.pev.frags + 0.5f;
		BaseClass.TraceAttack(pevAttacker, flDamage, vecDir, traceResult, bitsDamageType);
	}
	
	void Precache()
	{
		g_Game.PrecacheModel("models/serioussam/enemies/takecover.mdl");
		g_Game.PrecacheModel("sprites/zerogxplode.spr");
		g_SoundSystem.PrecacheSound("serioussam/enemies/kamikaze/attack.ogg");
		g_SoundSystem.PrecacheSound("serioussam/enemies/kamikaze/idle.ogg");
		g_SoundSystem.PrecacheSound("serioussam/weapons/explosion02.ogg");
		g_Game.PrecacheGeneric("sound/serioussam/enemies/kamikaze/attack.ogg");
		g_Game.PrecacheGeneric("sound/serioussam/enemies/kamikaze/idle.ogg");
		g_Game.PrecacheGeneric("sound/serioussam/weapons/explosion02.ogg");
	}
	
	
}