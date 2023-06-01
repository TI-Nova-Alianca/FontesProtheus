// Programa.:  SACI008
// Autor....:  Cláudia Lionço
// Data.....:  29/05/2023
// Descricao:  Ponto de entrada após baixa do título a receber  
// 
// Tags para automatizar catalogo de customizacoes:
// #Programa          #ponto_de_entrada
// #Descricao		  #Ponto de entrada após baixa do título a receber  
// #PalavasChave      #descontos #baixa #rapel
// #TabelasPrincipais #SE1 #SE5 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------
#Include 'Protheus.ch'
 
User Function SACI008()
    Local aArea := GetArea()
    Local aAreaE1 := SE1->(GetArea())

    If SE1->E1_TIPO == 'NCC' 
        _oCtaRapel := ClsCtaRap():New ()
		_sRede     := _oCtaRapel:RetCodRede(se1->e1_cliente, se1->e1_loja)
		_sTpRapel  := _oCtaRapel:TipoRapel(_sRede, se1->e1_loja)

		If alltrim(_sTpRapel) <> '0' .and. se5->e5_motbx == 'RAP' // Se o cliente tem configuração de rapel e for baixa rapel
			_oCtaRapel:Filial  	 = se1->e1_filial
			_oCtaRapel:Rede      = _sRede	
			_oCtaRapel:LojaRed   = se1->e1_loja
			_oCtaRapel:Cliente 	 = se1->e1_cliente
			_oCtaRapel:LojaCli	 = se1->e1_loja
			_oCtaRapel:TM      	 = '11' 	
			_oCtaRapel:Data    	 = ddatabase// date()
			_oCtaRapel:Hora    	 = time()
			_oCtaRapel:Usuario 	 = cusername 
			_oCtaRapel:Histor  	 = 'Estorno de rapel já pago pelo cliente-NCC' 
			_oCtaRapel:Documento = se1->e1_num
			_oCtaRapel:Serie 	 = se1->e1_prefixo
			_oCtaRapel:Parcela	 = se1->e1_parcela
			_oCtaRapel:Rapel	 = se5->e5_valor
			_oCtaRapel:Origem	 = 'SACI008'
			_oCtaRapel:NfEmissao = se1->e1_emissao

			If _oCtaRapel:Grava (.F.)
				_oEvento := ClsEvent():New ()
				_oEvento:Alias     = 'ZC0'
				_oEvento:Texto     = "Estorno rapel NCC "+ se1->e1_parcela + se1->e1_num + "/" + se1->e1_prefixo
				_oEvento:CodEven   = 'ZC0001'
				_oEvento:Cliente   = se1->e1_cliente
				_oEvento:LojaCli   = se1->e1_loja
				_oEvento:NFSaida   = se1->e1_num
				_oEvento:SerieSaid = se1->e1_prefixo
				_oEvento:Grava()
			EndIf
   		EndIf
    EndIf 
    RestArea(aAreaE1)
    RestArea(aArea)
Return
