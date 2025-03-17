#!/bin/python3

import os
import time

hw_feature_group = ["SOPHON_EEI SOPHON_EEI_SREG SOPHON_EEI_GPIO", \
                    "SOPHON_CLIC", \
                    "SOPHON_EEI SOPHON_EEI_SREG SOPHON_CLIC", \
                    "SOPHON_RVE", \
                    ]

always_on_hw_feature = "SOPHON_CLINT SOPHON_ZICSR SOPHON_EXT_INST SOPHON_EXT_DATA SOPHON_EXT_ACCESS"

# relative to regress directory
cfg_path = "../../../design/config/"
cfg_file = cfg_path + "config_feature.sv"
bak_cfg_file = cfg_path + "config_feature_bak.sv"
f_result     = "hw_regress.result"

if __name__ == "__main__":

    print ("\n\n\n\n\nHardware Parameters Regress Test Start...\n\n\n\n\n")

    regress_time = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))

    #----------------------- Back up the original config file ------------------------
    if os.path.exists(cfg_file):
        os.system("mv " + cfg_file + " " + bak_cfg_file)
    else:
        print ("\nConfig file does not exist....\n")
        os._exit(0)

    #----------------------- Run software regress test with each HW parameter --------
    with open(f_result, "w") as file:
        file.write('\n')
        file.write( regress_time )
        file.write('\n')

    for hw_feature in hw_feature_group:

        with open(cfg_file, "w") as file:
            file.write( "// hw regress test\n")

        hw_feature = always_on_hw_feature + " " + hw_feature

        hw_feature_spilt = hw_feature.split(" ")
        log_sub_dir = ""
        for feature in hw_feature_spilt:
            log_sub_dir  = log_sub_dir  + "_" + feature
            with open(cfg_file, "a") as file:
                file.write( "`define " + feature)
                file.write('\n')

        # call software regress test
        os.system("./run_regress_sw.py sw_tmp_log sanity-tests.tc rv32ui.tc benchmarks.tc")
        # os.system("./run_regress_sw.py sw_tmp_log rv32ui_simple.tc")

        # check result
        hw_feature_result = "PASS"
        f = open("./log/sw_tmp_log/regress.result")
        lines = f.readlines()
        for line in lines:
            if "FAILED" in line:
                hw_feature_result = "FAILED"
        f.close()

        with open(f_result, "a") as file:
            file.write( "="*72 + "\n")
            file.write( "Parameter : %s\n" % log_sub_dir )
            file.write( "Result    : %s\n" % hw_feature_result)

        # copy log
        log_dir = "./log/hw_"+regress_time+"/"+log_sub_dir
        os.system("mkdir -p " + log_dir)
        os.system("cp " + cfg_file + " " + log_dir)
        os.system("cp ./log/sw_tmp_log/*" + " " + log_dir)
        os.system("rm -rf ./log/sw_tmp_log")

    #----------------------- Restore the original config file ------------------------
    os.system("mv " + bak_cfg_file + " " + cfg_file)

    end_time = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))
    with open(f_result, "a") as file:
        file.write('\n')
        file.write( end_time )
        file.write('\n')

    os.system("cp " + f_result + " ./log/hw_" + regress_time)
    os.system("cat " + f_result)


