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
static const char *ng0 = "//vmware-host/Shared Folders/AES-128-256/Pipelined/RTL/Encryption/G-Function.v";



static void Cont_19_0(char *t0)
{
    char t3[8];
    char t9[8];
    char *t1;
    char *t2;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;

LAB0:    t1 = (t0 + 3168U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(19, ng0);
    t2 = (t0 + 1528U);
    t4 = *((char **)t2);
    t2 = (t0 + 2008U);
    t5 = *((char **)t2);
    t2 = (t0 + 1848U);
    t6 = *((char **)t2);
    t2 = (t0 + 1688U);
    t7 = *((char **)t2);
    t2 = (t0 + 1208U);
    t8 = *((char **)t2);
    t10 = *((unsigned int *)t7);
    t11 = *((unsigned int *)t8);
    t12 = (t10 ^ t11);
    *((unsigned int *)t9) = t12;
    t2 = (t7 + 4);
    t13 = (t8 + 4);
    t14 = (t9 + 4);
    t15 = *((unsigned int *)t2);
    t16 = *((unsigned int *)t13);
    t17 = (t15 | t16);
    *((unsigned int *)t14) = t17;
    t18 = *((unsigned int *)t14);
    t19 = (t18 != 0);
    if (t19 == 1)
        goto LAB4;

LAB5:
LAB6:    xsi_vlogtype_concat(t3, 32, 32, 4U, t9, 8, t6, 8, t5, 8, t4, 8);
    t22 = (t0 + 3568);
    t23 = (t22 + 56U);
    t24 = *((char **)t23);
    t25 = (t24 + 56U);
    t26 = *((char **)t25);
    memcpy(t26, t3, 8);
    xsi_driver_vfirst_trans(t22, 0, 31);
    t27 = (t0 + 3488);
    *((int *)t27) = 1;

LAB1:    return;
LAB4:    t20 = *((unsigned int *)t9);
    t21 = *((unsigned int *)t14);
    *((unsigned int *)t9) = (t20 | t21);
    goto LAB6;

}


extern void work_m_00000000000470039647_0645842995_init()
{
	static char *pe[] = {(void *)Cont_19_0};
	xsi_register_didat("work_m_00000000000470039647_0645842995", "isim/tb_AES_cascade_top_isim_beh.exe.sim/work/m_00000000000470039647_0645842995.didat");
	xsi_register_executes(pe);
}
