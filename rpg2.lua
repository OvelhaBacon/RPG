function copytable(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = copytable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function print_table(table)
    for i, v in pairs(table) do
        print(tostring(i) .. " = " .. tostring(v))
    end
end

function apply_type(value, type, number)
    if (type == "*") then
        return value * number
    elseif (type == "/") then
        return value / number
    elseif (type == "+") then
        return value + number
    elseif (type == "=") then
        return number
    elseif (type == "-") then
        return value - number
    end
end


function create_buff(target, type, amount, rounds_to_start, rounds)
    return {
        target = target,
        type = type,
        amount = amount,
        rounds_to_start = rounds_to_start,
        rounds = rounds_to_start+rounds,
    }
end

local classes = {
    ["guerreiro"] = {
        name = "Guerreiro",
        vida = 100,
        esquiva = 50,
        defesa = 20,
        ataques = {
            [1] = {
                name = "espadada",
                efeito = "da uma espadada",
                initial_cooldown = 0,
                cooldown = 0,
                damage = 50,
                garantido = false,
                velocidade = 50,
            },
            [2] = {
                name = "espadada forte",
                efeito = "da uma espadada forte",
                initial_cooldown = 0,
                cooldown = 2,
                damage = 100,
                garantido = false,
                velocidade = 25,
            },
            [3] = {
                name = "furia",
                efeito = "duplica o dano por 2 rodadas",
                initial_cooldown = 0,
                cooldown = 2,
                velocidade = 25,
                buff = create_buff("damage", "*", 2, 0, 2)
            },
        }
    },
    ["mago"] = {
        name = "mago",
        vida = 100,
        esquiva = 50,
        defesa = 20,
        ataques = {
            [1] = {
                name = "majada",
                efeito = "da uma espadada",
                initial_cooldown = 0,
                cooldown = 0,
                damage = 50,
                garantido = false,
                velocidade = 50,
            },
            [2] = {
                name = "majada forte",
                efeito = "da uma espadada forte",
                initial_cooldown = 0,
                cooldown = 2,
                damage = 100,
                garantido = false,
                velocidade = 25,
            },
            [3] = {
                name = "manada",
                efeito = "duplica o dano por 2 rodadas",
                initial_cooldown = 0,
                cooldown = 2,
                damage = 100,
                garantido = false,
                velocidade = 25,
            },
        }
    }
}

local battle_info = {
    players = {
        [1] = {
            cooldowns = {0,0,0},
            buffs = {},
        },
        [2] = {
            cooldowns = {0,0,0},
            buffs = {},
        }
    },
    turn = 0,
}

function get_classe(player)
    while true do
        print("Jogador " .. player .. " escolha uma classe (Guerreiro, Mago)")
        local escolhida = string.lower(io.read())
        if classes[escolhida] then
            print("Jogador " .. player .. " escolheu a classe " .. classes[escolhida].name)
            return escolhida
        end
    end
end

function apply_buff(player, buff)
    buff.rounds = buff.rounds - 1
    buff.rounds_to_start = buff.rounds_to_start - 1
    if buff.rounds_to_start > 0 then return end
    if buff.target == "velocidade" then
        player.info[1].velocidade = apply_type(player.info[1].velocidade,buff.type,buff.number)
        player.info[2].velocidade = apply_type(player.info[1].velocidade,buff.type,buff.number)
        player.info[3].velocidade = apply_type(player.info[2].velocidade,buff.type,buff.number)
    end
    if buff.target == "vida" then
        player.info.vida = apply_type(player.info.vida,buff.type,buff.number)
    end
    if buff.target == "defesa" then
        player.info.defesa = apply_type(player.info.defesa,buff.type,buff.number)
    end
    if buff.target == "esquiva" then
        player.info.esquiva = apply_type(player.info.esquiva,buff.type,buff.number)
    end
    if buff.target == "damage" then
        player.info.ataques[1].damage = apply_type(player.info.ataques[1].damage,buff.type,buff.amount)
        player.info.ataques[2].damage = apply_type(player.info.ataques[1].damage,buff.type,buff.amount)
        player.info.ataques[3].damage = apply_type(player.info.ataques[2].damage,buff.type,buff.amount)
    end

end

function apply_buffs(player)
    for i, v in pairs(player.buffs) do
        apply_buff(player, v)
    end
end


function load_players(class, index)
    local class_info = copytable(classes[class])
    battle_info.players[index].info = class_info
    battle_info.players[index].info.index = index
    battle_info.players[index].info.class_name = class

    battle_info.players[index].cooldowns[1] = class_info.ataques[1].initial_cooldown
    battle_info.players[index].cooldowns[2] = class_info.ataques[2].initial_cooldown
    battle_info.players[index].cooldowns[3] = class_info.ataques[3].initial_cooldown
end

function attack_orden(atk1, atk2)
    return atk1.velocidade > atk2.velocidade and {1,2} or {2,1}
end

function get_attack(player)
    local info = player.info
    while true do
        print("Player " .. info.index .. " Escolha um ataque\n1 = " .. info.ataques[1].name .. "\n2 = " .. info.ataques[2].name .. "\n3 = " .. info.ataques[3].name)
        local escolhida = tonumber(io.read())
        if escolhida then
            local atk = info.ataques[escolhida]
            if atk then
                if battle_info.players[info.index].cooldowns[escolhida] <= 0 then
                    battle_info.players[info.index].cooldowns[escolhida] = info.ataques[escolhida].cooldown
                    return info.ataques[escolhida]
                else
                    print("ataque em cooldown")
                end
            end
        end
    end
end

function enemy(n)
    return n == 2 and 1 or 2
end

function exec_attack(player, attack)
    local index = player.info.index
    local enemy_index = enemy(player.info.index)
    local player = battle_info.players[index]
    local enemy = battle_info.players[enemy_index]

    if battle_info.players[player.info.index].info.vida <= 0 then
        return
    end

    print("Player " .. index .. " utilizou " .. attack.name .. "\n")

    if attack.buff then
        table.insert(player.buffs, attack.buff)
    end
    if attack.damage then
        enemy.info.vida = enemy.info.vida - attack.damage
        print("Player " .. enemy_index .. " sofreu " .. attack.damage .. " de dano. (hp_left: " .. enemy.info.vida .. ")\n")
    end
    if attack.cura then
        print("Player " .. index .. " se curou em " .. attack.cura .. " de vida\n")
        player.info.vida = player.info.vida + attack.cura
    end
end

function print_status()
    local player1 = battle_info.players[1].info
    local player2 = battle_info.players[2].info

    print("------------Player1------------")
    print("VIda:" .. player1.vida)
    print("-------------------------------\n")

    print("------------Player2------------")
    print("VIda:" .. player2.vida)
    print("-------------------------------\n")
end


function game()
    load_players(get_classe(1), 1)
    load_players(get_classe(2), 2)



    while battle_info.players[1].info.vida > 0 and battle_info.players[2].info.vida > 0 do
        local temp_info = copytable(battle_info)
        local player1 = temp_info.players[1]
        local player2 = temp_info.players[2]


        apply_buffs(player1)
        apply_buffs(player2)

        local player1atk = get_attack(player1)
        local player2atk = get_attack(player2)
        local pre_attacks = {player1atk, player2atk}

        local attacks = attack_orden(player1atk, player2atk)


        for i, v in pairs(attacks) do
            exec_attack(temp_info.players[v], pre_attacks[v])
        end

        
        print_status()


        if battle_info.players[1].info.vida <= 0 then
            print("Jogador " .. 1 .. " Morreu :D\nJogador " .. 2 .. " Venceu!!!")
            break
        elseif battle_info.players[2].info.vida <= 0 then
            print("Jogador " .. 2 .. " Morreu :D\nJogador " .. 1 .. " Venceu!!!")
            break
        end

    end
    



end

game()