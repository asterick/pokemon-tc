/*
 *	Version : @(#)strlen.c	1.2	
 */

/**************************************************************************
**                                                                        *
**  FILE        :  strlen.c                                               *
**                                                                        *
**  DESCRIPTION :  Source file for strlen() routine                       *
**                 Returns the length of a string.                        *
**                                                                        *
**  COPYRIGHT   :  1996 Tasking Software B.V.                             *
**                                                                        *
**************************************************************************/
#include <string.h>


size_t
strlen( register const char *s )
{
	register size_t n = 0;

	while (*s++)
		n++;
	return(n);
}
