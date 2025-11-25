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
static const char *ng0 = "E:/AES/ISE/AES_128_Decryption_Iterative/AES_128_Decryption_DFT.v";
static unsigned int ng1[] = {0U, 0U};
static unsigned int ng2[] = {426380082U, 0U, 3692135831U, 0U, 47974907U, 0U, 958759965U, 0U};
static unsigned int ng3[] = {164581180U, 0U, 2885096840U, 0U, 682545830U, 0U, 729683222U, 0U};
static unsigned int ng4[] = {3761702708U, 0U, 825333922U, 0U, 2287612045U, 0U, 843314856U, 0U};
static unsigned int ng5[] = {1U, 0U};
static unsigned int ng6[] = {1890895194U, 0U, 3637360512U, 0U, 1786446896U, 0U, 1774510296U, 0U};
static unsigned int ng7[] = {202182159U, 0U, 134810123U, 0U, 67438087U, 0U, 66051U, 0U};
static unsigned int ng8[] = {3437096703U, 0U, 2291772091U, 0U, 1146447479U, 0U, 1122867U, 0U};
static unsigned int ng9[] = {2U, 0U};
static unsigned int ng10[] = {610725783U, 0U, 2828978931U, 0U, 226113120U, 0U, 987200436U, 0U};
static unsigned int ng11[] = {1939019562U, 0U, 3913121297U, 0U, 775987094U, 0U, 1807859426U, 0U};
static unsigned int ng12[] = {3U, 0U};
static unsigned int ng13[] = {1876667120U, 0U, 2019071401U, 0U, 62482910U, 0U, 4124300677U, 0U};
static unsigned int ng14[] = {4255664673U, 0U, 3496363432U, 0U, 1563191503U, 0U, 4219254455U, 0U};
static unsigned int ng15[] = {4U, 0U};
static unsigned int ng16[] = {3392416558U, 0U, 2286746201U, 0U, 4018809915U, 0U, 1726565332U, 0U};
static unsigned int ng17[] = {0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U};
static unsigned int ng18[] = {5U, 0U};
static unsigned int ng19[] = {3204150795U, 0U, 1977701469U, 0U, 2396863921U, 0U, 3366138367U, 0U};
static unsigned int ng20[] = {6U, 0U};
static unsigned int ng21[] = {423278969U, 0U, 2991681618U, 0U, 2994786096U, 0U, 3166642556U, 0U};
static unsigned int ng22[] = {4294967295U, 0U, 4294967295U, 0U, 4294967295U, 0U, 4294967295U, 0U};
static unsigned int ng23[] = {7U, 0U};
static unsigned int ng24[] = {952092972U, 0U, 2305050693U, 0U, 2273140685U, 0U, 2717263244U, 0U};



static void Always_48_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    int t6;
    char *t7;
    char *t8;

