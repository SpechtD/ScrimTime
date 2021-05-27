#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

ConVar g_cVarGameMode;
ConVar g_cVarGameType;

bool isInLobby = true;

public Plugin myinfo =
  {
    name = "ScrimTime",
    author = "SauerkrautKebap",
    description = "",
    version = "1.0",
    url = "https://github.com/SauerkrautKebap/ScrimTime"};


public void OnPluginStart()
{
    RegConsoleCmd("readyvote", Command_ReadyVote);
    RegAdminCmd("start_game", Command_StartGame, ADMFLAG_CHANGEMAP, "immediately starts the game without voting");
    g_cVarGameMode = FindConVar("game_mode");
    g_cVarGameType = FindConVar("game_type");
}

public void OnMapStart()
{
    switch(isInLobby)
    {
    case true:
    {
        g_cVarGameType.IntValue = 1;
        g_cVarGameMode.IntValue = 2;
    }
    case false:
    {
        GameRules_SetProp("m_nQueuedMatchmakingMode", 1, 1, 0, true);
        g_cVarGameType.IntValue = 0;
        g_cVarGameMode.IntValue = 1;
    }
    }
}

public Action Command_ReadyVote(int client, int args)
{
    PrintToServer("Starting ready vote");
    if(IsVoteInProgress())
        return Plugin_Handled;

    Menu menu = new Menu(Handle_VoteMenu);
    menu.VoteResultCallback = Handle_VoteResults;
    menu.SetTitle("Ready?");
    menu.AddItem("yes", "Yes");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);

    return Plugin_Handled;
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
        /* This is called after VoteEnd */
        delete menu;
}

public void Handle_VoteResults(Menu menu,
                        int num_votes,
                        int num_clients,
                        const int[][] client_info,
                        int num_items,
                        const int[][] item_info)
{
    if(num_votes < GetClientCount())
    {
        PrintToChatAll("%d players are not ready", GetClientCount() - num_votes);
        PrintCenterTextAll("%d players are not ready", GetClientCount() - num_votes);
        return;
    }
    PrintToChatAll("All players ready");
    PrintCenterTextAll("All players ready");
    StartGame();
}

public Action Command_StartGame(int client, int args)
{
    StartGame();
}

public void StartGame()
{

    PrintToChatAll("Starting map veto...");
    PrintCenterTextAll("Starting map veto...");
    isInLobby = false;
    ForceChangeLevel("lobby_mapveto", "start map vote");
}
