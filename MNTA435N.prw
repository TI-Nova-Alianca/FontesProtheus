//  Programa.: MNTA435N
//  Autor....: Andre Alves
//  Data.....: 14/02/2019
//  Descricao: PE para valida��o no Retorno Mod 2
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE para valida��o no Retorno Mod 2
// #PalavasChave      #validacao #manutencao #modelo_II #ordem_de_producao
// #TabelasPrincipais #STL #ST9
// #Modulos           #EST
//
// Historico de alteracoes:
// 24/06/2019 - Andre   - Adicionado valida��o para que teste insumos ja gravados na ordem antes de finalizar ordem.
// 18/10/2021 - Claudia - Adicionada valida��o para produtos MC. GLPI: 10765
// 27/05/2022 - Robert  - Adicionado CC 011304 para requisitar itens tipo MC (GLPI 12107)
// 05/06/2022 - Robert  - Trocados GetArea()/RestArea() por ML_SRArea() e SalvaAmb()
//                      - Varre todos os itens (antes retornava no primeiro erro)
//                      - MsgAlert() trocada por u_help()
//                      - Valida consistencias de estoque (GLPI 12133).
// 13/10/2022 - Robert  - Novos parametros funcao U_ConsEst().
// 14/07/2023 - Robert  - Valida data retroativa/futura (GLPI 13047)
//                      - Passa a chamar tambem a funcao U_VerEStq()
// 23/02/2024 - Robert  - Liberar reg. itens MC mediante senha (GLPI 14978)
//

#include 'protheus.ch'

//  ---------------------------------------------------------------------------------------------------------------------
User Function MNTA435N()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	Local cId       := PARAMIXB[1] //Indica o momento da chamada do PE
	Local aDadosOS  := {}
	Local aInsumos  := {} //Array de insumos realizados
	Local nOrdem
	Local nInsumo
	Local nPosTipReg := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_TIPOREG"})
	Local nPosDtInic := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_DTINICI"})
	Local nPosSeqD3  := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_NUMSEQ"})
	Local nPosProd   := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_CODIGO"})
	Local _nPosAlm   := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_LOCAL"})
	Local _nPosEnder := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_LOCALIZ"})
	Local _nPosLote  := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_LOTECTL"})
	Local _nPosQtd   := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_QUANTID"})
	Local nCodBem    := ''
	Local nOS        := ''
	local nCC        := ''
	local _sCC_MC    := '011404/011405/011304'
	local _lRetMN435 := .T.
	local _sAlmox    := ''
	local _sMsg      := ''
	local _sProduto  := ''
	local _sMsgCC    := ''

//	U_Log2 ('debug', '[' + procname () + ']ID de chamada: ' + cID)

	If cId == "VALID_CONFIRM"

		//Array com os dados das ordens de servi�o
		aDadosOS := ParamIXB[2]
		
		//Percorre o array de ordens
		For nOrdem := 1 To Len( aDadosOS )

			//Verifica se h� insumos realizados
			If ValType( aDadosOS[ nOrdem, 5 ] ) == "A"
				aInsumos := aClone( aDadosOS[ nOrdem, 5 ] )

				//Percorre o array de insumos realizados
				nInsumo := 1
				do while _lRetMN435 .and. nInsumo <= Len (aInsumos)

					If !aTail( aInsumos[ nInsumo ]) ; // Linha nao deletada
					.And. empty (aInsumos[ nInsumo, nPosSeqD3 ])  // Linha ainda nao gravada no SD3

						if aInsumos[ nInsumo, nPosTipReg ] == "M";       //Verifica se � insumo do tipo MDO
						.And. aInsumos[ nInsumo, nPosDtInic ] < Date() -3;  // Nao permite data menor que 3 dias da data atual

							//Apresenta para o usu�rio o n�mero da OS que h� uma inconsist�ncia
							u_help ("Ordem '" + aDadosOS[ nOrdem, 1 ] +  "': a data dos insumos tipo m�o de obra, n�o pode ser menor que tr�s dias retroativos.",, .t.)
								
							// Quando h� problema, deve retornar falso
							_lRetMN435 = .F.
						EndIf
					
						// Se for tipo [P]roduto
						If aInsumos[ nInsumo, nPosTipReg ] == "P"
							nOs := aDadosOS[ nOrdem, 1 ]
							nCodBem := fbuscacpo ("STJ",1,xFilial("STJ")+nOs, "TJ_CODBEM")
							nCC :=  fbuscacpo ("ST9",1,xFilial("ST9")+nCodBem, "T9_CCUSTO")

							if substr(nCC,1,2) != cFilAnt

								// Apresenta para o usu�rio o n�mero da OS que h� uma inconsist�ncia
								u_help ("Ordem '" + aDadosOS[ nOrdem, 1 ] +  "': o bem '" + nCodBem + "' desta manutencao nao pertence a esta filial.",, .t.)
								_lRetMN435 = .F.
							endif 

							_sProduto := aInsumos[ nInsumo, nPosProd]
							sTipo    := fbuscacpo("SB1",1,xfilial("SB1") + _sProduto,"B1_TIPO")
							nOs      := aDadosOS[ nOrdem, 1 ]
							nCodBem  := fbuscacpo("STJ",1,xFilial("STJ") + nOs, "TJ_CODBEM")
							nCC      := fbuscacpo("ST9",1,xFilial("ST9") + nCodBem, "T9_CCUSTO")

							if alltrim(sTipo) $ 'MC' .and. !(alltrim(nCC) $ _sCC_MC)
								_sMsgCC = "Produtos tipo MC devem ser lan�ados nos centros de custo '" + _sCC_MC + "'."
								
								// Alguns usuarios podem movimentar
								if ! U_ZZUVL ('157', __cUserID, .f.)
									u_help (_sMsgCC + " Liberacao somente para usuarios do grupo 157.",, .t.)
									_lRetMN435 = .F.
								else
									_lRetMN435 = U_MsgNoYes (_sMsgCC + " Confirma assim mesmo?")
								endif
							endif

							// Verifica se ha inconsistencias entre as tabelas de estoque.
							if _lRetMN435
								_sAlmox = aInsumos[ nInsumo, _nPosAlm]
							//	_lRetMN435 = U_ConsEstq (xfilial ("SD3"), _sProduto, _sAlmox, '*')
								_lRetMN435 = U_ConsEstq (xfilial ("SD3"), _sProduto, _sAlmox, '')
							endif

							// Bloqueia data retroativa e futura
							if _lRetMN435
								if aInsumos[ nInsumo, nPosDtInic ] != date () .or. dDataBase != date ()
									_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
									if U_ZZUVL ('084', __cUserId, .F.)  // Se for do grupo dos ricos, bonitos e famosos, pode movimentar.
										_lRetMN435 = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
									else
										u_help (_sMsg,, .t.)
										_lRetMN435 = .F.
									endif
								endif
							endif

							// Verifica disponibilidade de estoque.
							if _lRetMN435
								_sMsg = U_VerEstq ("4", _sProduto, '', _sAlmox, aInsumos [nInsumo, _nPosQtd], '', aInsumos [nInsumo, _nPosEnder], aInsumos [nInsumo, _nPosLote], '')
								if ! empty (_sMsg)
									u_help (_sMsg,, .t.)
									_lRetMN435 = .F.
								endif
							endif

						endif
					endif
					nInsumo ++
				enddo
			EndIf
		Next nOrdem
	EndIf

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
Return _lRetMN435
 