/obj/mecha/combat/marauder
	desc = "Heavy duty combat exosuit."
	name = "Marauder"
	icon_state = "marauder"
	step_in = 10
	health = 500
	deflect_chance = 25
	max_temperature = 5000
	var/thrusters = 0
	var/smoke = 5
	var/smoke_ready = 1
	var/smoke_cooldown = 100
	var/datum/effects/system/harmless_smoke_spread/smoke_system = new


/obj/mecha/combat/marauder/New()
	..()
	weapon_1 = new /datum/mecha_weapon/pulse(src)
	weapon_2 = new /datum/mecha_weapon/missile_rack(src)
	selected_weapon = weapon_1
	src.smoke_system.set_up(3, 0, src)
	src.smoke_system.attach(src)
	return

/obj/mecha/combat/marauder/relaymove(mob/user,direction)
	if(!can_move)
		return 0
	if(connected_port)
		src.occupant << "Unable to move while connected to the air system port"
		return 0
	if(!thrusters && src.inertia_dir)
		return 0
	if(state || !cell || cell.charge<=0)
		return 0
	var/tmp_step_in = step_in
	var/tmp_step_energy_drain = step_energy_drain
	if(step(src,direction))
		if(istype(src.loc, /turf/space))
			if(!src.check_for_support())
				src.inertia_dir = direction
				src.inertial_movement()
				if(thrusters)
					tmp_step_energy_drain = step_energy_drain*2

		can_move = 0
		spawn(tmp_step_in) can_move = 1
		cell.use(tmp_step_energy_drain)
		return 1
	return 0


/obj/mecha/combat/marauder/verb/toggle_thrusters()
	set category = "Exosuit Interface"
	set name = "Toggle thrusters"
	set src in view(0)
	if(usr!=src.occupant)
		return
	if(src.occupant)
		if(cell.charge > 0)
			thrusters = !thrusters
			src.occupant << "\blue Thrusters [thrusters?"en":"dis"]abled."
	return

/obj/mecha/combat/marauder/verb/smoke()
	set category = "Exosuit Interface"
	set name = "Smoke"
	set src in view(0)
	if(usr!=src.occupant)
		return
	if(smoke_ready && smoke>0)
		src.smoke_system.start()
		smoke--
		smoke_ready = 0
		spawn(smoke_cooldown)
			smoke_ready = 1
	return

/obj/mecha/combat/marauder/get_stats_part()
	var/output = ..()
	output += {"<b>Weapon systems:</b>
					<div style="margin-left: 15px;">
					[selected_weapon==weapon_1?"<b>":""][weapon_1.name][selected_weapon==weapon_1?"</b>":""]
					</div>
					<div style="margin-left: 15px;">
					[selected_weapon==weapon_2?"<b>":""][weapon_2.name] ([weapon_2:missiles])[selected_weapon==weapon_2?"</b>":""]
					</div>
					<b>Smoke:</b> [smoke]
					<br>
					<b>Thrusters:</b> [thrusters?"on":"off"]
				"}
	return output


/obj/mecha/combat/marauder/get_commands()
	var/output = ..()
	var/datum/mecha_weapon/missile_rack/MR = weapon_2
	output += {"<a href='?src=\ref[src];toggle_thrusters=1'>Toggle thrusters</a><br>
					<a href='?src=\ref[src];smoke=1'>Smoke</a><br>
					[(MR.missiles < initial(MR.missiles))?"<a href='?src=\ref[src];rearm_srm=1'>Rearm missile rack</a><br>":null]
					"}
	return output

/obj/mecha/combat/marauder/Topic(href, href_list)
	..()
	if (href_list["toggle_thrusters"])
		src.toggle_thrusters()
		return
	if (href_list["smoke"])
		src.smoke()
		return
	if (href_list["rearm_srm"])
		var/datum/mecha_weapon/missile_rack/MR = weapon_2
		MR.rearm()
	return