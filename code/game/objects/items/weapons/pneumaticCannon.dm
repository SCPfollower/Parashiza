///Defines for the pressure strength of the cannon
#define LOW_PRESSURE 1
#define MID_PRESSURE 2
#define HIGH_PRESSURE 3

/obj/item/pneumatic_cannon
	name = "pneumatic cannon"
	desc = "Пушка, способная стрелять различным хламом, загруженным в неё."
	w_class = WEIGHT_CLASS_BULKY
	force = 8 //Very heavy
	attack_verb = list("ударил", "огрел")
	icon = 'icons/obj/weapons/pneumaticCannon.dmi'
	icon_state = "pneumaticCannon"
	item_state = "bulldog"
	lefthand_file = 'icons/mob/inhands/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/guns_righthand.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 60, ACID = 50)
	var/maxWeightClass = 20 //The max weight of items that can fit into the cannon
	var/loadedWeightClass = 0 //The weight of items currently in the cannon
	var/obj/item/tank/internals/tank = null //The gas tank that is drawn from to fire things
	var/gasPerThrow = 3 //How much gas is drawn from a tank's pressure to fire
	var/list/loadedItems = list() //The items loaded into the cannon that will be fired out
	var/pressure_setting = LOW_PRESSURE //How powerful the cannon is - higher pressure = more gas but more powerful throws
	var/has_wad = FALSE //Need use cartboard as wad before loading

/obj/item/pneumatic_cannon/get_ru_names()
	return list(
		NOMINATIVE = "пневматическая пушка",
		GENITIVE = "пневматической пушки",
		DATIVE = "пневматической пушке",
		ACCUSATIVE = "пневматическую пушку",
		INSTRUMENTAL = "пневматической пушкой",
		PREPOSITIONAL = "пневматической пушке",
	)

/obj/item/pneumatic_cannon/Destroy()
	QDEL_NULL(tank)
	QDEL_LIST(loadedItems)
	return ..()

/obj/item/pneumatic_cannon/proc/pressure_setting_to_text(pressure_setting)
	switch(pressure_setting)
		if(LOW_PRESSURE)
			return "слабая"
		if(MID_PRESSURE)
			return "средняя"
		if(HIGH_PRESSURE)
			return "большая"
		else
			CRASH("Invalid pressure setting: [pressure_setting]!")

/obj/item/pneumatic_cannon/examine(mob/user)
	. = ..()
	if(!in_range(user, src))
		. += span_notice("Вы не можете разглядеть, что находится внутри.")
	else
		. += span_notice("Используйте <b>гаечный ключ</b> для изменения силы выстрела.\nТекущая сила выстрела — <b>[pressure_setting_to_text(pressure_setting)]</b>.")
		if(tank)
			. += span_notice("[icon2html(tank, user)] К ней прикреплен [tank.declent_ru(NOMINATIVE)]. [DECLENT_RU_CAP(tank, NOMINATIVE)] можно убрать <b>отверткой</b>.")
		for(var/obj/item/I in loadedItems)
			. += span_notice("[icon2html(I, user)] Она содержит [I.declent_ru(ACCUSATIVE)] внутри.")

/obj/item/pneumatic_cannon/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!tank)
		to_chat(user, span_warning("Баллон не установлен."))
		return .
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	to_chat(user, span_notice("Вы открепили [tank.declent_ru(ACCUSATIVE)] от [src.declent_ru(GENITIVE)]."))
	tank.forceMove(drop_location())
	user.put_in_hands(tank, ignore_anim = FALSE)
	tank = null
	update_icon(UPDATE_OVERLAYS)

/obj/item/pneumatic_cannon/wrench_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	pressure_setting = pressure_setting >= HIGH_PRESSURE ? LOW_PRESSURE : pressure_setting + 1
	to_chat(user, span_notice("Вы поменяли силу выстрела. Теперь она [pressure_setting_to_text(pressure_setting)]."))

/obj/item/pneumatic_cannon/return_analyzable_air()
	if(tank)
		return tank.return_analyzable_air()

