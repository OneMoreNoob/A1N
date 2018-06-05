debug(3).

// Name of the manager
manager("Manager").

// Team of troop.
team("AXIS").
// Type of troop.
type("CLASS_SOLDIER").

// Value of "closeness" to the Flag, when patrolling in defense
patrollingRadius(64).




{ include("jgomas.asl") }


// Plans


/*******************************
*
* Actions definitions
*
*******************************/

/////////////////////////////////
//  GET AGENT TO AIM
/////////////////////////////////
/**
 * Calculates if there is an enemy at sight.
 *
 * This plan scans the list <tt> m_FOVObjects</tt> (objects in the Field
 * Of View of the agent) looking for an enemy. If an enemy agent is found, a
 * value of aimed("true") is returned. Note that there is no criterion (proximity, etc.) for the
 * enemy found. Otherwise, the return value is aimed("false")
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!get_agent_to_aim
    <-  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
        ?fovObjects(FOVObjects);
        .length(FOVObjects, Length);

        ?debug(Mode); if (Mode<=1) { .println("El numero de objetos es:", Length); }

        if (Length > 0) {
            +bucle(0);

            -+aimed("false");

            while (aimed("false") & bucle(X) & (X < Length)) {

                //.println("En el bucle, y X vale:", X);

                .nth(X, FOVObjects, Object);
                // Object structure
                // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
                .nth(2, Object, Type);

                ?debug(Mode); if (Mode<=2) { .println("Objeto Analizado: ", Object); }

                if (Type > 1000) {
                    ?debug(Mode); if (Mode<=2) { .println("I found some object."); }
                } else {
                    // Object may be an enemy
                    .nth(1, Object, Team);
                    ?my_formattedTeam(MyTeam);

                    if (Team == 100) {  // Only if I'm AXIS

                        ?debug(Mode); if (Mode<=2) { .println("Aiming an enemy. . .", MyTeam, " ", .number(MyTeam) , " ", Team, " ", .number(Team)); }
                        +aimed_agent(Object);
                        -+aimed("true");
			
						//Fuego amigo
                        +ffloop(0);
					while(aimed("true") & ffloop(I) & (I < Length)){

						.nth(I, FOVObjects, ObjectI);
						.nth(2, ObjectI, TypeI);
						.nth(1, ObjectI, TeamI);
					
						if (TypeI<1000 & TeamI==200){
					
							?my_position(XMe, YMe, ZMe);
						
							.nth(6,Object,PosEnemy);
							.nth(6,ObjectI,PosTeammate);
						
							!distance(pos(XMe,YMe,ZMe),PosEnemy);
							?distance(DE);
							!distance(pos(XMe,YMe,ZMe),PosTeammate);
							?distance(DT);
						
							!distance(PosTeammate,PosEnemy);
							?distance(DTtoE);
						
							if(DE+3>=DT+DTtoE){
 								-aimed_agent(Object);
 								-+aimed("false");	
							}
						}
						-+ffloop(I+1);             
 				
					}
					-ffloop(_);
				
                }

            }

                -+bucle(X+1);

        }


    }

    -bucle(_).



/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ///?debug(Mode); if (Mode<=1) { .println("HAY ", Length, " OBJETOS A MI ALREDEDOR:\n", FOVObjects); }
        };
        -look_response(_)[source(M)];
        -+fovObjects(FOVObjects);
        //.//;
        !look.


/////////////////////////////////
//  PERFORM ACTIONS
/////////////////////////////////
/**
 * Action to do when agent has an enemy at sight.
 *
 * This plan is called when agent has looked and has found an enemy,
 * calculating (in agreement to the enemy position) the new direction where
 * is aiming.
 *
 *  It's very useful to overload this plan.
 *
 */

+!perform_aim_action
    <-  // Aimed agents have the following format:
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        ?aimed_agent(AimedAgent);
        ?debug(Mode); if (Mode<=1) { .println("AimedAgent ", AimedAgent); }
        .nth(1, AimedAgent, AimedAgentTeam);
        ?debug(Mode); if (Mode<=2) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam); }
        ?my_formattedTeam(MyTeam);
		.my_name(M);

        if (AimedAgentTeam == 100) {

            .nth(6, AimedAgent, NewDestination);
            ?debug(Mode); if (Mode<=1) { .println("NUEVO DESTINO MARCADO: ", NewDestination); }
            //update_destination(NewDestination);
			!add_task(task(8000, "TASK_ATTACK", M, NewDestination, "INT"));
        }
        .

