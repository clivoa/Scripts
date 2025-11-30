/*
 * =====================================================================================
 *
 *       Filename:  resolv.c
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  03-07-2016 12:53:09
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (), 
 *   Organization:  
 *
 * =====================================================================================
 */
#include <stdlib.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <stdio.h>

int main (int argc, char *argv[])
{
	char *alvo;
	alvo = argv[1];

	struct hostent *host;

	host=gethostbyname(alvo);

	printf("%s ===> %s \n",alvo, inet_ntoa(*((struct in_addr *)host ->h_addr)));
	return 0;
}

