const player_health = args[0]
//var player_health = "0x3131313131313131313131313131"

if (player_health.slice(0,1) == "a") {
    player_health = player_health.substring(1)
}
else {
    player_health = player_health.substring(2)
    player_health = Buffer.from(player_health, "hex").toString()
}

var health_by_id = []

for (var i = 0; i < player_health.length; i++) {
    health_by_id.push(parseInt(player_health[i]))
}

const player_actions = args[1].substring(1)
//var player_actions = "01010110001101100101011001101100101000101010001010100010"

var actions_by_id = []

var offset = 0

for (var j = 0; j < health_by_id.length; j++) {
    var action = []
    action.push(parseInt(player_actions[j + offset]))
    action.push(parseInt(player_actions[j + 1 + offset]))
    action.push(parseInt(player_actions[j + 2 + offset]))
    action.push(parseInt(player_actions[j + 3 + offset]))
    actions_by_id.push(action)
    action = []
    offset += 3
}

//Classes: 0 - Knight; 1 - Wizard; 2 - Thief
//Actions: 0 - Idle; 1 - Attack; 2 - Defend; 3 - Recover

//actions_by_id format: 0 - class; 1 - coordX; 2 - coordY; 3 - action
for (var k = 0; k < health_by_id.length; k++) {
    //player is alive
    if (health_by_id[k] != 0) {
        //if player is attacking
        if(actions_by_id[k][3] == 1) {
            //checks each other player
            for (var l = 0; l < health_by_id.length; l++) {
                //can't attack self
                if (actions_by_id[k] != actions_by_id[l]) {
                    //if player shares location with another player
                    if(actions_by_id[k][1] == actions_by_id[l][1]) {
                        if(actions_by_id[k][2] == actions_by_id[l][2]) {
                            
                                //if target is defending
                                if(actions_by_id[l][3] == 2) {
                                    health_by_id[l] -= 1
                                }
                                else {
                                    //damage dealt varies by class matchup
                                    if(actions_by_id[k][0] == actions_by_id[l][0]) {
                                        health_by_id[l] -= 3
                                    }
                                    else {
                                        if(actions_by_id[k][0] = 0) {
                                            if(actions_by_id[l][0] = 1) {
                                                health_by_id[l] -= 2
                                            }
                                            if(actions_by_id[l][0] = 2) {
                                                health_by_id[l] -= 4
                                            }

                                        }
                                        if(actions_by_id[k][0] = 1) {
                                            if(actions_by_id[l][0] = 2) {
                                                health_by_id[l] -= 2
                                            }
                                            if(actions_by_id[l][0] = 0) {
                                                health_by_id[l] -= 4
                                            }

                                        }
                                        if(actions_by_id[k][0] = 2) {
                                            if(actions_by_id[l][0] = 0) {
                                                health_by_id[l] -= 2
                                            }
                                            if(actions_by_id[l][0] = 1) {
                                                health_by_id[l] -= 4
                                            }

                                        }
        


                                    }

                                    }
                                }
                        


                    }

                }

            }


        }
        //if player is recovering
        else if (actions_by_id[k][3] == 3) {
            health_by_id[k] += 1
        }

    }
}


var packed_string = ""

for (var m = 0; m < health_by_id.length; m++) {
    if(health_by_id[m] < 0) {
        health_by_id[m] = 0
    }
    if(health_by_id[m] > 9) {
        health_by_id[m] = 9
    }
    packed_string = packed_string + health_by_id[m]
}

return Functions.encodeString(packed_string)