/obj/item/pneumatic_cannon/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(istype(I, /obj/item/tank/internals))
		add_fingerprint(user)
		if(tank)
			to_chat(user, span_warning("[DECLENT_RU_CAP(tank, NOMINATIVE)] уже установлен."))
			return ATTACK_CHAIN_PROCEED
		if(istype(I, /obj/item/tank/internals/emergency_oxygen))
			to_chat(user, span_warning("[DECLENT_RU_CAP(I, NOMINATIVE)] слишком мал для [src.declent_ru(GENITIVE)]."))
			return ATTACK_CHAIN_PROCEED
		if(!user.drop_transfer_item_to_loc(I, src))
			return ..()
		to_chat(user, span_notice("Вы прикрепили [I.declent_ru(ACCUSATIVE)] к [src.declent_ru(PREPOSITIONAL)]."))
		tank = I
		update_icon(UPDATE_OVERLAYS)
		return ATTACK_CHAIN_BLOCKED_ALL

	if(I.type == type)
		to_chat(user, span_warning("Вы точно уверены, что это не сработает."))
		return ATTACK_CHAIN_PROCEED

	if(loadedWeightClass >= maxWeightClass)
		to_chat(user, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] не вместит больше предметов!"))
		return ATTACK_CHAIN_PROCEED

	if((loadedWeightClass + I.w_class) > maxWeightClass)
		to_chat(user, span_warning("[DECLENT_RU_CAP(I, NOMINATIVE)] не вместиться в [src.declent_ru(ACCUSATIVE)]!"))
		return ATTACK_CHAIN_PROCEED

	if(I.w_class > w_class)
		to_chat(user, span_warning("[DECLENT_RU_CAP(I, NOMINATIVE)] не влезет в [src.declent_ru(ACCUSATIVE)]!"))
		return ATTACK_CHAIN_PROCEED

	if(istype(I, /obj/item/stack/sheet/cardboard) && !has_wad)
		var/obj/item/stack/sheet/cardboard/cardboard = I
		if(cardboard.amount > 1)
			to_chat(user, span_warning("Нужен лишь один кусок картона!"))
			return ATTACK_CHAIN_PROCEED
		add_fingerprint(user)
		has_wad = TRUE
		to_chat(user, span_notice("Вы загрузили пыж в [src]!"))
		qdel(I)
		return ATTACK_CHAIN_BLOCKED_ALL

	if(!has_wad)
		to_chat(user, span_warning("Нужно вставить пыж из картона!"))
		return ATTACK_CHAIN_PROCEED

	if(!user.drop_transfer_item_to_loc(I, src))
		return ..()

	to_chat(user, span_notice("Вы загрузили [I.declent_ru(ACCUSATIVE)] в [src.declent_ru(ACCUSATIVE)]."))
	loadedItems += I
	loadedWeightClass += I.w_class
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/item/pneumatic_cannon/afterattack(atom/target, mob/living/carbon/human/user, flag, params)
	. = ..()
	if(flag && user.a_intent == INTENT_HARM) // Melee attack
		return .
	if(!istype(user))
		return .
	if(loc != user)
		return .
	if(istype(target, /obj/item/storage/backpack) && in_range(target, src))
		return .
	Fire(user, target)

/obj/item/pneumatic_cannon/proc/Fire(mob/living/carbon/human/user, atom/target)
	if(!istype(user) && !target)
		return
	var/discharge = 0
	if(!loadedItems || !loadedWeightClass)
		to_chat(user, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] пуста."))
		return
	if(!tank)
		to_chat(user, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] не может стрелять без установленного баллона."))
		return
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("Вы не можете заставить себя выстрелить из [src.declent_ru(GENITIVE)]! Выстрел из нее слишком опасен..."))
		return
	if(tank && !tank.air_contents.remove(gasPerThrow * pressure_setting))
		to_chat(user, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] выпускает лишь слабый ветерок!"))
		return
	if(user && HAS_TRAIT(user, TRAIT_CLUMSY) && prob(75))
		user.visible_message(span_warning("[user.declent_ru(NOMINATIVE)] теряет хват и роняет [src.declent_ru(ACCUSATIVE)]!"), span_userdanger("[DECLENT_RU_CAP(src, NOMINATIVE)] выскальзывает из ваших рук!"))
		user.drop_from_active_hand()
		if(prob(10))
			target = get_turf(user)
		else
			var/list/possible_targets = range(3,src)
			target = pick(possible_targets)
		discharge = 1
	if(!discharge)
		user.visible_message(span_danger("[user.declent_ru(NOMINATIVE)] стрелят из [src.declent_ru(GENITIVE)]!"), span_danger("Вы стреляете из [src.declent_ru(GENITIVE)]!"), projectile_message = TRUE)
	add_attack_logs(user, target, "Fired [src]")
	playsound(loc, 'sound/weapons/sonic_jackhammer.ogg', 50, TRUE)
	has_wad = FALSE
	for(var/obj/item/ITD in loadedItems) //Item To Discharge
		spawn(0)
			src.launch_item(ITD, target, user)

	if(pressure_setting >= HIGH_PRESSURE && user)
		user.visible_message(span_warning("[user.declent_ru(NOMINATIVE)] падает на пол от отдачи!"), span_userdanger("[src.declent_ru(GENITIVE)] роняет вас силой отдачи!"))
		user.Weaken(6 SECONDS)

