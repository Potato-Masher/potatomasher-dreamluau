local SS13 = require("SS13")

SS13.wait(1)

local ADMIN_MODE = false
local user = SS13.get_runner_client()

soundsByHttp = soundsByHttp or {}

local loadSound = function(http)
	if soundsByHttp[http] then
		return soundsByHttp[http]
	end

	local request = SS13.new("/datum/http_request")
	local file_name = "tmp/custom_map_sound.ogg"
	request:prepare("get", http, "", "", file_name)
	request:begin_async()
	while request:is_complete() == 0 do
		sleep()
	end
	soundsByHttp[http] = SS13.new("/sound", file_name)
	return soundsByHttp[http]
end

local fireSound = {
	loadSound("https://cdn.discordapp.com/attachments/1335457966924628029/1335458249943814164/pistol_fire3.wav?ex=67a03dea&is=679eec6a&hm=47152b9643b1b29067bb500ed7c765d5c79a376b0a13672386875009e42e0e89&")
}
local dryfireSound = {
	loadSound("https://cdn.discordapp.com/attachments/1335457966924628029/1335458249394229268/pulse_pistol_empty.wav?ex=67a03dea&is=679eec6a&hm=fd711c4551da956ad53952ebf35b81396ee66bf9378f5cbed598837c1345afc7&")
}
local pickupSound = {
	loadSound("https://cdn.discordapp.com/attachments/1335457966924628029/1335458250958831706/pulse_pistol_draw.wav?ex=67a03dea&is=679eec6a&hm=b5d04195ef3c7ff8dd7dcb2c0404e93172370648daaf3e0937ac98dd7f93e3a1&")
}
local chargingSound = {
	loadSound("https://cdn.discordapp.com/attachments/1335457966924628029/1335458250644263002/pulse_pistol_charging.wav?ex=67a03dea&is=679eec6a&hm=153d63110a3ebe5552d2db0f4b9572cdf8e3be8e0eb8e89e1bf19b1c48cb97aa&")
}
local chargedfireSound = {
	loadSound("https://cdn.discordapp.com/attachments/1335457966924628029/1335458250275160095/pulse_pistol_chargedfire.wav?ex=67a03dea&is=679eec6a&hm=fd36ff166ccaa22306653510b3963f4bae27498e5eaed256a774915ab96ed575&")
}
local rackSound = {
	loadSound("https://cdn.discordapp.com/attachments/1335457966924628029/1335458249675374643/pulse_pistol_slide.wav?ex=67a03dea&is=679eec6a&hm=388b46be1282e67d010b610e7cb157047a66ff44f275a2ecda069fdc1d3c6cf1&")
}


local chargedoafter = "IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_INCAPACITATED|IGNORE_SLOWDOWNS"

local spawnPosition = user.mob.loc
local gun = SS13.new("/obj/item/gun/energy")
gun.name = "experimental bluespace pulse pistol"
gun.desc = "An experimental pistol from Nanotrasen's famed R&D armory. Fires bluespace energy pulses from striking a charged bluespace crystal contained inside the pistol. On impact, the pulses cause damage by destabilizing and teleporting mass from the impacted area. Where said mass ends up is unknown. While the energy capacity of crystal inside is low, it can be recharged by racking the slide."
gun.projectile_damage_multiplier = 1.78
gun.can_charge = 0
gun.cell.charge = 5
gun.cell.maxcharge = 5
gun.fire_sound = fireSound[1]
gun.dry_fire_sound = dryfireSound[1]
gun.pickup_sound = pickupSound[1]
for _, lens in gun.ammo_type do
	lens.projectile_type = "/obj/projectile/beam/laser/carbine/cybersun"
	lens.loaded_projectile = SS13.new("/obj/projectile/beam/laser/carbine/cybersun")
	lens.e_cost = 1
end

local chargedshot = SS13.new("/datum/action/item_action")
chargedshot.name = "Charged Shot"
chargedshot.desc = "Begin charging a high-power burst from the weapon. If a shot is already charged, the weapon will disapate its charged shot."
chargedshot.button_icon_state = "origami_on"
local charging_shot = false
local shot_charged = false
local function discharge()
	gun.loc:balloon_alert(gun.loc, "discharging!")
	dm.global_procs.playsound(gun.loc, rackSound[1], 30)
	for _, lens in gun.ammo_type do
		lens.projectile_type = "/obj/projectile/beam/laser/carbine/cybersun"
		lens.loaded_projectile = SS13.new("/obj/projectile/beam/laser/carbine/cybersun")
	end
	gun.cell.charge = 5
	shot_charged = false
end
SS13.register_signal(chargedshot, "action_trigger", function()
	if charging_shot == true then
		gun.loc:balloon_alert(gun.loc, "charging shot...")
		return
	end
	if shot_charged == true then
		discharge()
		return
	end
	local charging_shot = true
	gun.loc:balloon_alert(gun.loc, "charging shot...")
	gun.cell.charge = 0
	dm.global_procs.playsound(gun.loc, chargingSound[1], 50)
	for _, lens in gun.ammo_type do
		lens.projectile_type = nil
		lens.loaded_projectile = nil
	end
	SS13.await(SS13.global_proc, "do_after", gun.loc, 40, gun.loc, chargedoafter)
	shot_charged = true
	charging_shot = false
	for _, lens in gun.ammo_type do
		lens.projectile_type = "/obj/projectile/beam/laser/carbine/cybersun"
		lens.loaded_projectile = SS13.new("/obj/item/ammo_casing/shotgun/scatterlaser")
	end
	gun.cell.charge = 1
end)

SS13.register_signal(gun, "item_pre_attack", function()

end)

local actionsList = {chargedshot}
gun.actions = actionsList
gun.loc = user.mob.loc



SS13.register_signal(gun, "item_attack_self", function()
	if charging_shot == true then
		gun.loc:balloon_alert(gun.loc, "charging shot...")
		return
	end
	if shot_charged == true then
		discharge()
		return
	end
	if gun.cell:charge() <= 0 then
		gun.loc:balloon_alert(gun.loc, "reloading...")
		dm.global_procs.playsound(gun.loc, pickupSound[1], 30)
		if SS13.await(SS13.global_proc, "do_after", gun.loc, 10, gun.loc) == 0 then
			return
		end
		dm.global_procs.playsound(gun.loc, rackSound[1], 50)
		gun.cell.charge = 5
		gun.loc:balloon_alert(gun.loc, "slide racked, reloaded!")
		gun.loc:visible_message("<span class='danger'>"..gun.loc.name.." racks the slide on the "..gun.name.."</span>", "<span class='danger'>You rack the slide of the "..gun.name..", fully reloading it!</span>")
	else
		gun.loc:balloon_alert(gun.loc, ""..tostring(gun.cell:charge()).." shot(s) remaining!")
	end
end)
