/obj/machinery/shieldgen
		name = "Shield generator"
		desc = "Used to seal minor hull breaches."
		icon = 'objects.dmi'
		icon_state = "shieldoff"
		var/active = 0
		var/health = 100
		var/malfunction = 0
		density = 1
		opacity = 0
		anchored = 0
		pressure_resistance = 2*ONE_ATMOSPHERE

/obj/machinery/shieldwallgen
		name = "Shield Generator"
		desc = "A shield generator."
		icon = 'wizard.dmi'
		icon_state = "dontknow"
		anchored = 0
		density = 1
		req_access = list(access_security)
		var/Varedit_start = 0
		var/Varpower = 0
		var/active = 0
		var/power = 1 //fuck that, powered forever for now
		var/state = 0
		var/steps = 0
		var/last_check = 0
		var/check_delay = 10
		var/recalc = 0
		var/locked = 0
		var/destroyed = 0
		flags = FPRINT | CONDUCT

/obj/machinery/shield
		name = "shield"
		desc = "An energy shield."
		icon = 'effects.dmi'
		icon_state = "shieldsparkles"
		density = 1
		opacity = 1
		anchored = 1

/obj/machinery/shieldwall
		name = "Shield"
		desc = "An energy shield."
		icon = 'effects.dmi'
		icon_state = "shieldwall"
		anchored = 1
		density = 1
		var/active = 1
//		var/power = 10
		var/delay = 5
		var/last_active
		var/mob/U
		var/obj/machinery/shieldwallgen/gen_primary
		var/obj/machinery/shieldwallgen/gen_secondary


/obj/machinery/shieldgen/Del()
	for(var/obj/machinery/shield/shield_tile in deployed_shields)
		del(shield_tile)

	..()

/obj/machinery/shieldgen/var/list/obj/machinery/shield/deployed_shields

/obj/machinery/shieldgen/proc
	shields_up()
		if(active) return 0

		for(var/turf/target_tile in range(2, src))
			if (istype(target_tile,/turf/space) && !(locate(/obj/machinery/shield) in target_tile))
				if (malfunction && prob(33) || !malfunction)
					deployed_shields += new /obj/machinery/shield(target_tile)

		src.anchored = 1
		src.active = 1
		src.icon_state = malfunction ? "shieldonbr":"shieldon"

		spawn src.process()

	shields_down()
		if(!active) return 0

		for(var/obj/machinery/shield/shield_tile in deployed_shields)
			del(shield_tile)

		src.anchored = 0
		src.active = 0
		src.icon_state = malfunction ? "shieldoffbr":"shieldoff"

/obj/machinery/shieldgen/process()
	if(active)
		src.icon_state = malfunction ? "shieldonbr":"shieldon"

		if(malfunction)
			while(prob(10))
				del(pick(deployed_shields))

		spawn(30)
			src.process()
	return

/obj/machinery/shieldgen/proc/checkhp()
	if(health <= 30)
		src.malfunction = 1
	if(health <= 10 && prob(75))
		del(src)
	if (active)
		src.icon_state = malfunction ? "shieldonbr":"shieldon"
	else
		src.icon_state = malfunction ? "shieldoffbr":"shieldoff"
	return

/obj/machinery/shieldgen/meteorhit(obj/O as obj)
	src.health -= 25
	if (prob(5))
		src.malfunction = 1
	src.checkhp()
	return

/obj/machinery/shield/meteorhit(obj/O as obj)
	if (prob(75))
		del(src)
	return

/obj/machinery/shieldgen/ex_act(severity)
	switch(severity)
		if(1.0)
			src.health -= 75
			src.checkhp()
		if(2.0)
			src.health -= 30
			if (prob(15))
				src.malfunction = 1
			src.checkhp()
		if(3.0)
			src.health -= 10
			src.checkhp()
	return

/obj/machinery/shield/ex_act(severity)
	switch(severity)
		if(1.0)
			if (prob(75))
				del(src)
		if(2.0)
			if (prob(50))
				del(src)
		if(3.0)
			if (prob(25))
				del(src)
	return

