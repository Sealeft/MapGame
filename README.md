Final Year University Project that received a first class grade\
3D game where the user can explore any real world place by streaming 3D models from Google Earth\
Features first person parkour movement, a grappling hook, and a checkpoint system\
\
Interesting files to note:\
MapGame/map-game-godot/scripts holds most of the important scripts and code\
scripts/FirstPersonPlayer.gd controls a significant amount of player action, scripts/player folder holds some specialized player scripts\
scripts/GameWorld.gd handles loading the 3D world\
scripts/ObjectiveSystem.gd handles spawning objectives, keeping track of score, changes in game state\
test/integration/SceneInstantiationTest.gd runs tests using GDUnit plugin (similar to JUnit), to make sure aspects of the game world are being instatiated properly
