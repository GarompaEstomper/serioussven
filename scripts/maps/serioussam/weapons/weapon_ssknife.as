enum SSKnifeAnimation
{
	SSKNIFE_IDLE = 0,
	SSKNIFE_SLASH1,
	SSKNIFE_SLASH2,
	SSKNIFE_DRAW
};

namespace SS_KNIFE
{
	float KNIFE_DAMAGE = 120;
	
	const string KNIFE_P_MODEL = "models/serioussam/weapons/p_knife.mdl";
	const string KNIFE_V_MODEL = "models/serioussam/weapons/v_knife.mdl";
	const string KNIFE_W_MODEL = "models/serioussam/weapons/w_knife.mdl";
}

class weapon_ssknife : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	private int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.GetW_Model( SS_KNIFE::KNIFE_W_MODEL ) );
		
		BaseClass.Spawn();
		self.FallInit();
		
		self.m_iClip = -1;
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
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
	
	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( SS_KNIFE::KNIFE_P_MODEL );
		g_Game.PrecacheModel( SS_KNIFE::KNIFE_V_MODEL );
		g_Game.PrecacheModel( SS_KNIFE::KNIFE_W_MODEL );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/knife_swing.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/knife_swing.ogg" );
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_ssknife.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		
		@m_pPlayer = pPlayer;
		
		NetworkMessage ssknife( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			ssknife.WriteLong( self.m_iId );
		ssknife.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( SS_KNIFE::KNIFE_V_MODEL ), self.GetP_Model( SS_KNIFE::KNIFE_P_MODEL ), SSKNIFE_DRAW, "squeak" );
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			return bResult;
		}
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		self.SendWeaponAnim( SSKNIFE_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10, 15 );
	}
		
	void Holster( int skiplocal /* = 0 */ )
	{
		m_pPlayer.pev.viewmodel = SS_KNIFE::KNIFE_P_MODEL;
	}
	
	void PrimaryAttack()
	{
		SwingKnife();
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/knife_swing.ogg", 1, ATTN_NORM, 0, PITCH_NORM );
		
		switch( ( ( m_iSwing++ ) % 2 ) )
		{
			case 0:
				self.SendWeaponAnim( SSKNIFE_SLASH1 ); break;
			case 1:
				self.SendWeaponAnim( SSKNIFE_SLASH2 ); break;
		}
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.83;
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 6, 9 );
	}
	
	bool SwingKnife()
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
		
		if ( tr.flFraction < 1.0 )
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			
			g_WeaponFuncs.ClearMultiDamage();
			pEntity.TraceAttack( m_pPlayer.pev, SS_KNIFE::KNIFE_DAMAGE, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );  
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			if( pEntity !is null )
			{
				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() )
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
				}
			}
			
			m_trHit = tr;
			g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
		}
		
		return fDidHit;
	}
	
}

void RegisterSSKNIFE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_ssknife", "weapon_ssknife" );
	g_ItemRegistry.RegisterWeapon( "weapon_ssknife", "serioussam" );
}