/obj/machinery/shieldgen/attack_hand(mob/user as mob)
	if (src.active)
		for(var/mob/viwer in viewers(world.view, src.loc))
			viwer << text("<font color='blue'>\icon[] [user] deactivated the shield generator.</font>", src)
		shields_down()

	else
		for(var/mob/viwer in viewers(world.view, src.loc))
			viwer << text("<font color='blue'>\icon[] [user] activated the shield generator.</font>", src)
		shields_up()


////FIELD GEN START //shameless copypasta from fieldgen, yes


/* doesn't works for some reason.
/obj/machinery/shieldwallgen/proc/get_connection()
	var/turf/T = src.loc
	if(!istype(T, /turf/simulated/floor))
		return

	for(var/obj/cable/C in T)
		if(C.d1 == 0)
			return C.netnum

	return 0
*/

/obj/machinery/shieldwallgen/attack_hand(mob/user as mob)
	if(state == 1)
		if(!src.locked)
			if(power == 1)
				if(src.active >= 1)
					src.active = 0
		//			icon_state = "Field_Gen"
					user << "You turn off the shield generator."
		//			src.cleanup()
				else
					src.active = 1
		//			icon_state = "Field_Gen +a"
					user << "You turn on the shield generator."
			else
				user << "The shield generator needs to be powered by wire underneath."
		else
			user << "The controls are locked!"
	else
		user << "The shield generator needs to be firmly secured to the floor first."
	src.add_fingerprint(user)

/obj/machinery/shieldwallgen/attack_ai(mob/user as mob)
	if(state == 1)
		if(power == 1)
			if(src.active >= 1)
				user << "You turn off the field generator."
				src.active = 0
			else
				src.active = 1
	//			icon_state = "Field_Gen +a"
				user << "You turn on the field generator."
		else
			user << "The shield generator needs to be powered by wire underneath."
	else
		user << "The shield generator needs to be firmly secured to the floor first."
	src.add_fingerprint(user)

/obj/machinery/shieldwallgen/New()
	..()
	return

/obj/machinery/shieldwallgen/process()

	if(src.Varedit_start == 1)
		if(src.active == 0)
			src.active = 1
			src.state = 1
//			src.power = 1
			src.anchored = 1
//			icon_state = "Field_Gen +a"
		Varedit_start = 0

	if(src.active == 1)
		if(!src.state == 1)
			src.active = 0
			return
		spawn(1)
			setup_field(1)
		spawn(2)
			setup_field(2)
		spawn(3)
			setup_field(4)
		spawn(4)
			setup_field(8)
		src.active = 2
	if(src.active >= 1)
		if(Varpower == 0)
			if(src.power == 0)
				for(var/mob/M in viewers(src))
					M.show_message("\red The [src.name] shuts down due to lack of power!")
	//			icon_state = "Field_Gen"
				src.active = 0
				spawn(1)
					src.cleanup(1)
				spawn(1)
					src.cleanup(2)
				spawn(1)
					src.cleanup(4)
				spawn(1)
					src.cleanup(8)

/obj/machinery/shieldwallgen/proc/setup_field(var/NSEW = 0)
	var/turf/T = src.loc
	var/turf/T2 = src.loc
	var/obj/machinery/shieldwallgen/G
	var/steps = 0
	var/oNSEW = 0

	if(!NSEW)//Make sure its ran right
		return

	if(NSEW == 1)
		oNSEW = 2
	else if(NSEW == 2)
		oNSEW = 1
	else if(NSEW == 4)
		oNSEW = 8
	else if(NSEW == 8)
		oNSEW = 4

	for(var/dist = 0, dist <= 9, dist += 1) // checks out to 8 tiles away for another generator
		T = get_step(T2, NSEW)
		T2 = T
		steps += 1
		if(locate(/obj/machinery/shieldwallgen) in T)
			G = (locate(/obj/machinery/shieldwallgen) in T)
			steps -= 1
			if(!G.active)
				return
			G.cleanup(oNSEW)
			break

	if(isnull(G))
		return

	T2 = src.loc

	for(var/dist = 0, dist < steps, dist += 1) // creates each field tile
		var/field_dir = get_dir(T2,get_step(T2, NSEW))
		T = get_step(T2, NSEW)
		T2 = T
		var/obj/machinery/shieldwall/CF = new/obj/machinery/shieldwall/(src, G) //(ref to this gen, ref to connected gen)
		CF.loc = T
		CF.dir = field_dir


