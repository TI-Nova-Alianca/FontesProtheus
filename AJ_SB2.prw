// Programa.: Aj_SB2
// Autor....: Robert Koch
// Data.....: 13/12/2016
// Descricao: Ajustes manuais SB2 para casos em que "precisa custo para transferir entre filiais agora"
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Alteracao
// #Descricao         #Ajustes manuais SB2 para casos em que "precisa custo para transferir entre filiais agora"
// #PalavasChave      #transferencia #transferencia_entre_filiais
// #TabelasPrincipais #SB2
// #Modulos           #EST #FAT
//
// Historico de alteracoes:
// 16/10/2018 - Robert  - Ajuste decimais
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop 
// 20/07/2020 - Robert  - Permissao de acesso passa a validar acesso 105 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
//
// --------------------------------------------------------------------------
user function Aj_SB2 ()
	local _oEvento   := NIL
	local _nCustoAnt := 0
	private cPerg    := "AJ_SB2"

	if ! U_ZZUVL ('105', __cUserId, .T.)
		return
	endif

	_ValidPerg()
	pergunte (cPerg, .T.)
//	do while pergunte (cPerg, .T.)
	if empty (mv_par01) .or. empty (mv_par02) .or. empty (mv_par03)
		u_help ("Todos os parametros devem ser informados.")
	else
		sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
		if ! sb2 -> (dbseek (xfilial ("SB2") + mv_par01 + mv_par02, .F.))
			u_help ("Produto / almox. nao encontrado na tabela SB2.")
		else
			_nCustoAnt = sb2 -> b2_vacustr //0

			reclock ("SB2", .F.)
			sb2 -> b2_vacustr = mv_par03
			msunlock ()
			
			_oEvento := ClsEvent ():New ()
			_oEvento:CodEven   = "SB2001"
			_oEvento:Texto     = "Custo p/transf alterado de " + cvaltochar (_nCustoAnt) + " para " + cvaltochar (mv_par03) + " no alm. " + sb2 -> b2_local
			_oEvento:Produto   = sb2 -> b2_cod
			_oEvento:Alias     = 'SB2'
			_oEvento:CodAlias  = sb2 -> b2_cod + sb2 -> b2_local
			_oEvento:Recno     = sb2 -> (recno ())
			_oEvento:Grava ()

		endif
	endif
//		if ! U_MsgYesNo ("Deseja alterar outro produto?")
//			exit
//		endif
//	enddo
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
static function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM                     DEC                     VALID F3       Opcoes Help
	aadd (_aRegsPerg, {01, "Produto                       ", "C", tamsx3 ("B2_COD")[1],   0,                      "",   "SB1  ", {},    ""})
	aadd (_aRegsPerg, {02, "Almoxarifado                  ", "C", tamsx3 ("B2_LOCAL")[1], 0,                      "",   "     ", {},    ""})
	aadd (_aRegsPerg, {03, "Custo unitario                ", "N", tamsx3 ("B2_VFIM1")[1], tamsx3 ("B2_VFIM1")[2], "",   "     ", {},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
