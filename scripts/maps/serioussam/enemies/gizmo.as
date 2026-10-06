// gizmo
// code is a mess. totally hacked together monster :P

void RegisterMonsterGizmo()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_gizmo", "monster_gizmo" );
	InitGizmoSchedule();
}

array<ScriptSchedule@>@ gizmoSchedules;

ScriptSchedule gizmoRangeAttack1(
	bits_COND_ENEMY_OCCLUDED,
	0,
	"GizmoRangeAttack1"
);

void InitGizmoSchedule()
{
	gizmoRangeAttack1.AddTask(ScriptTask(TASK_STOP_MOVING));
	gizmoRangeAttack1.AddTask(ScriptTask(TASK_FACE_IDEAL));
	gizmoRangeAttack1.AddTask(ScriptTask(TASK_RANGE_ATTACK1));
	gizmoRangeAttack1.AddTask(ScriptTask(TASK_WAIT_RANDOM, 0.5f));
	
	array<ScriptSchedule@> scheds = {gizmoRangeAttack1};
	
	@gizmoSchedules = @scheds;
}

class monster_gizmo : ScriptBaseMonsterEntity
{
	void Spawn(){
		Precache();
		g_EntityFuncs.SetModel(self, "models/serioussam/enemies/gizmo.mdl");
		//g_EntityFuncs.SetModel(self, "models/headcrab.mdl");
		g_EntityFuncs.SetSize(self.pev, Vector(-18, -22, -0), Vector(18, 22, 10));
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		self.pev.health = 25;
		self.pev.view_ofs = Vector(0, 0, 30);
		self.pev.yaw_speed = 180;
		self.m_flFieldOfView = VIEW_FIELD_WIDE;
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_afCapability = bits_CAP_HEAR | bits_CAP_RANGE_ATTACK1;
		self.m_FormattedName = "Gizmo";
		@this.m_Schedules = @gizmoSchedules;
		self.MonsterInit();
	}
	
	Vector BodyTarget( const Vector& in posSrc ) 
	{ 
		return Center();
	}
	
	Vector Center()
	{
		return self.pev.origin + Vector(0,0,20);
	}
	
	void Killed(entvars_t@ pevAttacker, int iGibbed)
	{
		Die();
	}
	
	void Die()
	{
		DeathSound();
		g_Utility.BloodDrips(Center(), Vector(0,0,0), BLOOD_COLOR_GREEN, 4);

		g_EntityFuncs.SpawnRandomGibs(self.pev, 1, 0);
		
		g_EntityFuncs.Remove(self);
	}
	
	int Classify()
	{
		return CLASS_ALIEN_PREDATOR;
	}
	
	void Leap()
	{
		self.pev.flags &= ~FL_ONGROUND;
		//self.pev.origin.z += 1;
		Math.MakeVectors(self.pev.angles);
		Vector vecJumpDir;
		
		CBaseEntity@ pEnemy = cast<CBaseEntity@>(self.m_hEnemy);
		if(pEnemy !is null)
		{
			float gravity = 800; // todo: get cvar
			
			float height = pEnemy.pev.origin.z + pEnemy.pev.view_ofs.z - self.pev.origin.z;
			
			if(height < 16)
				height = 16; 
				
			float speed = sqrt(2*gravity*height);
			float time = speed / gravity;
			vecJumpDir = pEnemy.pev.origin + pEnemy.pev.view_ofs - self.pev.origin;
			
			vecJumpDir = vecJumpDir * (1.0f/time);
			vecJumpDir.z = speed;
			float distance = vecJumpDir.Length();
			if(distance > 650 * self.pev.scale)
				vecJumpDir = vecJumpDir*(650/distance);
		}else{
			vecJumpDir = Vector(g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z);
		}
		
		AlertSound(0.4f);
		self.pev.velocity = vecJumpDir;
		self.m_flNextAttack = g_Engine.time + 2 + Math.RandomFloat(1.0,4.0);
	}
	
	void LeapTouch(CBaseEntity@ pOther)
	{
		if(pOther.pev.takedamage == DAMAGE_NO)
			return;
			
		if(pOther.Classify() == Classify())
			return;
			
		if(self.pev.flags & FL_ONGROUND > 0)
			return;
			
		Vector vecDir = pOther.pev.origin - self.pev.origin;
		if(DotProduct(vecDir, self.pev.velocity) <= 0)
			return;
			
		pOther.TakeDamage(self.pev, self.pev, 5, DMG_SLASH);
			
		SetTouch(null);
	}
	
	void StartTask(Task@ task)
	{
		switch(task.iTask)
		{
			case TASK_RANGE_ATTACK1:
			{
				if(self.pev.flags & FL_ONGROUND > 0)
				{
					SetTouch(TouchFunction(LeapTouch));
					Leap();
				}
				break;
			}
			default: BaseClass.StartTask(task); break;
		}
	}
	
	void RunTask(Task@ task)
	{
		/*switch(task.iTask)
		{
			case TASK_RANGE_ATTACK1:
				{
					self.TaskComplete();
					SetTouch(null);
					break;
				}
		}*/
		
		BaseClass.RunTask(task);
	}
	
	Schedule@ GetScheduleOfType ( int Type )
	{
		switch(Type)
		{
			case SCHED_RANGE_ATTACK1:return gizmoRangeAttack1;
		}
		
		return BaseClass.GetScheduleOfType(Type);
	}
	
	Schedule@ GetSchedule()
	{
		switch(self.m_MonsterState)
		{
			case MONSTERSTATE_COMBAT:
			{
				if ( self.HasConditions( bits_COND_ENEMY_DEAD ) )				
					return BaseClass.GetSchedule();
					
				return GetScheduleOfType(SCHED_RANGE_ATTACK1);
			}
		}
		
		return BaseClass.GetSchedule();
	}
	
	bool CheckRangeAttack1(float flDot, float flDist)
	{
		if(self.pev.flags & FL_ONGROUND > 0)
			if(flDist <= 333*self.pev.scale)
				return true;
				
		return false;
	}
	
	void IdleSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "serioussam/enemies/gizmo/idle.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void AlertSound(float fVolume)
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "serioussam/enemies/gizmo/sight.ogg", fVolume, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void DeathSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "serioussam/enemies/gizmo/death.ogg", 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void PrescheduleThink()
	{
		if(self.m_MonsterState == MONSTERSTATE_COMBAT && Math.RandomFloat(0, 5) < 0.1f)
			IdleSound();
			
		if(self.pev.waterlevel > 0)
			Die();
			
	}
	
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
		g_Game.PrecacheModel("models/serioussam/enemies/gizmo.mdl");
		g_Game.PrecacheModel("models/headcrab.mdl");
		g_Game.PrecacheModel("models/agibs.mdl");
		g_SoundSystem.PrecacheSound("serioussam/enemies/gizmo/death.ogg");
		g_SoundSystem.PrecacheSound("serioussam/enemies/gizmo/idle.ogg");
		g_SoundSystem.PrecacheSound("serioussam/enemies/gizmo/sight.ogg");
		g_Game.PrecacheGeneric("sound/serioussam/enemies/gizmo/death.ogg");
		g_Game.PrecacheGeneric("sound/serioussam/enemies/gizmo/idle.ogg");
		g_Game.PrecacheGeneric("sound/serioussam/enemies/gizmo/sight.ogg");
	}
	
	
}