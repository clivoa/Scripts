/*
 * =====================================================================================
 *
 *       Filename:  socket.c
 *
 *    Description:  socket em c teste
 *
 *        Version:  1.0
 *        Created:  29-06-2016 19:57:46
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (), 
 *   Organization:  
 *
 * =====================================================================================
 */
#include <stdlib.h>
#include <stdio.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
	int meusocket;
	int conecta;

	struct sockaddr_in alvo;

	meusocket = socket(AF_INET, SOCK_STREAM, 0);
	alvo.sin_family = AF_INET;
	alvo.sin_port = htons(80);
	alvo.sin_addr.s_addr = inet_addr("10.0.2.15");

	conecta = connect(meusocket, (struct sockaddr *)& alvo, sizeof alvo);

	if(conecta == 0)
	{
		printf("Porta Aberta \n");
		close(meusocket);
		close(conecta);
	}else{
		printf("Porta Fechada \n");
	}


}
