Laser Sword for Unity
(c) 2016 Digital Ruby, LLC
Created by Jeff Johnson
http://www.digitalruby.com

Laster Sword for Unity is a highly realistic and beautiful representation of a beam sword. With a volumetric blade, glow, sounds and great looking hilt, this laser sword will wow your friends, co-workers and users.

Instructions:
I've created three prefabs for you: LaserSwordWhite, LaserSwordRed, and LaserSwordPurple. These are ready to be used as is. Simply drag the prefab into your scene and parent it to the appropriate object.

Scripting:
To turn on / off the weapon, call Activate, Deactivate, SetActive or TurnOn. All will get the job done. The weapon will not turn on or off if it is in progress of turning on or off.

The demo has added a rotation to the weapons, but you can set this to 0 for your app or game (i.e. script.RotationSpeed = Vector3.zero, or set it in the inspector), or just remove the property entirely.

Note: LaserSwordBladeCreatorScript is the script that creates the blade, and is a component on the top level of the prefab object, along with LaserSwordScript.

Physics:
The hilt and blade both have mesh colliders. The blade is a trigger. To allow the weapon to be thrown, you will have to move the LaserSwordRoot transform yourself.

Customization:
You can easily build your own laser sword by cloning the prefab and changing all the properties.

How to create your own laser sword:
1] Swap out the hilt 3D model with one of your own. LaserSwordHilt in the prefab contains the mesh filter and material. You'll need to set these to your own mesh and material.
  1a] For best results, the hilt model should be pointing straight up along the y axis without any additional rotation applied.
2] Change the hilt position, rotation and scale to be appropriate for your model.
3] Change the blade height to be appropriate for your usage.
4] Change the start and end radius of the blade to your liking.
5] Swap out the mesh renderer material on the LaserSwordBlade (LaserSwordRoot -> LaserSwordHilt -> LaserSwordBlade) to change colors.
6] The LaserSwordBlade object uses a custom shader, so you probably just want to copy an existing material, such as LaserSwordBladeWhiteMaterial, change the texture and tint colors, and use that.
7] The LaserSwordBladeGlow object uses volumetric glow with a capsule.
8] Change the audio clips on LaserSwordScript for on/off/constant to your own if you like.
9] Set the BladeStart object to the top of your hilt, right where you want the blade to come out.
10] There is no need to set BladeEnd, it is calculated automatically based off of the blade height.
11] Change the color of the LaserSwordLight object if you want. The glow color will match.
12] The rim color changes the color towards the edges of the weapon. For best results, keep this somewhat similar to the regular tint color.

Rotation:
Set all rotation values to 0 on LaserSwordScript to disable the demo rotation.

Anti-Aliasing:
If you are using deferred rendering, you should import the anti-aliasing script from the standard effects package, plust anti-aliasing shaders and add the script to your camera. For forward rendering, be sure you enable anti-aliasing for better looking edges on the weapon.

Please email support@digitalruby.com if you have further questions.

- Jeff