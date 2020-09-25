// Programa: VA_ATUVEN
// Autor...: -
// Data....: 28/03/2014
// Funcao..: Fução de gatilho C6_produto que preenche os campos c6_prcven e c6_prcunit 
//			 com valor de tabela máximo - da1_pvunit
//
// Historico de alteracoes:
// 02/02/2015 - alteração para que busque o gatilho de tabelas apenas para se no cliente a tabela for 998 ou em branco
//            - se no cliente tiver tabela informada usa de la.
// 02/02/2015 - tirado o campo canal da chave 9 da DA1
// 08/10/2015 - Robert - Aviso de 'preco 1 centavo apenas para nao bloquear' mudado de u_help() para u_log().
// 28/01/2017 - Catia  - Composicao do preço de venda conforme percentuais do cliente - igual ao Mercanet
// 10/07/2017 - Robert - Desabilitada mensagem "valor utilizado da lista de precos por canal".
// 16/06/2020 - Claudia - Incluida validação de contrato, conforme GLPI: 8061
//
// -----------------------------------------------------------------------------------------------------------------
User Function VA_ATUVEN(_par)

	 cliente	:= M->C5_CLIENT
	 loja  		:= M->C5_LOJACLI
	 produto	:= GDFieldGet ("C6_PRODUTO")
	 contrato   := GDFieldGet ("C6_CONTRAT")
	 canal		:=''
	 estado		:=''
	 tabela     :=''
	 par		:=_par
	 continuar  := .T.
	 
	 If !empty(contrato)
	 	prcVenda   := GDFieldGet ("C6_PRCVEN")
	 	continuar  := .F.
	 EndIf
	                      
	 If continuar == .T.
		 DbSelectArea("SA1")
		 DbSetOrder(1)
		 DbSeek(xFilial()+cliente+loja) 
		 
		 If Found()	
			canal	:=SA1->A1_VACANAL
			estado	:=SA1->A1_EST 
			tabela	:=SA1->A1_TABELA
		 Endif
		 
		 If tabela = '998' .or. tabela = ''
		 
		 	prcVenda:=U_VA_PRCVEN(cliente,loja,produto,canal,estado,par)
		 Else
		 	// se ja tem a tabela correta no cadastro do cliente
		 	DbSelectArea("DA1")
			DbSetOrder(9)
			DbSeek(xFilial("DA1")+tabela+ '  '+ estado+produto) //DA1_FILIAL+DA1_CODTAB+DA1_CANAL+DA1_ESTADO+DA1_CODPRO                                                                                                           
			
			//seta em branco a ultima nota
			GDFieldPut("C6_DOC",'')
			GDFieldPut("C6_SDOC",'')
			GDFieldPut("C6_VLRNF",0)
			
			If par==1
				If IsInCallStack ("U_EDIM1")
					u_log ("Preco unitario = 1 centavo, apenas para nao bloquear a importacao do pedido")
					prcvenda = 0.01
				Else
					If tabela = '990'
						//u_help ("Preço de Venda composto, conforme parametros do cliente.")
						prcvenda:= U_CompPrc (cliente, produto, par)				
					Else
						//u_help ("Valor utilizado da Lista de Preços por Canal.")
						prcvenda:= DA1->DA1_PRCVEN
					Endif				
				Endif
			Elseif par==2
				If tabela = '990'
					prcvenda:= U_CompPrc (cliente, produto, par)				
				Else
					prcvenda:= DA1->DA1_PRCVEN
				Endif			
			Elseif par==3  .AND. GDFIELDGET("C6_VAPRCVE")==0
				If tabela = '990'
					prcvenda:= U_CompPrc (cliente, produto, par)				
				Else
					prcvenda:= DA1->DA1_PRCVEN
				Endif						
			Elseif par==3 .AND.GDFIELDGET("C6_VAPRCVE")<>0
				prcvenda:=GDFIELDGET("C6_VAPRCVE")
			Endif			
		 Endif	
	Endif 	
Return prcVenda