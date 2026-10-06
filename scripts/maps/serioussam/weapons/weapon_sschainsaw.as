enum SSCHAINSAWAnimation
{
	SSCHAINSAW_IDLE = 0,
	SSCHAINSAW_ATTACK_START,
	SSCHAINSAW_ATTACK_LOOP,
	SSCHAINSAW_ATTACK_END,
	SSCHAINSAW_DRAW
};

const int SSCHAINSAW_WEIGHT			= 69;

class weapon_sschainsaw : ScriptBasePlayerWeaponEntity
{
	private int m_iInAttack;
	private int m_iAnimate;
	
	TraceResult m_trHit;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_chainsaw.mdl" );
		
		m_iAnimate = 0;
		
		self.m_iClip =	-1;
		
		BaseClass.Spawn();
		self.FallInit();
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -30;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 30;
			}
		}
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_chainsaw.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_chainsaw.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_chainsaw.mdl");
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/beginfire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/bringdown.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/bringup.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/endfire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/idle.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/chainsaw/saw_flesh01.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/beginfire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/bringdown.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/bringup.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/endfire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/idle.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/chainsaw/saw_flesh01.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_sschainsaw.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 0;
		info.iPosition	= 6;
		info.iFlags		= 0;
		info.iWeight	= SSCHAINSAW_WEIGHT;
		
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
		
		NetworkMessage sschainsaw( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			sschainsaw.WriteLong( self.m_iId );
		sschainsaw.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
		m_iAnimate = 0;
		m_iInAttack = 0;
		
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/chainsaw/fire.ogg" );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/chainsaw/idle.ogg" );
			
		BaseClass.Holster( skipLocal ); 
    }
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool Deploy()
	{	
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/serioussam/weapons/v_chainsaw.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_chainsaw.mdl" ), SSCHAINSAW_DRAW, "minigun" , 0 );
			
			float deployTime = 0.5;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}
	
	void PrimaryAttack()
	{
		if (m_iInAttack == 0)
		{
			self.SendWeaponAnim( SSCHAINSAW_ATTACK_START );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, "serioussam/weapons/chainsaw/beginfire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/chainsaw/idle.ogg" );
			
			m_iInAttack = 1;
			
			return;
		}
		
		if ( m_iInAttack == 1 )
		{
			ChainsawAttack();
				
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.075;
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2;
	}
	
	void ChainsawAttack()
	{
		if ( m_iAnimate == 0 )
		{
			self.SendWeaponAnim( SSCHAINSAW_ATTACK_LOOP );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/chainsaw/fire.ogg", 0.9, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );
			m_iAnimate = 1;
			return;
		}
	
		ChainsawHit( false );
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_SAW );
	}
	
	bool ChainsawHit( bool m_bSecondaryAttack )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 69;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
					
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 1.1;
			
			/*
			float x,y,z;
			
			x = Math.RandomFloat(0.5,1);
			y = Math.RandomFloat(0.5,1);
			z = 0;
			
			m_pPlayer.pev.punchangle = Vector(x,y,z);
			*/
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
			
			g_WeaponFuncs.ClearMultiDamage();
			
			int iDamage = 25;
			
			pEntity.TraceAttack( m_pPlayer.pev, iDamage, g_Engine.v_forward, tr, DMG_SNIPER | DMG_SLASH | DMG_ALWAYSGIB );
			
			if(!pEntity.IsBSPModel())
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_BODY, "serioussam/weapons/chainsaw/saw_flesh01.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					int x,y,z;
					
					x = Math.RandomLong(1,2);
					y = Math.RandomLong(1,2);
					z = 0;
					
					m_pPlayer.pev.punchangle = Vector(x,y,z);
					
					m_pPlayer.m_iWeaponVolume = 128;
					
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				fvolbar = 1;

				int x,y,z;
					
				x = Math.RandomLong(1,2);
				y = Math.RandomLong(1,2);
				z = 0;
					
				m_pPlayer.pev.punchangle = Vector(x,y,z);
			}

			m_trHit = tr;
			
			Smack();

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		
		return fDidHit;
	}
	
	void WeaponIdle()
	{
		if( m_iInAttack == 1 )
		{
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/chainsaw/fire.ogg" );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, "serioussam/weapons/chainsaw/endfire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			self.SendWeaponAnim( SSCHAINSAW_ATTACK_END );
			m_iInAttack = 0;
			m_iAnimate = 0;
			return;
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( SSCHAINSAW_IDLE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/chainsaw/idle.ogg", 0.9, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 30.0;
	}
}

void RegisterSSCHAINSAW()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_sschainsaw", "weapon_sschainsaw" );
	g_ItemRegistry.RegisterWeapon( "weapon_sschainsaw", "serioussam" );
}