// Programa.: GatCkCFO
// Autor....: Robert Koch
// Data.....: 02/04/2008
// Descricao: Gatilho campo CK_CFO para geracao do CK_CF
// 
//  #TipoDePrograma    #gatilho
//  #Descricao         #Gatilho campo CK_CFO para geracao do CK_CF
//  #PalavasChave      #Mercanet #integracao 
//  #TabelasPrincipais #SA1 
//  #Modulos 		   #FAT 
//
// Historico de alteracoes:
//
//
// --------------------------------------------------------------------------
user function GatCkCFO (_sTES)
	local _sRet := ""
	local _aDados := {}
	local _aAreaAnt := U_ML_SRArea ()
	
	if ! empty (_sTES)
		sa1 -> (dbsetorder (1))
		if ! sa1 -> (dbseek (xfilial ("SA1") + m->cj_cliente + m->cj_loja, .F.))
			u_help ("Funcao " + procname () + ": Nao encontrei cadastro do cliente!")
		else

			sf4 -> (dbsetorder (1))
			if ! sf4 -> (dbseek (xfilial ("SF4") + _sTES, .F.))
				u_help ("Funcao " + procname () + ": Nao encontrei cadastro do TES!")
			else
				
				// Preenche mnemonicos para a funcao MaFisCFO
				Aadd(_aDados, {"OPERNF"		, "S"			})
				Aadd(_aDados, {"TPCLIFOR"	, SA1->A1_TIPO	})
				Aadd(_aDados, {"UFDEST"		, SA1->A1_EST	})
				Aadd(_aDados, {"INSCR" 		, SA1->A1_INSCR	})
				_sRet := MaFisCfo(,SF4->F4_CF,_aDados)
			endif
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return _sRet
