/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x7708f090 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "t=%0t | valid_in=%b | valid_out=%b | round=%d | Dec_en=%b\n  KeyLoad=%h\n  KeyRound=%h\n  Plaintext=%h\n state=%h\n";
static const char *ng1 = "E:/AES/AES-128-256/Iterative/Decryption/Test Benches/TB_top_module.v";
static int ng2[] = {0, 0};
static int ng3[] = {0, 0, 0, 0, 0, 0, 0, 0};
static const char *ng4 = "top_module_tb.vcd";
static int ng5[] = {1, 0};
static unsigned int ng6[] = {164581180U, 0U, 2885096840U, 0U, 682545830U, 0U, 729683222U, 0U};
static unsigned int ng7[] = {426380082U, 0U, 3692135831U, 0U, 47974907U, 0U, 958759965U, 0U};
static const char *ng8 = "\n--------------------------------------------";
static const char *ng9 = "Decryption Completed at time %0t ns";
static const char *ng10 = "Plaintext = %h";
static const char *ng11 = "--------------------------------------------\n";
static const char *ng12 = "Time\tState Info";

void Monitor_101_3(char *);
void Monitor_101_3(char *);


static void Monitor_101_3_Func(char *t0)
{
    char t1[16];
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;

LAB0:    t2 = xsi_vlog_time(t1, 1000.0000000000000, 1000.0000000000000);
    t3 = (t0 + 2360);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t0 + 1480U);
    t7 = *((char **)t6);
    t6 = (t0 + 6844);
    t8 = *((char **)t6);
    t9 = ((((char*)(t8))) + 40U);
    t10 = *((char **)t9);
    t9 = (t0 + 6876);
    t11 = *((char **)t9);
    t12 = ((((char*)(t11))) + 40U);
    t13 = *((char **)t12);
    t12 = (t0 + 6908);
    t14 = *((char **)t12);
    t15 = ((((char*)(t14))) + 40U);
    t16 = *((char **)t15);
    t15 = (t0 + 6948);
    t17 = *((char **)t15);
    t18 = ((((char*)(t17))) + 40U);
    t19 = *((char **)t18);
    t18 = (t0 + 6988);
    t20 = *((char **)t18);
    t21 = ((((char*)(t20))) + 40U);
    t22 = *((char **)t21);
    t21 = (t0 + 7020);
    t23 = *((char **)t21);
    t24 = ((((char*)(t23))) + 56U);
    t25 = *((char **)t24);
    xsi_vlogfile_write(1, 0, 3, ng0, 10, t0, (char)118, t1, 64, (char)118, t5, 1, (char)118, t7, 1, (char)118, t10, 4, (char)118, t13, 1, (char)118, t16, 128, (char)118, t19, 128, (char)118, t22, 128, (char)118, t25, 2);

LAB1:    return;
}

static void Initial_38_0(char *t0)
{
    char t4[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    char *t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    char *t24;

LAB0:    t1 = (t0 + 3600U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(38, ng1);

LAB4:    xsi_set_current_line(39, ng1);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2040);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(40, ng1);

LAB5:    xsi_set_current_line(40, ng1);
    t2 = (t0 + 3408);
    xsi_process_wait(t2, 5000LL);
    *((char **)t1) = &&LAB6;

LAB1:    return;
LAB6:    xsi_set_current_line(40, ng1);
    t3 = (t0 + 2040);
    t5 = (t3 + 56U);
    t6 = *((char **)t5);
    memset(t4, 0, 8);
    t7 = (t6 + 4);
    t8 = *((unsigned int *)t7);
    t9 = (~(t8));
    t10 = *((unsigned int *)t6);
    t11 = (t10 & t9);
    t12 = (t11 & 1U);
    if (t12 != 0)
        goto LAB10;

LAB8:    if (*((unsigned int *)t7) == 0)
        goto LAB7;

LAB9:    t13 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t13) = 1;

LAB10:    t14 = (t4 + 4);
    t15 = (t6 + 4);
    t16 = *((unsigned int *)t6);
    t17 = (~(t16));
    *((unsigned int *)t4) = t17;
    *((unsigned int *)t14) = 0;
    if (*((unsigned int *)t15) != 0)
        goto LAB12;

LAB11:    t22 = *((unsigned int *)t4);
    *((unsigned int *)t4) = (t22 & 1U);
    t23 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t23 & 1U);
    t24 = (t0 + 2040);
    xsi_vlogvar_assign_value(t24, t4, 0, 0, 1);
    goto LAB5;

LAB7:    *((unsigned int *)t4) = 1;
    goto LAB10;

LAB12:    t18 = *((unsigned int *)t4);
    t19 = *((unsigned int *)t15);
    *((unsigned int *)t4) = (t18 | t19);
    t20 = *((unsigned int *)t14);
    t21 = *((unsigned int *)t15);
    *((unsigned int *)t14) = (t20 | t21);
    goto LAB11;

LAB13:    goto LAB1;

}