/obj/machinery/shieldwallgen/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/wrench))
		if(active)
			user << "Turn off the field generator first."
			return

		else if(state == 0)
			state = 1
			playsound(src.loc, 'Ratchet.ogg', 75, 1)
			user << "You secure the external reinforcing bolts to the floor."
			src.anchored = 1
			return

		else if(state == 1)
			state = 0
			playsound(src.loc, 'Ratchet.ogg', 75, 1)
			user << "You undo the external reinforcing bolts."
			src.anchored = 0
			return

	if(istype(W, /obj/item/weapon/card/id)||istype(W, /obj/item/device/pda))
		if (src.allowed(user))
			src.locked = !src.locked
			user << "Controls are now [src.locked ? "locked." : "unlocked."]"
		else
			user << "\red Access denied."

	else
		src.add_fingerprint(user)
		user << "\red You hit the [src.name] with your [W.name]!"
		for(var/mob/M in viewers(src))
			if(M == user)	continue
			M.show_message("\red The [src.name] has been hit with the [W.name] by [user.name]!")

/obj/machinery/shieldwallgen/proc/cleanup(var/NSEW)
	var/obj/machinery/shieldwall/F
	var/obj/machinery/shieldwallgen/G
	var/turf/T = src.loc
	var/turf/T2 = src.loc

	for(var/dist = 0, dist <= 9, dist += 1) // checks out to 8 tiles away for fields
		T = get_step(T2, NSEW)
		T2 = T
		if(locate(/obj/machinery/shieldwall) in T)
			F = (locate(/obj/machinery/shieldwall) in T)
			del(F)

		if(locate(/obj/machinery/shieldwallgen) in T)
			G = (locate(/obj/machinery/shieldwallgen) in T)
			if(!G.active)
				break

/obj/machinery/shieldwallgen/Del()
	src.cleanup(1)
	src.cleanup(2)
	src.cleanup(4)
	src.cleanup(8)
	..()




/obj/machinery/shield
	New()
		src.dir = pick(1,2,3,4)

		..()

		update_nearby_tiles(need_rebuild=1)

	Del()
		update_nearby_tiles()

		..()

	CanPass(atom/movable/mover, turf/target, height, air_group)
		if(!height || air_group) return 0
		else return ..()

	proc/update_nearby_tiles(need_rebuild)
		if(!air_master) return 0

		var/turf/simulated/source = loc
		var/turf/simulated/north = get_step(source,NORTH)
		var/turf/simulated/south = get_step(source,SOUTH)
		var/turf/simulated/east = get_step(source,EAST)
		var/turf/simulated/west = get_step(source,WEST)

		if(need_rebuild)
			if(istype(source)) //Rebuild/update nearby group geometry
				if(source.parent)
					air_master.groups_to_rebuild += source.parent
				else
					air_master.tiles_to_update += source
			if(istype(north))
				if(north.parent)
					air_master.groups_to_rebuild += north.parent
				else
					air_master.tiles_to_update += north
			if(istype(south))
				if(south.parent)
					air_master.groups_to_rebuild += south.parent
				else
					air_master.tiles_to_update += south
			if(istype(east))
				if(east.parent)
					air_master.groups_to_rebuild += east.parent
				else
					air_master.tiles_to_update += east
			if(istype(west))
				if(west.parent)
					air_master.groups_to_rebuild += west.parent
				else
					air_master.tiles_to_update += west
		else
			if(istype(source)) air_master.tiles_to_update += source
			if(istype(north)) air_master.tiles_to_update += north
			if(istype(south)) air_master.tiles_to_update += south
			if(istype(east)) air_master.tiles_to_update += east
			if(istype(west)) air_master.tiles_to_update += west

		return 1


//////////////Contaiment Field START


/obj/machinery/shieldwall/New(var/obj/machinery/shieldwallgen/A, var/obj/machinery/shieldwallgen/B)
	..()
	src.gen_primary = A
	src.gen_secondary = B
	spawn(1)
		src.sd_SetLuminosity(5)

/obj/machinery/shieldwall/attack_hand(mob/user as mob)
	return


/obj/machinery/shieldwall/process()
	if(isnull(gen_primary)||isnull(gen_secondary))
		del(src)
		return

	if(!(gen_primary.active)||!(gen_secondary.active))
		del(src)
		return