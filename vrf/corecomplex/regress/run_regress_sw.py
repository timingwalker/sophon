#!/bin/python3

import os
import sys
import time

f_tc_group   = ["./sanity-tests.tc", "./rv32ui.tc", "./benchmarks.tc"]
# relative to verification directory
tc_file_dir  = "../../sw/build/"
# relative to regress directory
log_dir_root = "log/"
log_curr_dir = ""
f_result     = "regress.result"


def run_test_group (f_tc, sw_type):

    #----------------------- read tc -------------------------------------------------
    regress_tc = []

    f = open(f_tc)
    lines = f.readlines()
    for line in lines:
        regress_tc.append(line.strip('\n'))
    f.close()

    #----------------------- compile -------------------------------------------------
    # regress is subdir of vrf, so change to vrf to call makefile
    pwd = os.getcwd()
    parent_pwd = os.path.dirname(pwd)
    os.chdir(parent_pwd)

    os.system("make clean" )
    os.system("make compile_sw TC_TYPE=" + sw_type )
    os.system("make compile_rtl" )

    #----------------------- simulation ----------------------------------------------
    regress_result=[]
    for tc in regress_tc:

        #tc_file = tc_file_dir + sw_type +"/" + tc + ".hex"
        cmd_make_sim = "make sim " + "TC_TYPE=" + sw_type + " TC=" + tc + " >> sim.log"
        print (cmd_make_sim)

        os.system ( cmd_make_sim )

        # check tc result
        tc_result = "FAILED"
        f = open("sim.log")
        lines = f.readlines()
        for line in lines:
            if "Testcase PASS!" in line:
                tc_result = "PASS"
        f.close()

        regress_result.append( "%-20s : %6s :   %s\n" % (tc, tc_result, cmd_make_sim) )

        # copy log
        os.system("mv sim.log "+pwd+"/"+log_dir_root+log_curr_dir+"/"+tc+".log")

    # change back to regress
    os.chdir(pwd)

    return regress_result


if __name__ == "__main__":

    print ("\n\n\n\n\nRegress test start...\n\n\n\n\n")
    regress_time = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))

    #----------------------- parameter -----------------------------------------------
    len_argv = len(sys.argv)
    # log curr dir
    if len_argv >= 2:
        log_curr_dir = sys.argv[1]
    else:
        log_curr_dir = regress_time
    # tc group
    if len_argv >= 3:
        f_tc_group.clear()
        for i in range(len_argv-2):
            f_tc_group.append(sys.argv[i+2])

    #----------------------- prepare -------------------------------------------------
    with open(f_result, "w") as file:
        file.write( regress_time )
        file.write('\n')
    if not os.path.exists(log_dir_root+log_curr_dir):
        os.makedirs(log_dir_root+log_curr_dir)

    #----------------------- run tc group --------------------------------------------
    for f_tc in f_tc_group:

        print ("Run test groups : %s\n" % (f_tc) )
        with open(f_result, "a") as file:
            file.write("\n")
            file.write( "="*72 + "\n")
            file.write( "Run test groups : %s\n" % (f_tc) )
            file.write( "="*72 + "\n")

        if 'benchmarks' in f_tc:
            sw_type = "benchmarks"
            print ("benchmarks")
        elif 'rv32' in f_tc:
            sw_type = "isa"
            print ("isa")
        elif 'sanity' in f_tc:
            sw_type = "sanity-tests"
            print ("sanity-tests")

        # run test cases
        result_group = run_test_group(f_tc, sw_type)
        for t in result_group:
            with open(f_result, "a") as file:
                file.write( t )

    #----------------------- end -----------------------------------------------------
    end_time = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))

    with open(f_result, "a") as file:
        file.write('\n')
        file.write( end_time )

    os.system("cat " + f_result )
    os.system("cp " + f_result + " " + log_dir_root + log_curr_dir)