/**
 * Action to do when the agent is looking at.
 *
 * This plan is called just after Look method has ended.
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!perform_look_action .
/// <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_LOOK_ACTION GOES HERE.") }.

/**
 * Action to do if this agent cannot shoot.
 *
 * This plan is called when the agent try to shoot, but has no ammo. The
 * agent will spit enemies out. :-)
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!perform_no_ammo_action .
/// <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_NO_AMMO_ACTION GOES HERE.") }.

/**
 * Action to do when an agent is being shot.
 *
 * This plan is called every time this agent receives a messager from
 * agent Manager informing it is being shot.
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!perform_injury_action .
///<- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_INJURY_ACTION GOES HERE.") }.


/////////////////////////////////
//  SETUP PRIORITIES
/////////////////////////////////
/**  You can change initial priorities if you want to change the behaviour of each agent  **/
+!setup_priorities
    <-  +task_priority("TASK_NONE",0);
        +task_priority("TASK_GIVE_MEDICPAKS", 2000);
        +task_priority("TASK_GIVE_AMMOPAKS", 0);
        +task_priority("TASK_GIVE_BACKUP", 0);
        +task_priority("TASK_GET_OBJECTIVE",1000);
        +task_priority("TASK_ATTACK", 1000);
        +task_priority("TASK_RUN_AWAY", 1500);
        +task_priority("TASK_GOTO_POSITION", 750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 750).