LAB0:    t1 = (t0 + 4808U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(48, ng0);
    t2 = (t0 + 5376);
    *((int *)t2) = 1;
    t3 = (t0 + 4840);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(48, ng0);

LAB5:    xsi_set_current_line(49, ng0);
    t4 = (t0 + 2048U);
    t5 = *((char **)t4);

LAB6:    t4 = ((char*)((ng1)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t4, 3);
    if (t6 == 1)
        goto LAB7;

LAB8:    t2 = ((char*)((ng5)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB9;

LAB10:    t2 = ((char*)((ng9)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB11;

LAB12:    t2 = ((char*)((ng12)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB13;

LAB14:    t2 = ((char*)((ng15)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB15;

LAB16:    t2 = ((char*)((ng18)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB17;

LAB18:    t2 = ((char*)((ng20)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB19;

LAB20:    t2 = ((char*)((ng23)));
    t6 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t6 == 1)
        goto LAB21;

LAB22:
LAB24:
LAB23:    xsi_set_current_line(106, ng0);

LAB34:    xsi_set_current_line(107, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(108, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(109, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);

LAB25:    goto LAB2;

LAB7:    xsi_set_current_line(51, ng0);

LAB26:    xsi_set_current_line(52, ng0);
    t7 = ((char*)((ng2)));
    t8 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t8, t7, 0, 0, 128, 0LL);
    xsi_set_current_line(53, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(54, ng0);
    t2 = ((char*)((ng4)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB9:    xsi_set_current_line(58, ng0);

LAB27:    xsi_set_current_line(59, ng0);
    t3 = ((char*)((ng6)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(60, ng0);
    t2 = ((char*)((ng7)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(61, ng0);
    t2 = ((char*)((ng8)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB11:    xsi_set_current_line(65, ng0);

LAB28:    xsi_set_current_line(66, ng0);
    t3 = ((char*)((ng10)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(67, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(68, ng0);
    t2 = ((char*)((ng11)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB13:    xsi_set_current_line(71, ng0);

LAB29:    xsi_set_current_line(72, ng0);
    t3 = ((char*)((ng13)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(73, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(74, ng0);
    t2 = ((char*)((ng14)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB15:    xsi_set_current_line(78, ng0);

LAB30:    xsi_set_current_line(79, ng0);
    t3 = ((char*)((ng16)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(80, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(81, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB17:    xsi_set_current_line(85, ng0);

LAB31:    xsi_set_current_line(86, ng0);
    t3 = ((char*)((ng19)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(87, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(88, ng0);
    t2 = ((char*)((ng8)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB19:    xsi_set_current_line(92, ng0);

LAB32:    xsi_set_current_line(93, ng0);
    t3 = ((char*)((ng21)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(94, ng0);
    t2 = ((char*)((ng22)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(95, ng0);
    t2 = ((char*)((ng22)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

LAB21:    xsi_set_current_line(99, ng0);

LAB33:    xsi_set_current_line(100, ng0);
    t3 = ((char*)((ng24)));
    t4 = (t0 + 3088);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 128, 0LL);
    xsi_set_current_line(101, ng0);
    t2 = ((char*)((ng22)));
    t3 = (t0 + 3248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    xsi_set_current_line(102, ng0);
    t2 = ((char*)((ng17)));
    t3 = (t0 + 3408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 128, 0LL);
    goto LAB25;

}

static void Always_131_1(char *t0)
{
    char t4[8];
    char t22[32];
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
    char *t23;
    char *t24;
    char *t25;

LAB0:    t1 = (t0 + 5056U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(131, ng0);
    t2 = (t0 + 5392);
    *((int *)t2) = 1;
    t3 = (t0 + 5088);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(131, ng0);

LAB5:    xsi_set_current_line(132, ng0);
    t5 = (t0 + 1888U);
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

LAB11:    xsi_set_current_line(142, ng0);

LAB14:    xsi_set_current_line(144, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 3728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(145, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 3568);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(147, ng0);
    t2 = (t0 + 3888);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);

LAB15:    t6 = ((char*)((ng1)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 3, t6, 3);
    if (t21 == 1)
        goto LAB16;

LAB17:    t2 = ((char*)((ng5)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t21 == 1)
        goto LAB18;

LAB19:    t2 = ((char*)((ng9)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t21 == 1)
        goto LAB20;

LAB21:    t2 = ((char*)((ng15)));
    t21 = xsi_vlog_unsigned_case_compare(t5, 3, t2, 3);
    if (t21 == 1)
        goto LAB22;

LAB23:
LAB25:
LAB24:    xsi_set_current_line(177, ng0);

LAB40:    xsi_set_current_line(178, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 3888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 3, 0LL);

LAB26:
LAB12:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(132, ng0);

LAB13:    xsi_set_current_line(134, ng0);
    t19 = ((char*)((ng1)));
    t20 = (t0 + 3888);
    xsi_vlogvar_wait_assign_value(t20, t19, 0, 0, 3, 0LL);
    xsi_set_current_line(135, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 3568);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(136, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(137, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(140, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 3728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB12;

LAB16:    xsi_set_current_line(148, ng0);

LAB27:    xsi_set_current_line(149, ng0);
    t12 = ((char*)((ng5)));
    t13 = (t0 + 3888);
    xsi_vlogvar_wait_assign_value(t13, t12, 0, 0, 3, 0LL);
    goto LAB26;

LAB18:    xsi_set_current_line(152, ng0);

LAB28:    xsi_set_current_line(153, ng0);
    t3 = ((char*)((ng5)));
    t6 = (t0 + 3568);
    xsi_vlogvar_wait_assign_value(t6, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(154, ng0);
    t2 = ((char*)((ng9)));
    t3 = (t0 + 3888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 3, 0LL);
    goto LAB26;

LAB20:    xsi_set_current_line(158, ng0);

LAB29:    xsi_set_current_line(159, ng0);
    t3 = (t0 + 2368U);
    t6 = *((char **)t3);
    t3 = (t6 + 4);
    t7 = *((unsigned int *)t3);
    t8 = (~(t7));
    t9 = *((unsigned int *)t6);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB30;

LAB31:
LAB32:    goto LAB26;

LAB22:    xsi_set_current_line(173, ng0);

LAB39:    xsi_set_current_line(174, ng0);
    t3 = ((char*)((ng15)));
    t6 = (t0 + 3888);
    xsi_vlogvar_wait_assign_value(t6, t3, 0, 0, 3, 0LL);
    goto LAB26;

LAB30:    xsi_set_current_line(159, ng0);

LAB33:    xsi_set_current_line(161, ng0);
    t12 = (t0 + 2208U);
    t13 = *((char **)t12);
    t12 = (t0 + 3408);
    t19 = (t12 + 56U);
    t20 = *((char **)t19);
    xsi_vlog_unsigned_equal(t22, 128, t13, 128, t20, 128);
    t23 = (t22 + 4);
    t14 = *((unsigned int *)t23);
    t15 = (~(t14));
    t16 = *((unsigned int *)t22);
    t17 = (t16 & t15);
    t18 = (t17 != 0);
    if (t18 > 0)
        goto LAB34;

LAB35:    xsi_set_current_line(164, ng0);

LAB38:    xsi_set_current_line(165, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(166, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 2928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);

LAB36:    xsi_set_current_line(168, ng0);
    t2 = ((char*)((ng15)));
    t3 = (t0 + 3888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 3, 0LL);
    goto LAB32;

LAB34:    xsi_set_current_line(161, ng0);

LAB37:    xsi_set_current_line(162, ng0);
    t24 = ((char*)((ng5)));
    t25 = (t0 + 2768);
    xsi_vlogvar_wait_assign_value(t25, t24, 0, 0, 1, 0LL);
    xsi_set_current_line(163, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB36;

}


extern void work_m_00000000001773365207_2585705929_init()
{
	static char *pe[] = {(void *)Always_48_0,(void *)Always_131_1};
	xsi_register_didat("work_m_00000000001773365207_2585705929", "isim/tb_AES_DFT_Decrypt_Reset_Method_isim_beh.exe.sim/work/m_00000000001773365207_2585705929.didat");
	xsi_register_executes(pe);
}
