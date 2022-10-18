//  Programa.: MNTA435N
//  Autor....: Andre Alves
//  Data.....: 14/02/2019
//  Descricao: PE para validação no Retorno Mod 2
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE para validação no Retorno Mod 2
// #PalavasChave      #validacao #manutencao #modelo_II #ordem_de_producao
// #TabelasPrincipais #STL #ST9
// #Modulos           #EST
//
// Historico de alteracoes:
// 24/06/2019 - Andre   - Adicionado validação para que teste insumos ja gravados na ordem antes de finalizar ordem.
// 18/10/2021 - Claudia - Adicionada validação para produtos MC. GLPI: 10765
// 27/05/2022 - Robert  - Adicionado CC 011304 para requisitar itens tipo MC (GLPI 12107)
// 05/06/2022 - Robert  - Trocados GetArea()/RestArea() por ML_SRArea() e SalvaAmb()
//                      - Varre todos os itens (antes retornava no primeiro erro)
//                      - MsgAlert() trocada por u_help()
//                      - Valida consistencias de estoque (GLPI 12133).
// 13/10/2022 - Robert  - Novos parametros funcao U_ConsEst().
//

//  ---------------------------------------------------------------------------------------------------------------------

#include 'protheus.ch'

User Function MNTA435N()
//	Local aArea     := GetArea()
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
	Local nCodBem    := ''
	Local nOS        := ''
	local nCC        := ''
	local _sCC_MC    := '011404/011405/011304'
	local _lRetMN435 := .T.
	local _sAlmox    := ''

	U_Log2 ('debug', '[' + procname () + ']ID de chamada: ' + cID)

	If cId == "VALID_CONFIRM"

		//Array com os dados das ordens de serviço
		aDadosOS := ParamIXB[2]
		
		//Percorre o array de ordens
		For nOrdem := 1 To Len( aDadosOS )

			//Verifica se há insumos realizados
			If ValType( aDadosOS[ nOrdem, 5 ] ) == "A"
				aInsumos := aClone( aDadosOS[ nOrdem, 5 ] )

				//Percorre o array de insumos realizados
				nInsumo := 1
				do while _lRetMN435 .and. nInsumo <= Len (aInsumos)

					If !aTail( aInsumos[ nInsumo ]) ; // Linha nao deletada
					.And. empty (aInsumos[ nInsumo, nPosSeqD3 ])  // Linha ainda nao gravada no SD3

						if aInsumos[ nInsumo, nPosTipReg ] == "M";       //Verifica se é insumo do tipo MDO
						.And. aInsumos[ nInsumo, nPosDtInic ] < Date() -3;  // Nao permite data menor que 3 dias da data atual

							//Apresenta para o usuário o número da OS que há uma inconsistência
							u_help ("Ordem '" + aDadosOS[ nOrdem, 1 ] +  "': a data dos insumos tipo mão de obra, não pode ser menor que três dias retroativos.",, .t.)
								
							// Quando há problema, deve retornar falso
							_lRetMN435 = .F.
						EndIf
					
						// Se for tipo [P]roduto
						If aInsumos[ nInsumo, nPosTipReg ] == "P"
							nOs := aDadosOS[ nOrdem, 1 ]
							nCodBem := fbuscacpo ("STJ",1,xFilial("STJ")+nOs, "TJ_CODBEM")
							nCC :=  fbuscacpo ("ST9",1,xFilial("ST9")+nCodBem, "T9_CCUSTO")

							if substr(nCC,1,2) != cFilAnt

								// Apresenta para o usuário o número da OS que há uma inconsistência
								u_help ("Ordem '" + aDadosOS[ nOrdem, 1 ] +  "': o bem '" + nCodBem + "' desta manutencao nao pertence a esta filial.",, .t.)
								_lRetMN435 = .F.
							endif 

							sProduto := aInsumos[ nInsumo, nPosProd]
							sTipo    := fbuscacpo("SB1",1,xfilial("SB1") + sProduto,"B1_TIPO")
							nOs      := aDadosOS[ nOrdem, 1 ]
							nCodBem  := fbuscacpo("STJ",1,xFilial("STJ") + nOs, "TJ_CODBEM")
							nCC      := fbuscacpo("ST9",1,xFilial("ST9") + nCodBem, "T9_CCUSTO")

							if alltrim(sTipo) $ 'MC' .and. !(alltrim(nCC) $ _sCC_MC)
								u_help ("Produtos tipo MC devem ser lançados nos centros de custo '" + _sCC_MC + "'.",, .t.)
								_lRetMN435 = .F.
							endif

							// Verifica se ha inconsistencias entre as tabelas de estoque.
							if _lRetMN435
								_sAlmox = aInsumos[ nInsumo, _nPosAlm]
								_lRetMN435 = U_ConsEstq (xfilial ("SD3"), sProduto, _sAlmox, '*')
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
