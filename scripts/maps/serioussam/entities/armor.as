void RemapArmorTypes()
{
	array<string> modemap = {"item_ss_armor_shard", "item_ss_armor_small", "item_ss_armor_medium", "item_ss_armor_strong", "item_ss_armor_super"};

	CBaseEntity@ pEntity = null;
	while((@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "item_ss_armor_*")) !is null)
	{
		CBaseEntity@ pNew = g_EntityFuncs.CreateEntity("item_ss_armor", null, false);
		g_EntityFuncs.DispatchKeyValue(pNew.edict(), "m_Mode", modemap.find(string(pEntity.pev.classname)));
		g_EntityFuncs.DispatchKeyValue(pNew.edict(), "angles", string(pEntity.pev.angles.x)+" "+string(pEntity.pev.angles.y)+" "+string(pEntity.pev.angles.z));
		g_EntityFuncs.DispatchKeyValue(pNew.edict(), "origin", string(pEntity.pev.origin.x)+" "+string(pEntity.pev.origin.y)+" "+string(pEntity.pev.origin.z));
		g_EntityFuncs.DispatchSpawn(pNew.edict());
	
		g_EntityFuncs.Remove(pEntity);
		g_Game.AlertMessage( at_console, "Remapping: "+string(pEntity.pev.classname)+"-> item_ss_armor("+string(modemap.find(string(pEntity.pev.classname)))+")\n" );
	}
	
	g_Game.AlertMessage( at_console, "Remap: armor done\n"); 
}

class item_ss_armor : ScriptBasePlayerAmmoEntity
{
	int m_Mode = 0;
	
	array<string> modesounds = {"armorshard.ogg", "armorsmall.ogg", "armormedium.ogg", "armorstrong.ogg", "armorsuper.ogg"};
	array<string> modemodels = {"shard.mdl", "small.mdl", "medium.mdl", "strong.mdl", "super.mdl"};
	array<int> modevalues = {1, 25, 50, 100, 200};
	
	bool KeyValue(const string &in szKey, const string &in szValue)
	{
		if(szKey == "m_Mode")
		{
			m_Mode = atoi(szValue);
			return true;
		}
		
		return BaseClass.KeyValue(szKey, szValue);
	}

	void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/armor/"+modemodels[m_Mode] );
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
		if(m_Mode == 4)
		{
			if ( pOther.pev.armorvalue < 200 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/"+modesounds[m_Mode], 1, ATTN_NORM );
				pOther.TakeArmor( modevalues[m_Mode], DMG_GENERIC, 200 );
				return true;
			}
		}else{
			if ( pOther.pev.armorvalue < 100 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/"+modesounds[m_Mode], 1, ATTN_NORM );
				pOther.TakeArmor( modevalues[m_Mode], DMG_GENERIC, 100 );
				return true;
			}
		}
        return false;
    }
}

void RegisterItemSSArmor()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_armor", "item_ss_armor" );
}