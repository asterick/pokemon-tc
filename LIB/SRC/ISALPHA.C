/*
 *	Version : @(#)isalpha.c	1.2	
 */

/**************************************************************************
**                                                                        *
**  FILE        :  isalpha.c                                              *
**                                                                        *
**  DESCRIPTION :  Source file for isalpha() routine                      *
**                 Returns non zero if given character is an upper- or    *
**                 lowercase character.                                   *
**                                                                        *
**  COPYRIGHT   :  1996 Tasking Software B.V.                             *
**                                                                        *
**************************************************************************/
#include <ctype.h>

#undef	isalpha

int
isalpha( int c )
{
	return( (_ctype_+1)[c] & (__U|__L) );
}
