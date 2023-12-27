#!/bin/python3

import os
import time

f_tc     = "./regress/regress.tc"
f_result = "./regress/regress.result"

if __name__ == "__main__":

    print ("\n\n\n\n\nRegress test start...\n\n\n\n\n")


    #----------------------- prepare -------------------------------------------------
    regress_time = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))

    with open(f_result, "w") as file:
        file.write( regress_time )
        file.write('\n\n')

    if not os.path.exists('regress'):
        os.makedirs('regress')
    #---------------------------------------------------------------------------------


    #----------------------- read tc -------------------------------------------------
    regress_tc = []

    f = open(f_tc)
    lines = f.readlines()
    for line in lines:
        regress_tc.append(line.strip('\n'))
    f.close()
    #---------------------------------------------------------------------------------


    #----------------------- compile ----------------------------------------------
    os.system("make clean" )
    os.system("make build" )
    os.system("make sw_compile TEST=isa" )
    #----------------------- simulation ----------------------------------------------
    for tc in regress_tc:

        tc_cc0 = "../../sw/build/isa/" + tc + ".hex"

        cmd_make_sim = "make sim " + "CC0=" + tc_cc0 + " >> sim.log"
        print (cmd_make_sim)

        os.system ( cmd_make_sim )

        # check result
        tc_result = "FAILED"
        f = open("sim.log")
        lines = f.readlines()
        for line in lines:
            if "Testcase PASS!" in line:
                tc_result = "PASS"
        f.close()

        with open(f_result, "a") as file:
            #print ( "%-20s : %6s" % (tc, tc_result) )
            file.write( "%-20s : %6s :   %s\n" % (tc, tc_result, cmd_make_sim) )

        # copy log
        if not os.path.exists('regress/'+regress_time):
            os.makedirs('regress/'+regress_time)
        os.system("mv sim.log ./regress/"+regress_time+"/"+tc+".log")
    #---------------------------------------------------------------------------------


    end_time = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))

    with open(f_result, "a") as file:
        file.write('\n\n')
        file.write( end_time )

    os.system("cat " + f_result )
    # os.system("cp " + f_result + " ./regress/"+regress_time+"/"+f_result)