/obj/item/pneumatic_cannon/proc/launch_item(obj/item/item, atom/target, mob/user)
	if(QDELETED(item) || !item)
		return

	loadedItems.Remove(item)
	loadedWeightClass -= item.w_class
	item.throw_speed = pressure_setting * 2
	item.forceMove(get_turf(src))

	var/datum/thrownthing/TT = item.throw_at(target, (pressure_setting * 5), (pressure_setting * 2), user)

	if(TT && item.GetComponent(/datum/component/eatable) && user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		RegisterSignal(item, COMSIG_MOVABLE_IMPACT, /obj/item/pneumatic_cannon/proc/cannon_food_impact)

/obj/item/pneumatic_cannon/proc/cannon_food_impact(obj/item/source, atom/target)
	UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)

	if(!ishuman(target))
		return

	var/mob/living/carbon/human/human = target

	if(human.is_mouth_covered() || !human.check_has_mouth())
		return

	var/datum/component/eatable/eatable = source.GetComponent(/datum/component/eatable)
	if(!eatable)
		return

	if(human.nutrition >= NUTRITION_LEVEL_FULL)
		return

	human.visible_message(
		span_notice("[source] залетает прямо в рот [human]!"),
		span_notice("[source] залетает вам прямо в рот!")
	)

	eatable.eat(human, human)

/obj/item/pneumatic_cannon/attack_self(mob/user)
	if(!loadedItems.len)
		to_chat(user, span_warning("Нечего высыпать!"))
		return

	to_chat(user, span_notice("Вы высыпали содержимое [src.declent_ru(GENITIVE)] на пол."))
	for(var/obj/item/item in loadedItems)
		spawn(0)
			loadedItems.Remove(item)
			loadedWeightClass -= item.w_class
			item.loc = get_turf(src)

/obj/item/pneumatic_cannon/ghetto //Obtainable by improvised methods; more gas per use, less capacity, but smaller
	name = "improvised pneumatic cannon"
	desc = "Пушка, способная стрелять различным хламом, загруженным в неё. На вид тоже хлам."
	force = 5
	w_class = WEIGHT_CLASS_BULKY
	maxWeightClass = 7
	gasPerThrow = 5

/obj/item/pneumatic_cannon/ghetto/get_ru_names()
	return list(
		NOMINATIVE = "самодельная пневматическая пушка",
		GENITIVE = "самодельной пневматической пушки",
		DATIVE = "самодельной пневматической пушке",
		ACCUSATIVE = "самодельную пневматическую пушку",
		INSTRUMENTAL = "самодельной пневматической пушкой",
		PREPOSITIONAL = "самодельной пневматической пушке",
	)

/datum/crafting_recipe/improvised_pneumatic_cannon //Pretty easy to obtain but
	name = "Pneumatic Cannon"
	result = /obj/item/pneumatic_cannon/ghetto
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	reqs = list(
		/obj/item/stack/sheet/metal = 4,
		/obj/item/stack/packageWrap = 8,
		/obj/item/pipe = 2,
	)
	time = 300
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/obj/item/pneumatic_cannon/update_overlays()
	. = ..()
	if(tank)
		. += "[tank.icon_state]"

#undef LOW_PRESSURE
#undef MID_PRESSURE
#undef HIGH_PRESSURE
