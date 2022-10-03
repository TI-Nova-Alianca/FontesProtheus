// Programa  : MNTNG
// Autor     : Andre Alves
// Data      : 18/06/2019
// Descricao : PE para validações especificas do aplicativo MNT NG	
//
// Historico de alteracoes:
// 21/06/2019 - Andre  - Adicionado validação de datas retroativas.
// 07/04/2021 - Robert - Faltava declaracao variavel _oObjMnt (GLPI 9774)
// 09/03/2022 - Robert - Instanciava objeto oWS sempre, mas parece que paramixb[2] muda conforme o caso.
// 16/03/2022 - Robert - Filtro busca produtos mudado de tipo MM para MM e MC (GLPI 11296)
// 08/04/2022 - Robert - Criado filtro de OS conforme usuario (cada manutentor visualiza zaapenas as suas OS) - GLPI 11886
// 26/08/2022 - Robert - Criado filtro para usuario FELIPE.ESTEVES
// 02/09/2022 - Robert - Criado filtro para usuarios junior.melgarejo e joao.costa
// 05/09/2022 - Robert - Nome do Evaldo estava incorreto no filtro de OS.
// 06/09/2022 - Robert - Criado filtro para alexandre.andrade
//                     - Criada variavel unica para retorno da funcao.
// 02/10/2022 - Robert - Removido atributo :DiasDeVida da classe ClsAviso.
// 03/10/2022 - Robert - Trocado grpTI por grupo 122 no envio de avisos.
//

//  ---------------------------------------------------------------------------------------------------------------------

// https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878
#include "PROTHEUS.ch"
User Function MNTNG()
	local _xRet      := NIL
	Local _sIDdLocal := ''
	local _oObjMnt   := NIL
//	local _sRet      := ''
	local _sCodFunc  := ''
	local _oAviso    := NIL
	private _sArqLog := 'U_MNTNG.log'  // Quero usar o mesmo arquivo de log para todos os usuarios.

	_sIDdLocal := PARAMIXB[1] //Indica o momento da chamada do PE
//	U_Log2 ('debug', '[' + procname () + ']_sIDdLocal:' + cvaltochar (_sIDdLocal))

	If _sIDdLocal == "CANCEL_VALID" //valida cancelamento da ordem
		If FWJsonDeserialize(PARAMIXB[2]:GetContent(),@_oObjMnt) //Parse da string no formato Json
			If Empty(_oObjMnt:message )//verifica campo observação foi passado vazio
				_xRet = "A observação do cancelamento é obrigatória."
			EndIf
		else
			_xRet = ''
//			U_Log2 ('erro', '[' + procname () + ']_sIDdLocal:' + cvaltochar (_sIDdLocal) + ': Nao foi possivel desserializar objeto.')
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = 'Erro ao desserializar objeto _oObjMnt'
			_oAviso:Texto      = 'Nao foi possivel desserializar objeto no ponto de entrada ' + procname () + ". Mais detalhes em " + _sArqLog
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
		EndIf

	ElseIf _sIDdLocal == "FINISH_VALID_ORDER"
		If FWJsonDeserialize(PARAMIXB[2]:GetContent(), @_oObjMnt)
			If Empty(_oObjMnt:observation ) //verifica campo observação foi passado vazio
				_xRet = "Campo observação deve ser informado."
			EndIf
			if STOD(substr(_oObjMnt:startDate, 1, 8)) < date () -3 .and. STOD(substr(_oObjMnt:startDate, 1, 8)) > date () 
				_xRet = "Data inicial nao pode ser menor do que data de hoje."
			endif
			if STOD(substr(_oObjMnt:endDate, 1, 8)) < date () -3 .and. STOD(substr(_oObjMnt:endDate, 1, 8)) > date ()
				_xRet = "Data final nao pode ser menor do que data de hoje."
			endif
		else
			_xRet = ''
//			U_Log2 ('erro', '[' + procname () + ']_sIDdLocal:' + cvaltochar (_sIDdLocal) + ': Nao foi possivel desserializar objeto.')
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = 'Erro ao desserializar objeto _oObjMnt'
			_oAviso:Texto      = 'Nao foi possivel desserializar objeto no ponto de entrada ' + procname () + ". Mais detalhes em " + _sArqLog
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
		EndIf
		
	ElseIf _sIDdLocal == "FILTER_PRODUCT" //adiciona filtro para busca de produtos
		_xRet = "AND B1_TIPO IN ('MM','MC')"
	
	ElseIf _sIDdLocal == "FILTER_ORDER" // Filtro para ordens de servico
		_xRet = ''
//		U_Log2 ('debug', '[' + procname () + ']filtrando OS')
//		U_Log2 ('debug', '[' + procname () + ']cUserName: >>' + cUserName + '<<')

		// Define o codigo de funcionario (campo T1_CODFUNC) para que o usuario receba somente as OS designadas para ele.
		// Siiiim, eu sei que chumbar os nomes no fonte é deselegante, mas ainda nao tenho uma forma melhor de descobrir o codigo do funcionario.
		_sCodFunc = ''
		do case
	//	case alltrim (upper (cUserName)) $ 'EVALDO.AGNOLETO/LEONARDO.BORGES/APP.MNTNG/ELSO.RODRIGUES/MARCOS.OLIVEIRA/JONATHAN.SANTOS'
		case alltrim (upper (cUserName)) $ 'EVALDO.AGNOLETTO/LEONARDO.BORGES/APP.MNTNG/ELSO.RODRIGUES/MARCOS.OLIVEIRA/JONATHAN.SANTOS/JUNIOR.MELGAREJO/JOAO.COSTA'
			_sCodFunc = ''  // Sem filtro para estes usuarios.
		case alltrim (upper (cUserName)) = 'ALEXANDRE.ANDRADE'; _sCodFunc = '2065'
		case alltrim (upper (cUserName)) = 'ELIEL.PEDRON'     ; _sCodFunc = '2119'
		case alltrim (upper (cUserName)) = 'FABRICIO.GOMES'   ; _sCodFunc = '2010'
		case alltrim (upper (cUserName)) = 'FLAVIO.ALVES'     ; _sCodFunc = '2202'
		case alltrim (upper (cUserName)) = 'MARCOS.CORSO'     ; _sCodFunc = '1648'
		case alltrim (upper (cUserName)) = 'MARLON.SENE'      ; _sCodFunc = '2322'
		case alltrim (upper (cUserName)) = 'TAILOR.BACCA'     ; _sCodFunc = '2369'
		case alltrim (upper (cUserName)) = 'FELIPE.ESTEVES'   ; _sCodFunc = '2487'
		otherwise
//			U_AvisaTI ('[' + procname () + "]Usuario '" + cUserName + "' sem tratamento para filtrar OS.")
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = 'Erro ao desserializar objeto _oObjMnt'
			_oAviso:Texto      = "Usuario '" + cUserName + "' sem tratamento para filtrar OS no ponto de entrada " + procname () + ". Mais detalhes em " + _sArqLog
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
		endcase
		if ! empty (_sCodFunc)
			_xRet := ""
			_xRet += "AND EXISTS ("
			_xRet +=     "SELECT * FROM " + RetSQLName ("STL")
			_xRet +=     " WHERE D_E_L_E_T_ = ''"
			_xRet +=       " AND TL_FILIAL  = TJ_FILIAL"
			_xRet +=       " AND TL_ORDEM   = TJ_ORDEM"
			_xRet +=       " AND TL_CODIGO  = '" + _sCodFunc + "')"
		endif
		U_Log2 ('debug', '[' + procname () + ']Filtrando OS. _xRet = ' + _xRet)
	EndIf
Return _xRet
