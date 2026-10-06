enum SkillItemMapping
{
	ITEMS_EASY,
	ITEMS_NORM,
	ITEMS_HARD
}

class SkillLevel
{
	int lives;
	float extraLifeMultiplier;
	string readableName;
	float scoreMultiplier;
	float enemyHpMultiplier;
	float enemyMultiplier;
	int itemMapping;
	
	SkillLevel(int startlives, float xtra, float score, float hpenemy, float enemy, string readable, int mapping)
	{
		lives = startlives;
		extraLifeMultiplier = xtra;
		scoreMultiplier = score;
		readableName = readable;
		enemyHpMultiplier = hpenemy;
		enemyMultiplier = enemy;
		itemMapping = mapping;
	}
	
	SkillLevel(const SkillLevel &in other)
	{
		lives = other.lives;
		extraLifeMultiplier = other.extraLifeMultiplier;
		scoreMultiplier = other.scoreMultiplier;
		readableName = other.readableName;
		enemyHpMultiplier = other.enemyHpMultiplier;
		enemyMultiplier = other.enemyMultiplier;
		itemMapping = other.itemMapping;
	}
}

string GLOBAL_SKILL;
bool GLOBAL_SKILLVOTE_RUNNING = false;
dictionary GLOBAL_SKILLMAP = 
{
	//                             start	live	score		enemy	enemy
	//                             lives	mult 	mult		hpmult	mult	name		remapper
	{"skill_tourist",	SkillLevel(200,		4.0f,	3.0f,		0.5f,	0.8f,	"tourist",	ITEMS_EASY)},
	{"skill_easy",		SkillLevel(100,		2.0f,	2.0f,		0.8f,	1.0f,	"easy",		ITEMS_EASY)},
	{"skill_normal",	SkillLevel(50,		1.0f,	1.5f,		1.0f,	1.25f,	"normal",	ITEMS_NORM)},
	{"skill_hard", 		SkillLevel(25,		0.6f,	1.25f,		1.5f,	1.5f,	"hard",		ITEMS_NORM)},
	{"skill_serious",	SkillLevel(15,		0.4f,	1.0f,		2.0f,	1.75f,	"serious",	ITEMS_HARD)},
	{"skill_mental", 	SkillLevel(1,		0.1f,	1.0f,		2.0f,	2.0f,	"mental",	ITEMS_HARD)}
};

void SkillVote( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if(GLOBAL_SKILLVOTE_RUNNING)
		return;
		
	GLOBAL_SKILLVOTE_RUNNING = true;
	string sk = string(pCaller.pev.targetname);
	g_Game.AlertMessage( at_console, "skill vote: "+sk+" \n" );
	
	SkillLevel@ skl = cast<SkillLevel>(GLOBAL_SKILLMAP[sk]);
	
	Vote@ skillvote = Vote("Skill vote", "Do you want to play on "+skl.readableName+"?", 5, 66.0f);
	skillvote.SetYesText("Yes");
	skillvote.SetNoText("No");
	skillvote.SetUserData(any(sk));
	skillvote.SetVoteBlockedCallback(SkillVoteBlocked);
	skillvote.SetVoteEndCallback(SkillVoteEnd);
	skillvote.Start();
}

void SkillVoteBlocked(Vote@ pVote, float flTime)
{
	string sk;
	pVote.GetUserData().retrieve(sk);
	g_Game.AlertMessage( at_console, "skill vote blocked: "+sk+" \n" );
	GLOBAL_SKILLVOTE_RUNNING = false;
}

void SkillVoteEnd(Vote@ pVote, bool fResult, int iVoters)
{
	string sk;
	pVote.GetUserData().retrieve(sk);
	g_Game.AlertMessage( at_console, "skill vote end: "+sk+" result: "+(fResult?"true":"false")+"\n" );
	if(fResult)
	{
		g_Scheduler.SetTimeout("StartModeVote", 1.0f, sk);
	}
	else
	{
		GLOBAL_SKILLVOTE_RUNNING = false;
	}
}

void StartModeVote(string sk)
{
	Vote@ skillvote = Vote("Mode vote", "Select game mode", 5, 66.0f);
	skillvote.SetYesText("Coin-op");
	skillvote.SetNoText("Normal");
	skillvote.SetUserData(any(sk));
	skillvote.SetVoteBlockedCallback(SkillVoteBlocked);
	skillvote.SetVoteEndCallback(ModeVoteEnd);
	skillvote.Start();
}

void ModeVoteEnd(Vote@ pVote, bool fResult, int iVoters)
{
	string sk;
	pVote.GetUserData().retrieve(sk);
	g_Game.AlertMessage( at_console, "skill vote end 2 : "+sk+" result: "+(fResult?"true":"false")+"\n" );
	
	GLOBAL_SKILL = sk;
	SkillLevel@ skl = cast<SkillLevel>(GLOBAL_SKILLMAP[GLOBAL_SKILL]);
	if(fResult)
	{
		GLOBAL_COIN_COOP = true;
		
		GLOBAL_LIVES = skl.lives;
		
		SendCoinCoopToAll();
	}
	
	RemapArmorTypes();
	RemapHealthTypes();
	g_PlayerFuncs.ScreenFadeAll(Vector(0.0, 16.0, 0.0), 3.0f, 1.0f, 255, 1);
	g_Scheduler.SetTimeout("MoveSpawn", 3.5f);
}