/////////////////////////////////
//  UPDATE TARGETS
/////////////////////////////////
/**
 * Action to do when an agent is thinking about what to do.
 *
 * This plan is called at the beginning of the state "standing"
 * The user can add or eliminate targets adding or removing tasks or changing priorities
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!update_targets
	<- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR update_targets GOES HERE.")};
        .my_name(ME);
        ?mi_pos(X, Y, Z);
        !safe_pos(X, Y, Z);
        ?safe_pos(X1, Y1, Z1);
        ?estoyformado(B);
		?objective(ObjectiveX,ObjectiveY,ObjectiveZ);
		?initialflag(A,_,C);
		if((A \== ObjectiveX) & (C \== ObjectiveZ)){
			 -+tasks([]);
			 -+lugar(20);
			 .println("a ver; ", X, Z);
			 !add_task(task(8000, "TASK_ATTACK", ME, pos(X, Y, Z), "INT"));
		}
        if((B == true) & lugar(0)) {
            !add_task(task(3000, "TASK_GOTO_POSITION1", ME, pos(X1, Y1, Z1+1), "INT"));
            -+lugar(1);
        }
            else{
                if((B == true) & lugar(1)){
                    !add_task(task(3000, "TASK_GOTO_POSITION2", ME, pos(X1, Y1, Z1-1), "INT"));
                    -+lugar(0);
            }
        }.
/////////////////////////////////
//  CHECK MEDIC ACTION (ONLY MEDICS)
/////////////////////////////////
/**
 * Action to do when a medic agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!checkMedicAction
<-  -+medicAction(on).
// go to help



/////////////////////////////////
//  CHECK FIELDOPS ACTION (ONLY FIELDOPS)
/////////////////////////////////
/**
 * Action to do when a fieldops agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!checkAmmoAction
<-  -+fieldopsAction(on).
//  go to help



/////////////////////////////////
//  PERFORM_TRESHOLD_ACTION
/////////////////////////////////
/**
 * Action to do when an agent has a problem with its ammo or health.
 *
 * By default always calls for help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!performThresholdAction
       <-

       ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_TRESHOLD_ACTION GOES HERE.") }

       ?my_ammo_threshold(At);
       ?my_ammo(Ar);

       if (Ar <= At) {
          ?my_position(X, Y, Z);

         .my_team("fieldops_AXIS", E1);
         //.println("Mi equipo intendencia: ", E1 );
         .concat("cfa(",X, ", ", Y, ", ", Z, ", ", Ar, ")", Content1);
         .send_msg_with_conversation_id(E1, tell, Content1, "CFA");


       }

       ?my_health_threshold(Ht);
       ?my_health(Hr);

       if (Hr <= Ht) {
          ?my_position(X, Y, Z);

         .my_team("medic_AXIS", E2);
         //.println("Mi equipo medico: ", E2 );
         .concat("cfm(",X, ", ", Y, ", ", Z, ", ", Hr, ")", Content2);
         .send_msg_with_conversation_id(E2, tell, Content2, "CFM");

       }
       .

/////////////////////////////////
//  ANSWER_ACTION_CFM_OR_CFA
/////////////////////////////////



+cfm_agree[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfm_agree GOES HERE.")};
      -cfm_agree.

+cfa_agree[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfa_agree GOES HERE.")};
      -cfa_agree.

+cfm_refuse[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfm_refuse GOES HERE.")};
      -cfm_refuse.

+cfa_refuse[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfa_refuse GOES HERE.")};
      -cfa_refuse.

/////////////////////////////////
//  EXTRA
/////////////////////////////////

+formado(F)[source(A)]
<-
    .println("Mensaje recibido de agente listo ", A);
    ?numformados(N);
    -+numformados(N+1);
    -formado(_).

+!formar1(Medico,Fieldop,Soldier)
<-
    ?objective(ObjectiveX,ObjectiveY,ObjectiveZ);
    .my_team(Fieldop,Fieldops);
    .my_team(Medico,Medicos);
    .my_team(Soldier,Soldiers);

    .nth(0,Medicos,Medic1);
    .nth(1,Medicos,Medic2);

    .concat("formar1(",ObjectiveX-6-5,",",ObjectiveY,",",ObjectiveZ-6,",",1,")",PosMedico1);
    .concat("formar1(",ObjectiveX-6,",",ObjectiveY,",",ObjectiveZ-6-5,",",2,")",PosMedico2);
    .send_msg_with_conversation_id(Medic1,tell,PosMedico1,"INT");
    .send_msg_with_conversation_id(Medic2,tell,PosMedico2,"INT");

    .nth(0,Fieldops,Ops1);
    .nth(1,Fieldops,Ops2);

    .concat("formar1(",ObjectiveX-6-7,",",ObjectiveY,",",ObjectiveZ-6,",",1,")",PosOps1);
    .concat("formar1(",ObjectiveX-6,",",ObjectiveY,",",ObjectiveZ-6-7,",",2,")",PosOps2);
    .send_msg_with_conversation_id(Ops1,tell,PosOps1,"INT");
    .send_msg_with_conversation_id(Ops2,tell,PosOps2,"INT");
    
    .nth(0,Soldiers,Sold1);
    .nth(1,Soldiers,Sold2);
    .nth(2,Soldiers,Sold3);
    
    .concat("formar1(",ObjectiveX-6-9,",",ObjectiveY,",",ObjectiveZ-6,",",1,")",PosSold1);
    .concat("formar1(",ObjectiveX-6-3,",",ObjectiveY,",",ObjectiveZ-6,",",2,")",PosSold2);
    .concat("formar1(",ObjectiveX-6,",",ObjectiveY,",",ObjectiveZ-6-3,",",2,")",PosSold3);
    .send_msg_with_conversation_id(Sold1,tell,PosSold1,"INT");
    .send_msg_with_conversation_id(Sold2,tell,PosSold2,"INT");
    .send_msg_with_conversation_id(Sold3,tell,PosSold3,"INT");

    .println("Enviados Mensajes de formacion.");

    .my_name(ME);
    !safe_pos(ObjectiveX-6-9,ObjectiveY,ObjectiveZ-6);
    ?safe_pos(X1,Y1,Z1);
    +mi_pos(X1, Y1, Z1);
    !add_task(task(5000,"TASK_GOTO_POSITION",ME,pos(X1,Y1,Z1),"INT"));
    -+estoyformado(true);
    .

/////////////////////////////////
//  Initialize variables
/////////////////////////////////

+!init
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR init GOES HERE.")};
   .register("JGOMAS","capitan_AXIS");
   .wait(2000);
   -+tasks([]);
   +numformados(0);
   +boolformado(false);
   +estoyformado(false);
   ?objective(ObjectiveX,ObjectiveY,ObjectiveZ);
   +initialflag(ObjectiveX,ObjectiveY,ObjectiveZ);
   +plan(0);
   +lugar(0);
   !formar1("medic_AXIS","fieldops_AXIS","backup_AXIS").