static void Initial_57_1(char *t0)
{
    char t4[8];
    char t16[16];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    char *t15;

LAB0:    t1 = (t0 + 3848U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(57, ng1);

LAB4:    xsi_set_current_line(60, ng1);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2200);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(61, ng1);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2360);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(62, ng1);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 2520);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 128);
    xsi_set_current_line(63, ng1);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 2680);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 128);
    xsi_set_current_line(66, ng1);
    xsi_vcd_dumpfile(ng4);
    xsi_set_current_line(67, ng1);
    t2 = ((char*)((ng2)));
    xsi_vcd_dumpvars_args(*((unsigned int *)t2), t0, (char)109, t0, (char)101);
    xsi_set_current_line(70, ng1);
    t2 = (t0 + 3656);
    xsi_process_wait(t2, 20000LL);
    *((char **)t1) = &&LAB5;

LAB1:    return;
LAB5:    xsi_set_current_line(71, ng1);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 2200);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(72, ng1);
    t2 = (t0 + 3656);
    xsi_process_wait(t2, 20000LL);
    *((char **)t1) = &&LAB6;
    goto LAB1;

LAB6:    xsi_set_current_line(75, ng1);
    t2 = (t0 + 4664);
    *((int *)t2) = 1;
    t3 = (t0 + 3880);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB7;
    goto LAB1;

LAB7:    xsi_set_current_line(76, ng1);
    t2 = ((char*)((ng6)));
    t3 = (t0 + 2680);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(77, ng1);
    t2 = ((char*)((ng7)));
    t3 = (t0 + 2520);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(78, ng1);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 2360);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(80, ng1);
    t2 = (t0 + 4680);
    *((int *)t2) = 1;
    t3 = (t0 + 3880);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB8;
    goto LAB1;

LAB8:    xsi_set_current_line(81, ng1);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2360);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(84, ng1);

LAB9:    t2 = (t0 + 1480U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng5)));
    memset(t4, 0, 8);
    if (*((unsigned int *)t3) != *((unsigned int *)t2))
        goto LAB12;

LAB10:    t5 = (t3 + 4);
    t6 = (t2 + 4);
    if (*((unsigned int *)t5) != *((unsigned int *)t6))
        goto LAB12;

LAB11:    *((unsigned int *)t4) = 1;

LAB12:    t7 = (t4 + 4);
    t8 = *((unsigned int *)t7);
    t9 = (~(t8));
    t10 = *((unsigned int *)t4);
    t11 = (t10 & t9);
    t12 = (t11 != 0);
    if (t12 > 0)
        goto LAB14;

LAB13:    t13 = (t0 + 4696);
    *((int *)t13) = 1;
    t14 = (t0 + 3848U);
    *((char **)t14) = &&LAB9;
    goto LAB1;

LAB14:    t15 = (t0 + 4696);
    *((int *)t15) = 0;
    xsi_set_current_line(86, ng1);
    xsi_vlogfile_write(1, 0, 0, ng8, 1, t0);
    xsi_set_current_line(87, ng1);
    t2 = xsi_vlog_time(t16, 1000.0000000000000, 1000.0000000000000);
    xsi_vlogfile_write(1, 0, 0, ng9, 2, t0, (char)118, t16, 64);
    xsi_set_current_line(88, ng1);
    t2 = (t0 + 1320U);
    t3 = *((char **)t2);
    xsi_vlogfile_write(1, 0, 0, ng10, 2, t0, (char)118, t3, 128);
    xsi_set_current_line(89, ng1);
    xsi_vlogfile_write(1, 0, 0, ng11, 1, t0);
    xsi_set_current_line(91, ng1);
    t2 = (t0 + 3656);
    xsi_process_wait(t2, 20000LL);
    *((char **)t1) = &&LAB15;
    goto LAB1;

LAB15:    xsi_set_current_line(92, ng1);
    xsi_vlog_stop(1);
    goto LAB1;

}

static void Initial_99_2(char *t0)
{

LAB0:    xsi_set_current_line(99, ng1);

LAB2:    xsi_set_current_line(100, ng1);
    xsi_vlogfile_write(1, 0, 0, ng12, 1, t0);
    xsi_set_current_line(101, ng1);
    Monitor_101_3(t0);

LAB1:    return;
}

void Monitor_101_3(char *t0)
{
    char *t1;
    char *t2;

LAB0:    t1 = (t0 + 4152);
    t2 = (t0 + 4712);
    xsi_vlogfile_monitor((void *)Monitor_101_3_Func, t1, t2);

LAB1:    return;
}


extern void work_m_00000000002941550934_3807137581_init()
{
	static char *pe[] = {(void *)Initial_38_0,(void *)Initial_57_1,(void *)Initial_99_2,(void *)Monitor_101_3};
	xsi_register_didat("work_m_00000000002941550934_3807137581", "isim/tb_Top_Module_isim_beh.exe.sim/work/m_00000000002941550934_3807137581.didat");
	xsi_register_executes(pe);
}
