class ammo_ssbullets : ScriptBasePlayerAmmoEntity
{
	void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_bullets.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 50, "9mm", 500 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSBULLETS()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_ssbullets", "ammo_ssbullets" );
}

class ammo_ssshells : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_shells.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 10, "ssshells", 100 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSSHELLS()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_ssshells", "ammo_ssshells" );
}

class ammo_sscannonballs : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_cannonballs.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 4, "cannonballs", 30 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSCANNONBALLS()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_sscannonballs", "ammo_sscannonballs" );
}

class ammo_sscells : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_cells.mdl" );
        BaseClass.Spawn();
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		self.pev.movetype = MOVETYPE_NONE;
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 40, "energycells", 400 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSCELLS()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_sscells", "ammo_sscells" );
}

class ammo_ssgrenades : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_grenades.mdl" );
		
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 10, "ssgrenades", 50 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSGRENADES()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_ssgrenades", "ammo_ssgrenades" );
}

class ammo_ssnapalm : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_napalm.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 50, "ssnapalm", 500 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSNAPALM()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_ssnapalm", "ammo_ssnapalm" );
}

class ammo_ssrockets : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_rockets.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 5, "ssrockets", 50 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSROCKETS()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_ssrockets", "ammo_ssrockets" );
}

class ammo_sssniper : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_sniperbullets.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 36;
			}
		}
    }
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 5, "sniperbullets", 50 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterSSSNIPERBULLETS()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_sssniper", "ammo_sssniper" );
}

class ammo_plasmapack : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_plasmapack.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
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
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 50, "plasmacells", 150 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterPLASMAPACK()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_plasmapack", "ammo_plasmapack" );
}

class ammo_minepack : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/ammo/ammo_minepack.mdl" );
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
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
   
    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 3, "mines", 30 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterMINEPACK()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "ammo_minepack", "ammo_minepack" );
}