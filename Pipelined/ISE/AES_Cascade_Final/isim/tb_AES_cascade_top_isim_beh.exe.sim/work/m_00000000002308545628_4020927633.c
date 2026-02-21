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
static const char *ng0 = "//vmware-host/Shared Folders/AES-128-256/Pipelined/RTL/Encryption/FSM.v";
static unsigned int ng1[] = {0U, 0U};
static unsigned int ng2[] = {1U, 0U};
static unsigned int ng3[] = {2U, 0U};
static unsigned int ng4[] = {11U, 0U};



static void Always_19_0(char *t0)
{
    char t4[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    char *t19;
    char *t20;

LAB0:    t1 = (t0 + 3736U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(19, ng0);
    t2 = (t0 + 4552);
    *((int *)t2) = 1;
    t3 = (t0 + 3768);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(20, ng0);

LAB5:    xsi_set_current_line(21, ng0);
    t5 = (t0 + 1616U);
    t6 = *((char **)t5);
    memset(t4, 0, 8);
    t5 = (t6 + 4);
    t7 = *((unsigned int *)t5);
    t8 = (~(t7));
    t9 = *((unsigned int *)t6);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB9;

LAB7:    if (*((unsigned int *)t5) == 0)
        goto LAB6;

LAB8:    t12 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t12) = 1;

LAB9:    t13 = (t4 + 4);
    t14 = *((unsigned int *)t13);
    t15 = (~(t14));
    t16 = *((unsigned int *)t4);
    t17 = (t16 & t15);
    t18 = (t17 != 0);
    if (t18 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(24, ng0);
    t2 = (t0 + 2816);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = (t0 + 2656);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 2, 0LL);

LAB12:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(22, ng0);
    t19 = ((char*)((ng1)));
    t20 = (t0 + 2656);
    xsi_vlogvar_wait_assign_value(t20, t19, 0, 0, 2, 0LL);
    goto LAB12;

}

static void Always_31_1(char *t0)
{
    char t4[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    char *t19;
    char *t20;
    int t21;
    unsigned int t22;
    unsigned int t23;
    char *t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    char *t32;

LAB0:    t1 = (t0 + 3984U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(31, ng0);
    t2 = (t0 + 4568);
    *((int *)t2) = 1;
    t3 = (t0 + 4016);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(32, ng0);

LAB5:    xsi_set_current_line(33, ng0);
    t5 = (t0 + 1616U);
    t6 = *((char **)t5);
    memset(t4, 0, 8);
    t5 = (t6 + 4);
    t7 = *((unsigned int *)t5);
    t8 = (~(t7));
    t9 = *((unsigned int *)t6);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB9;

LAB7:    if (*((unsigned int *)t5) == 0)
        goto LAB6;

LAB8:    t12 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t12) = 1;

LAB9:    t13 = (t4 + 4);
    t14 = *((unsigned int *)t13);
    t15 = (~(t14));
    t16 = *((unsigned int *)t4);
    t17 = (t16 & t15);
    t18 = (t17 != 0);
    if (t18 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(41, ng0);

LAB14:    xsi_set_current_line(42, ng0);
    t2 = (t0 + 2816);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);

LAB15:    t6 = ((char*)((ng1)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 2, t6, 2);
    if (t21 == 1)
        goto LAB16;

LAB17:    t2 = ((char*)((ng2)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 2, t2, 2);
    if (t21 == 1)
        goto LAB18;

LAB19:    t2 = ((char*)((ng3)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 2, t2, 2);
    if (t21 == 1)
        goto LAB20;

LAB21:
LAB22:
LAB12:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(34, ng0);

LAB13:    xsi_set_current_line(35, ng0);
    t19 = ((char*)((ng1)));
    t20 = (t0 + 2496);
    xsi_vlogvar_wait_assign_value(t20, t19, 0, 0, 4, 0LL);
    xsi_set_current_line(36, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2336);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 4, 0LL);
    xsi_set_current_line(37, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2176);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB12;

LAB16:    xsi_set_current_line(44, ng0);

LAB23:    xsi_set_current_line(45, ng0);
    t12 = ((char*)((ng1)));
    t13 = (t0 + 2496);
    xsi_vlogvar_wait_assign_value(t13, t12, 0, 0, 4, 0LL);
    xsi_set_current_line(46, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2336);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 4, 0LL);
    xsi_set_current_line(47, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2176);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB22;

LAB18:    xsi_set_current_line(51, ng0);

LAB24:    xsi_set_current_line(52, ng0);
    t3 = (t0 + 2656);
    t6 = (t3 + 56U);
    t12 = *((char **)t6);
    t13 = ((char*)((ng2)));
    memset(t4, 0, 8);
    t19 = (t12 + 4);
    t20 = (t13 + 4);
    t7 = *((unsigned int *)t12);
    t8 = *((unsigned int *)t13);
    t9 = (t7 ^ t8);
    t10 = *((unsigned int *)t19);
    t11 = *((unsigned int *)t20);
    t14 = (t10 ^ t11);
    t15 = (t9 | t14);
    t16 = *((unsigned int *)t19);
    t17 = *((unsigned int *)t20);
    t18 = (t16 | t17);
    t22 = (~(t18));
    t23 = (t15 & t22);
    if (t23 != 0)
        goto LAB26;

LAB25:    if (t18 != 0)
        goto LAB27;

LAB28:    t25 = (t4 + 4);
    t26 = *((unsigned int *)t25);
    t27 = (~(t26));
    t28 = *((unsigned int *)t4);
    t29 = (t28 & t27);
    t30 = (t29 != 0);
    if (t30 > 0)
        goto LAB29;

LAB30:    xsi_set_current_line(60, ng0);

LAB33:    xsi_set_current_line(61, ng0);
    t2 = (t0 + 2496);
    t3 = (t2 + 56U);
    t6 = *((char **)t3);
    t12 = ((char*)((ng2)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_add(t4, 4, t6, 4, t12, 4);
    t13 = (t0 + 2496);
    xsi_vlogvar_wait_assign_value(t13, t4, 0, 0, 4, 0LL);
    xsi_set_current_line(62, ng0);
    t2 = (t0 + 2496);
    t3 = (t2 + 56U);
    t6 = *((char **)t3);
    t12 = ((char*)((ng2)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_add(t4, 4, t6, 4, t12, 4);
    t13 = (t0 + 2336);
    xsi_vlogvar_wait_assign_value(t13, t4, 0, 0, 4, 0LL);
    xsi_set_current_line(63, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2176);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);

LAB31:    goto LAB22;

LAB20:    xsi_set_current_line(68, ng0);

LAB34:    xsi_set_current_line(69, ng0);
    t3 = ((char*)((ng1)));
    t6 = (t0 + 2496);
    xsi_vlogvar_wait_assign_value(t6, t3, 0, 0, 4, 0LL);
    xsi_set_current_line(70, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2336);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 4, 0LL);
    xsi_set_current_line(71, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2176);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB22;

LAB26:    *((unsigned int *)t4) = 1;
    goto LAB28;

LAB27:    t24 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t24) = 1;
    goto LAB28;

LAB29:    xsi_set_current_line(53, ng0);

LAB32:    xsi_set_current_line(54, ng0);
    t31 = ((char*)((ng1)));
    t32 = (t0 + 2496);
    xsi_vlogvar_wait_assign_value(t32, t31, 0, 0, 4, 0LL);
    xsi_set_current_line(55, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2336);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 4, 0LL);
    xsi_set_current_line(56, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2176);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB31;

}

static void Always_79_2(char *t0)
{
    char t18[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    int t8;
    char *t9;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    char *t32;

LAB0:    t1 = (t0 + 4232U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(79, ng0);
    t2 = (t0 + 4584);
    *((int *)t2) = 1;
    t3 = (t0 + 4264);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(80, ng0);

LAB5:    xsi_set_current_line(81, ng0);
    t4 = (t0 + 2656);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);

LAB6:    t7 = ((char*)((ng1)));
    t8 = xsi_vlog_unsigned_case_compare(t6, 2, t7, 2);
    if (t8 == 1)
        goto LAB7;

LAB8:    t2 = ((char*)((ng2)));
    t8 = xsi_vlog_unsigned_case_compare(t6, 2, t2, 2);
    if (t8 == 1)
        goto LAB9;

LAB10:    t2 = ((char*)((ng3)));
    t8 = xsi_vlog_unsigned_case_compare(t6, 2, t2, 2);
    if (t8 == 1)
        goto LAB11;

LAB12:
LAB14:
LAB13:    xsi_set_current_line(104, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2816);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 2);

LAB15:    goto LAB2;

LAB7:    xsi_set_current_line(84, ng0);
    t9 = (t0 + 1776U);
    t10 = *((char **)t9);
    t9 = (t10 + 4);
    t11 = *((unsigned int *)t9);
    t12 = (~(t11));
    t13 = *((unsigned int *)t10);
    t14 = (t13 & t12);
    t15 = (t14 != 0);
    if (t15 > 0)
        goto LAB16;

LAB17:    xsi_set_current_line(87, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2816);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 2);

LAB18:    goto LAB15;

LAB9:    xsi_set_current_line(90, ng0);
    t3 = (t0 + 2496);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t7 = ((char*)((ng4)));
    memset(t18, 0, 8);
    t9 = (t5 + 4);
    t10 = (t7 + 4);
    t11 = *((unsigned int *)t5);
    t12 = *((unsigned int *)t7);
    t13 = (t11 ^ t12);
    t14 = *((unsigned int *)t9);
    t15 = *((unsigned int *)t10);
    t19 = (t14 ^ t15);
    t20 = (t13 | t19);
    t21 = *((unsigned int *)t9);
    t22 = *((unsigned int *)t10);
    t23 = (t21 | t22);
    t24 = (~(t23));
    t25 = (t20 & t24);
    if (t25 != 0)
        goto LAB22;

LAB19:    if (t23 != 0)
        goto LAB21;

LAB20:    *((unsigned int *)t18) = 1;

LAB22:    t17 = (t18 + 4);
    t26 = *((unsigned int *)t17);
    t27 = (~(t26));
    t28 = *((unsigned int *)t18);
    t29 = (t28 & t27);
    t30 = (t29 != 0);
    if (t30 > 0)
        goto LAB23;

LAB24:    xsi_set_current_line(93, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2816);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 2);

LAB25:    goto LAB15;

LAB11:    xsi_set_current_line(96, ng0);
    t3 = (t0 + 1616U);
    t4 = *((char **)t3);
    memset(t18, 0, 8);
    t3 = (t4 + 4);
    t11 = *((unsigned int *)t3);
    t12 = (~(t11));
    t13 = *((unsigned int *)t4);
    t14 = (t13 & t12);
    t15 = (t14 & 1U);
    if (t15 != 0)
        goto LAB29;

LAB27:    if (*((unsigned int *)t3) == 0)
        goto LAB26;

LAB28:    t5 = (t18 + 4);
    *((unsigned int *)t18) = 1;
    *((unsigned int *)t5) = 1;

LAB29:    t7 = (t18 + 4);
    t19 = *((unsigned int *)t7);
    t20 = (~(t19));
    t21 = *((unsigned int *)t18);
    t22 = (t21 & t20);
    t23 = (t22 != 0);
    if (t23 > 0)
        goto LAB30;

LAB31:    xsi_set_current_line(98, ng0);
    t2 = (t0 + 1776U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t11 = *((unsigned int *)t2);
    t12 = (~(t11));
    t13 = *((unsigned int *)t3);
    t14 = (t13 & t12);
    t15 = (t14 != 0);
    if (t15 > 0)
        goto LAB33;

LAB34:    xsi_set_current_line(101, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 2816);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 2);

LAB35:
LAB32:    goto LAB15;

LAB16:    xsi_set_current_line(85, ng0);
    t16 = ((char*)((ng2)));
    t17 = (t0 + 2816);
    xsi_vlogvar_assign_value(t17, t16, 0, 0, 2);
    goto LAB18;

LAB21:    t16 = (t18 + 4);
    *((unsigned int *)t18) = 1;
    *((unsigned int *)t16) = 1;
    goto LAB22;

LAB23:    xsi_set_current_line(91, ng0);
    t31 = ((char*)((ng3)));
    t32 = (t0 + 2816);
    xsi_vlogvar_assign_value(t32, t31, 0, 0, 2);
    goto LAB25;

LAB26:    *((unsigned int *)t18) = 1;
    goto LAB29;

LAB30:    xsi_set_current_line(97, ng0);
    t9 = ((char*)((ng1)));
    t10 = (t0 + 2816);
    xsi_vlogvar_assign_value(t10, t9, 0, 0, 2);
    goto LAB32;

LAB33:    xsi_set_current_line(99, ng0);
    t4 = ((char*)((ng2)));
    t5 = (t0 + 2816);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    goto LAB35;

}


extern void work_m_00000000002308545628_4020927633_init()
{
	static char *pe[] = {(void *)Always_19_0,(void *)Always_31_1,(void *)Always_79_2};
	xsi_register_didat("work_m_00000000002308545628_4020927633", "isim/tb_AES_cascade_top_isim_beh.exe.sim/work/m_00000000002308545628_4020927633.didat");
	xsi_register_executes(pe);
}
