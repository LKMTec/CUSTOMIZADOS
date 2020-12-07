CREATE OR REPLACE PACKAGE LKM_LANCTO_CTB_ONESOURCE_CPROC IS

  --Danilo Lima - 11/11/2019
  --ECF - Lançamento contábil por tipoo de documento
  
  --Parametro Standard
  FUNCTION Parametros RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION Nome RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION Tipo RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION Versao RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION Descricao RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION Modulo RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION Classificacao RETURN VARCHAR2;

  --Parametro Standard
  FUNCTION Executar(ps_empresa    varchar2,
                    Ps_Estab      varchar2,
                    ps_incl_excl  varchar2,
                    ps_dt_ini     date,
                    ps_dt_fim     date,
                    ps_tp_docto   varchar2,
                    ps_num_lancto varchar2) RETURN INTEGER;
   
    
  
  --Funcao Explode campo delimitado em tabela                       
	FUNCTION explode(delimitador IN VARCHAR2, exp_string IN VARCHAR2) RETURN lista;
   --CREATE OR REPLACE TYPE lista AS TABLE OF VARCHAR2 (255)

END LKM_LANCTO_CTB_ONESOURCE_CPROC;
/
CREATE OR REPLACE PACKAGE BODY LKM_LANCTO_CTB_ONESOURCE_CPROC IS
        mproc_id                     INTEGER;
        vt_varchar2           varchar2(10)                 := 'varchar2';
        vt_Date               varchar2(10)                 := 'Date';
        vt_text               varchar2(10)                 := 'text';
        vt_Textbox            varchar2(10)                 := 'Textbox';
        vt_S                  varchar2(10)                 := 'S';
        vt_N                  varchar2(10)                 := 'N';
        vt_DateMarcara        varchar2(10)               	:= 'dd/mm/yyyy';
        vt_Combobox           varchar2(10)               	:= 'Combobox';
        
       
        FUNCTION Parametros RETURN VARCHAR2 IS
        pstr VARCHAR2(5000);
        BEGIN

        lib_proc.add_param (
        pparam      => pstr,
        ptitulo     => lpad(' ', 32, ' ')||'ECF - Lançamento Contábil p/ Tipo de Documento',
        ptipo       => vt_varchar2,
        pcontrole   => vt_text,
        pmandatorio => vt_N
        );

        lib_proc.add_param (
        pparam      => pstr,
        ptitulo     => lpad(' ', 32, ' '),
        ptipo       => vt_varchar2,
        pcontrole   => vt_text,
        pmandatorio => vt_N
        );

        LIB_PROC.add_param(
        pparam      =>pstr,
        ptitulo     =>'Empresa',
        ptipo       =>vt_varchar2,
        pcontrole   =>vt_Combobox,
        pmandatorio => vt_S,
        pdefault    => NULL,
        pmascara    => NULL,
        pvalores    => 'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e  order by 1');

        lib_proc.add_param (
         pparam      => pstr,
         ptitulo     => lpad(' ', 32, ' '),
         ptipo       => vt_varchar2,
         pcontrole   => vt_text,
         pmandatorio => vt_N
          );

    LIB_PROC.add_param(
         pparam      => pstr,
         ptitulo     =>'Estabelecimento',
         ptipo       =>vt_varchar2,
         pcontrole   =>vt_Combobox,
         pmandatorio => vt_S,
         pdefault    =>NULL,
         pmascara    =>Null,
         pvalores    =>'SELECT DISTINCT e.cod_estab, e.cod_estab||'' - ''||e.razao_social FROM estabelecimento e where e.cod_empresa = :3 order by 1');


        lib_proc.add_param (
         pparam      => pstr,
         ptitulo     => lpad(' ', 32, ' '),
         ptipo       => vt_varchar2,
         Pcontrole   => vt_text,
         pmandatorio => vt_N    );
         
     Lib_Proc.Add_Param(pparam     =>Pstr,
                       ptitulo     => 'Gerar Arquivos para inclusão ou Exclusão',
                       ptipo       => vt_varchar2,
                       Pcontrole   => 'ListBox',
                       pmandatorio => vt_N,
                       pdefault    => 'I',
                       pmascara    => NULL,
                       pvalores    =>'I=Inclusão,' ||'E=Exclusão',
                       phabilita => vt_S);
                       
         lib_proc.add_param (
         pparam      => pstr,
         ptitulo     => lpad(' ', 32, ' '),
         ptipo       => vt_varchar2,
         Pcontrole   => vt_text,
         pmandatorio => vt_N    );                      

   LIB_PROC.ADD_PARAM(PSTR, 'Data Início', vt_Date, vt_Textbox, vt_S, null, vt_DateMarcara);

    lib_proc.add_param (
         pparam      => pstr,
         ptitulo     => lpad(' ', 32, ' '),
         ptipo       => vt_varchar2,
         pcontrole   => vt_text,
         pmandatorio => vt_N
                       );

    LIB_PROC.ADD_PARAM(PSTR, 'Data Final', vt_Date, vt_Textbox, vt_S, null, vt_DateMarcara);
        lib_proc.add_param (
        pparam      => pstr,
        ptitulo     => lpad(' ', 32, ' '),
        ptipo       => vt_varchar2,
        pcontrole   => vt_text,
        pmandatorio => vt_N
        );
        
      LIB_PROC.add_param(
        pparam      => pstr,
        ptitulo     => 'Tipo de documento',
        ptipo       => vt_varchar2,
        pcontrole   => vt_Combobox,
        pmandatorio => vt_N,
        pdefault    => NULL,
        pmascara    => NULL,
        pvalores    => 'select distinct a.cod_histpadrao, a.cod_histpadrao || '' - ''|| a.descricao from x2020_hist_padrao a, relac_tab_grupo b where a.grupo_histpadrao = b.grupo_estab and b.cod_tabela = 2020 and b.cod_empresa = :3 and b.cod_estab = :5 order by 1'
        );  
        
        lib_proc.add_param (
        pparam      => pstr,
        ptitulo     => lpad(' ', 32, ' '),
        ptipo       => vt_varchar2,
        pcontrole   => vt_text,
        pmandatorio => vt_N
        );
                
     LIB_PROC.add_param(
        pparam      => pstr,
        ptitulo     => 'Numero do Lancamento',
        ptipo       => vt_varchar2,
        pcontrole   => vt_Textbox,
        pmandatorio => vt_N,
        pdefault    => NULL,
        pmascara    => NULL,
        pvalores    => '');      

        lib_proc.add_param (
        pparam      => pstr,
        ptitulo     => lpad(' ', 32, ' '),
        ptipo       => vt_varchar2,
        pcontrole   => vt_text,
        pmandatorio => vt_N
        );

        lib_proc.add_param (
        pparam      => pstr,
        ptitulo     => lpad(' ', 48, ' ') || 'Desenvolvido por LKM Tecnologia - 2019',
        ptipo       => vt_varchar2,
        pcontrole   => vt_text,
        pmandatorio => vt_N
        );
        RETURN pstr;
        END;

        FUNCTION Nome RETURN VARCHAR2 IS
        BEGIN
        RETURN 'Integração Mastersaf DW X Onesource';
        END;

        FUNCTION Tipo RETURN VARCHAR2 IS
        BEGIN
        RETURN 'Integração';
        END;

        FUNCTION Versao RETURN VARCHAR2 IS
        BEGIN
        RETURN 'V2R01.0';
        END;

        FUNCTION Descricao RETURN VARCHAR2 IS
        BEGIN
        RETURN 'Processo customizado para carga de movimentos contábeis para Onesource ECF';
        END;

        FUNCTION Modulo RETURN VARCHAR2 IS
        BEGIN
        RETURN 'Processos Customizados';
        END;

        FUNCTION Classificacao RETURN VARCHAR2 IS
        BEGIN
        RETURN 'ECF';
        END;
        
        FUNCTION explode(delimitador IN VARCHAR2, exp_string IN VARCHAR2)
          RETURN lista AS
          l_string varchar2(10000) DEFAULT exp_string || delimitador;
          l_data   lista := lista();
          cont     NUMBER;
        BEGIN
          LOOP
            EXIT WHEN l_string IS NULL;
            cont := INSTR(l_string, delimitador);
            l_data.EXTEND;
            l_data(l_data.COUNT) := LTRIM(RTRIM(SUBSTR(l_string, 1, cont - 1)));
            l_string := SUBSTR(l_string, cont + 1);
          END LOOP;
          RETURN l_data;
        END;

        FUNCTION  Executar(ps_empresa   varchar2, Ps_Estab varchar2, ps_incl_excl varchar2,
                           ps_dt_ini date, ps_dt_fim  date, ps_tp_docto varchar2, ps_num_lancto varchar2) 
        RETURN INTEGER IS

        V_CONT              INTEGER := 0;
       -- v_periodo           varchar2(6) ;
       
       cursor c01 (ps_empresa   varchar2, Ps_Estab varchar2, ps_incl_excl varchar2,
        ps_dt_ini date, ps_dt_fim  date, ps_tp_docto varchar2, ps_num_lancto varchar2)  is
        
        
       with dados as (
               SELECT rownum as contador,
                  X01.COD_EMPRESA,--
                  X01.COD_ESTAB,--
                  X01.data_lancto, --
                  X01.VLR_LANCTO,--
                  X01.IND_DEB_CRE,--
                  X01.ARQUIVAMENTO,--
                  X01.NUM_LANCAMENTO, --
                  rownum as num_processo,
                  X01.TIPO_LANCTO, --
                  X2002.GRUPO_CONTA, 
                  X2002.COD_CONTA, --
                  X2003.GRUPO_CUSTO, 
                  X2003.COD_CUSTO,--
                  x2020_hp.cod_histpadrao,
                  NVL(X01.TXT_HISTCOMPL, X2020_HP.DESCRICAO)  as historico,
                  DSC_RESERVADO4,
                  
                  x01.ident_conta,
                  x01.ident_custo,
                  IDENT_CONTRA_PART
                  
                  
          FROM X01_CONTABIL X01 
               INNER JOIN  X2002_PLANO_CONTAS X2002           ON X01.IDENT_CONTA = X2002.IDENT_CONTA 
               LEFT JOIN X2003_CENTRO_CUSTO X2003             ON X01.IDENT_CUSTO = X2003.IDENT_CUSTO  
               
               LEFT JOIN X2020_HIST_PADRAO X2020_HP           ON X01.IDENT_HISTPADRAO = X2020_HP.IDENT_HISTPADRAO                  
         WHERE X01.cod_empresa = ps_empresa
           AND X01.cod_estab = ps_estab
           
           AND ( X01.DATA_LANCTO BETWEEN ps_dt_ini AND ps_dt_fim ) 
           and (
                        (x2020_hp.cod_histpadrao = nvl(ps_tp_docto,'0') and nvl(ps_tp_docto,'0') <> '0') 
                     or (nvl(ps_tp_docto,'0') =  '0')
                    )         
                and (
                        ( X01.num_lancamento in (SELECT COLUMN_VALUE as LINHA
                                                 FROM TABLE(LKM_LANCTO_CTB_ONESOURCE_CPROC.explode(';', ps_num_lancto))
                                                 where COLUMN_VALUE is not null
                                                 )
                         )
                     or (TRIM(nvl(ps_num_lancto,'0')) =  '0')
                    )
                    
      )
      select  a.contador
              ,a.COD_EMPRESA
              ,a.COD_ESTAB
              ,a.data_lancto
              ,a.VLR_LANCTO
              ,a.IND_DEB_CRE
              ,a.ARQUIVAMENTO
              ,a.NUM_LANCAMENTO
              ,a.num_processo
              ,TIPO_LANCTO
              ,a.GRUPO_CONTA 
              ,a.COD_CONTA
              ,a.GRUPO_CUSTO 
              ,a.COD_CUSTO
              ,X2002_CP.COD_CONTA  as CONTA_CP
              ,ESTAB.CGC as CGC
              ,a.cod_histpadrao
              ,a.historico
              ,a.DSC_RESERVADO4
      from dados a
           LEFT JOIN X2002_PLANO_CONTAS X2002_CP          ON a.IDENT_CONTRA_PART = X2002_CP.IDENT_CONTA 
           INNER JOIN  ESTABELECIMENTO  ESTAB             ON  ps_empresa = ESTAB.COD_EMPRESA 
                                                          and ps_estab   = ESTAB.COD_ESTAB 
               
           
   ;                        
       
           

        BEGIN

        mproc_id := LIB_PROC.new('LKM_LANCTO_CTB_ONESOURCE_CPROC', 48, 150);

        LIB_PROC.add_tipo(mproc_id, 2, 'Integração ECF', 2);

       -- v_periodo := TO_CHAR(ps_periodo,'YYYYMM');

        --execute immediate 'alter session set nls_language = ''BRAZILIAN PORTUGUESE'' ';
        --execute immediate 'alter session set NLS_NUMERIC_CHARACTERS = '',.''';

     --   lkm_relatorio(ps_empresa, Ps_Estab, ps_dt_ini, ps_dt_fim);
     
        LIB_PROC.add_log('Inicio do Processo: ' ||
                     to_char(sysdate, 'dd/mm/rrrr hh24:mi:ss'),
                     1);
        LIB_PROC.add_log('Empresa: ' || ps_empresa, 1);
        LIB_PROC.add_log('Estabelecimento: ' ||Ps_Estab, 1);
        LIB_PROC.add_log('Inclusão/Exclusão: ' ||ps_incl_excl, 1);
        LIB_PROC.add_log('De: ' || ps_dt_ini, 1);
        LIB_PROC.add_log('Ate: ' || ps_dt_fim, 1);
        LIB_PROC.add_log('Tipo de documento: ' || ps_tp_docto, 1);
        
        
        

        BEGIN
          
        IF (PS_TP_DOCTO IS NOT NULL OR ps_num_lancto IS NOT NULL) THEN
        
        --for lc in c_lanctos_ctb
         -- loop
            for x01 in c01 (ps_empresa, Ps_Estab, ps_incl_excl, ps_dt_ini, ps_dt_fim, ps_tp_docto, ps_num_lancto) loop
              V_CONT := V_CONT + 1;
             BEGIN 
              INSERT into tbr_int_0001 
                
                (IDT_INT_0001, -- identificador único do registro na tabela. 
                 NUM_FED_TAX, -- cnpj do estabelecimento. 
                 IND_DELETE, -- indica se o registro deverá ser excluído da base. s - sim n - não 
                 DAT_ACCOUNT_ENTRY, -- data do lançamento contábil. 
                 NUM_ACCOUNT_ENTRY, -- número do lançamento contábil. 
                 CUR_ACCOUNT_ENTRY_AMOUNT, -- valor total dos lançamentos 
                 IND_ACCOUNT_ENTRY_TYPE, -- indicador do tipo de lançamento contábil. i - inclusão n - normal e - expurgo 
                 COD_LEDGER_ACCOUNT, -- código da conta contábil. 
                 COD_COST_CENTER, -- código do centro de custo. 
                 COD_LDGR_ACCT_DBLE_ENTRY, -- código da conta contábil de contrapartida nas situações de partidas duplas. 
                 NUM_ARCHIVING, -- número de arquivamento. 
                 IND_DEBIT_CREDIT, -- indicador de débito ou crédito. preencher com: d - débito c - crédito 
                 CUR_ENTRY_AMOUNT, -- valor da partida do lançamento. 
                 NUM_PROCESS_PROTOCOL, -- número do protocolo gerado pelo processo. 
                 IND_INTEGRATION, -- indicador de status do processo de integração, podendo ser: n - não processado; b - bloqueado; p - pendente; i - integrado com sucesso; e - erros durante integração. 
                 D_LAST_UPDATE_DATE, -- data da última atualização. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                 S_LAST_UPDATE_BY, -- responsável pela última atualização. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                 D_CREATION_DATE, -- data da criação do registro. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                 S_CREATED_BY, -- criado por. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                 DSC_ADDITIONAL_HISTORICAL, 
                 S_INTEGRATION_HASH)
                 
                 values
                 
                                   
                 (null, -- identificador único do registro na tabela.
                  x01.cgc, -- NUM_FED_TAX - cnpj do estabelecimento.
                  decode(ps_incl_excl, 'I', vt_N, vt_S), -- IND_DELETE -- indica se o registro deverá ser excluído da base. s - sim n - não 
                  x01.data_lancto, -- DAT_ACCOUNT_ENTRY -- data do lançamento contábil.
                  x01.num_lancamento, -- NUM_ACCOUNT_ENTRY -- número do lançamento contábil.
                  '0', -- CUR_ACCOUNT_ENTRY_AMOUNT -- valor total dos lançamentos 
                  vt_N, -- IND_ACCOUNT_ENTRY_TYPE -- indicador do tipo de lançamento contábil. i - inclusão n - normal e - expurgo 
                  x01.cod_conta, -- COD_LEDGER_ACCOUNT, -- código da conta contábil.
                  x01.cod_custo, --COD_COST_CENTER -- código do centro de custo. 
                  x01.conta_cp, --COD_LDGR_ACCT_DBLE_ENTRY -- código da conta contábil de contrapartida nas situações de partidas duplas. 
                  x01.arquivamento, --NUM_ARCHIVING -- número de arquivamento. 
                  x01.ind_deb_cre, --IND_DEBIT_CREDIT, -- indicador de débito ou crédito. preencher com: d - débito c - crédito 
                  x01.vlr_lancto, --CUR_ENTRY_AMOUNT -- valor da partida do lançamento. 
                  x01.num_processo, -- NUM_PROCESS_PROTOCOL -- número do protocolo gerado pelo processo. 
                  vt_N, -- IND_INTEGRATION -- indicador de status do processo de integração, podendo ser: n - não processado; b - bloqueado; p - pendente; i - integrado com sucesso; e - erros durante integração. 
                  sysdate, -- data da última atualização. campo utilizado pela framework de aplicação de regras de negócio de validação.
                  null, -- S_LAST_UPDATE_BY -- responsável pela última atualização. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                  null, -- data da criação do registro. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                  null, -- criado por. campo utilizado pela framework de aplicação de regras de negócio de validação. 
                  --x01.historico, --c01.historico,  /*Alterado para pegar o campo 27*/
                  x01.dsc_reservado4, -- Campo 27
                  null);
 
           EXCEPTION 
            WHEN OTHERS THEN
              
              lib_proc.ADD_LOG('Erro na gravacao da tabela TBR_INT_0001.',NULL);
              
           END;
          end loop;  
       -- end loop;   
        
        ELSE 
            LIB_PROC.add_log('Necessario informar TIPO DE LANCAMENTO ou NUMERO DE LANCAMENTO', 1);      
        END IF;
        
        IF (V_CONT = 0) THEN
          LIB_PROC.add_log('O FILTRO UTILIZADO NAO ENCONTROU LANCAMENTOS CONTABEIS' ||V_CONT, 1);
        ELSE
          LIB_PROC.add_log('FORAM GRAVADAS '|| V_CONT||' LINHAS' , 1);
        END IF;
 
        LIB_PROC.CLOSE();
        
        END;
        
        RETURN mproc_id;
  end;
END LKM_LANCTO_CTB_ONESOURCE_CPROC;
/
