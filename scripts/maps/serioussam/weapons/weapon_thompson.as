
enum TOMMYAnimation
{
	TOMMY_IDLE = 0,
	TOMMY_SHOOT,
	TOMMY_DRAW
};

namespace SS_TOMMYGUN
{
	const int TOMMY_DEFAULT_GIVE	= 50;
	const int TOMMY_MAX_CARRY		= 500;
	const int TOMMY_WEIGHT			= 5;
	
	const string TOMMY_P_MODEL	= "models/serioussam/weapons/p_tommygun.mdl";
	const string TOMMY_V_MODEL	= "models/serioussam/weapons/v_tommygun.mdl";
	const string TOMMY_W_MODEL	= "models/serioussam/weapons/w_tommygun.mdl";
}

class weapon_thompson : ScriptBasePlayerWeaponEntity
{	
	private CBasePlayer@ m_pPlayer = null;
	private int shellmdl;
	
	void Spawn()
	{
		shellmdl = g_Game.PrecacheModel( "models/shell.mdl" );
		g_EntityFuncs.SetModel( self, SS_TOMMYGUN::TOMMY_W_MODEL );
		
		BaseClass.Spawn();
		
		self.m_iDefaultAmmo = SS_TOMMYGUN::TOMMY_DEFAULT_GIVE;
		self.FallInit();
		
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
		
		g_Game.PrecacheModel( SS_TOMMYGUN::TOMMY_P_MODEL );
		g_Game.PrecacheModel( SS_TOMMYGUN::TOMMY_V_MODEL );
		g_Game.PrecacheModel( SS_TOMMYGUN::TOMMY_W_MODEL );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/tommygun_fire.ogg" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/tommygun_fire.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_thompson.txt" );
		g_Game.PrecacheGeneric( "events/muzzle_ss_tommygun.txt" );
	}
   
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1  = SS_TOMMYGUN::TOMMY_MAX_CARRY;
		info.iMaxAmmo2  = -1;
		info.iMaxClip   = WEAPON_NOCLIP;
		info.iSlot	  	= 3;
		info.iPosition  = 5;
		info.iFlags	 	= 0;
		info.iWeight	= SS_TOMMYGUN::TOMMY_WEIGHT;
	   
		return true;
	}
   
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		
		@m_pPlayer = pPlayer;
		
		NetworkMessage tommy( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			tommy.WriteLong( self.m_iId );
		tommy.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
 
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( SS_TOMMYGUN::TOMMY_V_MODEL ), self.GetP_Model( SS_TOMMYGUN::TOMMY_P_MODEL ), TOMMY_DRAW, "m16" );
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			
			return bResult;
		}
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.09f; // 0.09
		self.m_flTimeWeaponIdle = g_Engine.time + 6.9;
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( TOMMY_SHOOT, 0, 0 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/tommygun_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		Vector vecSpread = Vector(0.015, 0.015, 0.015); // add really really small amount of spread
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecSpread, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, 0 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * vecSpread.x * g_Engine.v_right 
						+ y * vecSpread.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		int iDamage = 20;
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
				}
				
				g_WeaponFuncs.ClearMultiDamage();
					
				if( pHit.pev.takedamage != DAMAGE_NO && pHit.pev.classname != "monster_robogrunt" && pHit.pev.classname != "monster_gargantua" )
				{
						
						pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_SNIPER | DMG_NEVERGIB ); 
				}
				else if ( pHit.pev.classname == "monster_robogrunt" && pHit.IsAlive() == true )
				{
							//all damage done to robogrunts is multiplied by 0.15
							pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_ENERGYBEAM | DMG_NEVERGIB ); 
				}
				else if ( pHit.pev.classname == "monster_gargantua" && pHit.IsAlive() == true )
				{
							//do slight damage to gargs
							pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_BLAST | DMG_SNIPER | DMG_NEVERGIB ); 
				}	
				
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}
		}
		
		Vector vecShellVelocity, vecShellOrigin;
       
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
		CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 17, 10, -9, false, false );
       
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
       
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], shellmdl, TE_BOUNCE_SHELL );
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( TOMMY_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 6, 9 );
	}
}

void RegisterTOMMY()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_thompson", "weapon_thompson" );
	g_ItemRegistry.RegisterWeapon( "weapon_thompson", "serioussam", "9mm" );
}