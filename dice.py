# -*- coding: UTF-8 -*-

from typing import Tuple
from termcolor import colored
import random

Dices = {
    "default": [('F', 1), ('W', 1), ('S', 1), ('F', 3), ('N', 3), ('T', 5)]
}

ElementName = {
    'F': "　　火",
    'W': "　　水",
    'S': "　攻击",
    'N': "　自然",
    'T': "　　雷"
}

player_dice_definitions = [
    "default",
    "default",
    "default",
    "default",
    "default",
    "default",
    "default",
    "default",
    "default",
]

patterns = [
    {
        "levels": [
            "SSS",
            "SSSS",
            "SSSSS",
            "SSSSSS"
        ],
        "base": 40,
        "max": 140,
        "pow": 0.5
    },
    {
        "levels": [
            "FFF",
            "FFFF",
            "FFFFF",
            "FFFFFF"
        ],
        "base": 20,
        "max": 200,
        "pow": 1.0
    },
    {
        "levels": [
            "WWW",
            "WWWW",
            "WWWWW",
            "WWWWWW"
        ],
        "base": 20,
        "max": 200,
        "pow": 2.0
    },
    {
        "levels": [
            "TTT",
            "TTTT",
            "TTTTT",
            "TTTTTT"
        ],
        "base": 10,
        "max": 400,
        "pow": 2.5
    },
    {
        "levels": [
            "NNN",
            "NNNN",
            "NNNNN",
            "NNNNNN"
        ],
        "base": 50,
        "max": 160,
        "pow": 1.2
    },
]

initial_rerolls = 3
reroll_recovery = 2

def get_power(level, level_max, power_base, power_max, power_pow):
    assert power_pow > 0
    return (power_max - power_base) * ((level - 1) / (level_max - 1)) ** power_pow + power_base

def roll(dice):
    assert len(dice) == 6
    return dice[random.randint(0, 5)]

def show_dices(dices, color = "green"):
    
    result = ""

    for idx in range(1, len(dices) + 1):
        result += "　　#%1d\t" % idx
    
    result += "\n"

    for elem in [d[0] for d in dices]:
        result += "%s\t" % ElementName[elem]
    
    result += "\n"

    for numb in [d[1] for d in dices]:
        result += "　　 %1d\t" % numb

    return result

Power = int
MatchedPattern = str

def match_pattern(dices, pattern) -> Tuple[Power, MatchedPattern]:

    dice_occurrences = {x : ''.join([dice[0] for dice in dices]).count(x) for x in ElementName.keys()}
    
    for level, pattern_str in reversed(list(enumerate(pattern["levels"]))):
    
        pattern_occurrences = {x : pattern_str.count(x) for x in ElementName.keys()}
    
        if all([pattern_occurrences[x] <= dice_occurrences[x] for x in ElementName.keys()]):
            return get_power(level + 1, len(pattern["levels"]), pattern["base"], pattern["max"], pattern["pow"]), pattern_str
    
    return 0, None

def match_all_patterns(dices) -> Tuple[Power, MatchedPattern]:

    result = ""
    total_power = 0

    for pattern in patterns:
        power, pattern_str = match_pattern(dices, pattern)
        if pattern_str is not None:
            result += "%10s | %d\n" % (pattern_str, power)
            total_power += power
        
    return total_power, result

def turn_query_action(rerolls):
    print(colored("选择行动：", "cyan"))
    print("- 重新投掷（剩余 %s）：输入想要投掷的骰子ID，以逗号分隔；如 '%s'。" % (colored(rerolls, 'red'), ','.join([str(x+1) for x in random.sample(list(range(len(player_dice_definitions))), random.randint(2,5))]))) # still sane tho
    print("- 攻击！输入'a'")
    return input()

def main():

    player_dices = [Dices[dice_key] for dice_key in player_dice_definitions]

    total_dmg = 0
    max_dmg = 0
    turns = 0

    rerolls = initial_rerolls - reroll_recovery

    # Main loop
    while True:

        turns += 1
        rerolls += reroll_recovery

        print(colored(">>====回合 %d=====================================================================================================" % turns, 'magenta'))

        # Roll the dices
        rolled_dices = [roll(d) for d in player_dices]

        while True:

            # Print roll result
            print(colored(show_dices(rolled_dices), 'green'))
            
            turn_dmg, result_patterns = match_all_patterns(rolled_dices)
            print(colored(result_patterns, 'yellow'), end = '')
            print(colored("%8s | %d" % ("总计", turn_dmg), 'red'))

            player_input = None

            if rerolls <= 0:
                print(colored("没有剩余的重掷机会了！", 'cyan'))
                input("按下[ENTER]攻击...")
                player_input = 'a'

            end_turn = False

            while True:

                if player_input is None:
                    player_input = turn_query_action(rerolls)

                try:
                    if 'a' in player_input:
                        player_input = None
                        print("行动！")
                        total_dmg += turn_dmg
                        if turn_dmg > max_dmg:
                            max_dmg = turn_dmg
                        print(colored("伤害 %d | 平均 %d | 最高 %d" % (turn_dmg, total_dmg / turns, max_dmg), 'yellow'))
                        end_turn = True
                        break

                    else:
                        reroll_idxs = [int(s) for s in player_input.split(',')]
                        player_input = None

                        for ix in reroll_idxs:
                            if ix < 0 or ix > len(player_dices):
                                continue

                        for ix in reroll_idxs:
                            rolled_dices[ix - 1] = roll(player_dices[ix - 1])

                        rerolls -= 1
                        print("REROLL ...")
                        break
                except (ValueError, IndexError) as error:
                    player_input = None
                    continue
            
            if end_turn:
                break

if __name__ == "__main__":

    main()
