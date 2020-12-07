CREATE OR REPLACE PACKAGE LKM_APTRIB_CPROC IS
  --=================================================================================================
   -- Purpose       : Geracao de arquivo TXT, para upload no SAP - AP-TRIB
  -- Requester     : LKM Tecnologia
  --
  --=================================================================================================

  TYPE T_VEN_RECORD IS RECORD(
    CONTEUDO VARCHAR2(255),
    VALOR    VARCHAR2(255));

  TYPE T_VEN_TABLE IS TABLE OF T_VEN_RECORD;

  TYPE T_TIPO_RECORD IS RECORD(
    TIPO VARCHAR2(255));

  TYPE T_TIPO_TABLE IS TABLE OF T_TIPO_RECORD;

  TYPE T_FERIADO_CONT IS RECORD(
    contador INT);

  TYPE T_FERIADO_CONT_TABLE IS TABLE OF T_FERIADO_CONT;
  
  
  TYPE T_CODPGTO_RECORD IS RECORD(
    IMP_EMP_ESTAB VARCHAR2(20),
    codigo    VARCHAR2(6),
    cod_empresa    VARCHAR2(6),
    cod_estab    VARCHAR2(6)
    
    );
    
    TYPE T_CODPGTO_TABLE IS TABLE OF T_CODPGTO_RECORD;

  --=================================================================================================

  TYPE T_FB60 IS RECORD(
    bukrs                   VARCHAR2(255), --1
    branch                  VARCHAR2(255), --2
    gsber                   VARCHAR2(255), --3
    fatger                  VARCHAR2(255), --4
    budat                   VARCHAR2(255), --5
    codrec                  VARCHAR2(255), --6
    cnpj_cpf                VARCHAR2(255), --7
    xblnr                   VARCHAR2(255), --8
    vlrtrib                 VARCHAR2(255), --9
    aliq                    VARCHAR2(255), --10
    vlret                   VARCHAR2(255), --11
    vecto                   VARCHAR2(255), --12
    dmbtr                   VARCHAR2(255), --13
    wrbtr                   VARCHAR2(255), --14
    vlrcorr                 VARCHAR2(255), --15
    txjcd                   VARCHAR2(255), --16
    stcd3                   VARCHAR2(255), --17
    estado                  VARCHAR2(255), --18
    dat_end_clc_op_calction VARCHAR2(255) --19
    );

  CURSOR c_lkm_fb60 is
    select distinct null as BUKRS,
                    null as BRANCH,
                    null as GSBER,
                    null as FATGER,
                    null as BUDAT,
                    null as CODREC,
                    null as CNPJ_CPF,
                    null as XBLNR,
                    null as VLRTRIB,
                    null as ALIQ,
                    null as VLRET,
                    null as VECTO,
                    null as STCD3,
                    null as TXJCD,
                    null as DMBTR,
                    null as WRBTR,
                    null as VLRCORR
    
      from dual;

  mproc_id          integer;
  mLinha            varchar2(5000);
  v_pagto           varchar2(10);
  v_contador        integer := 0;
  v_bukrs           varchar2(4);
  v_GSBER           varchar2(4);
  v_validacao       integer := 0;
  v_datavencto      varchar2(8);
  v_cod_receita_icm varchar2(6) ;
  v_cod_estab       varchar2(4);
  v_perfil          varchar2(100); --003
  --006 inicio
  mLinha2     varchar2(5000);
  mLinha3     varchar2(5000);
  wEmpresa    empresa%rowtype;
  wEtab       estabelecimento%rowtype;
  v_erroSql   varchar2(500);
  v_MsgErro   varchar2(500) := '@';
  vDatIniProc date := sysdate;
  vCol01      number := 4; --'EMPRESA - SAP'
  vCol02      number := 14; --'CPF/CGC'
  vCol03      number := 4; --'ESTAB - SAP'
  vCol04      number := 10; --'DATA FATO GERADOR'
  vCol05      number := 7; --'COD. RECEITA'
  vCol06      number := 14; --'VALOR IMPOSTO'
  vCol07      number := 10; --'VENCIMENTO'
  vCol08      number := 14; --'VALOR DA MULTA'
  vCol09      number := 14; --'VALOR DE JUROS'
  vCol010     number := 14; --'VALOR TOTAL'
  vCol011     number := 10; --'DOMICILIO FISCAL'
  sep         varchar2(3) := ' | ';
  a           number;
  --006 fim
  
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
  
  --Retorna se uma data é um feriado
  FUNCTION fn_feriado(d in VARCHAR2, p_perfil VARCHAR2) RETURN integer;
  
  --Retona ultimo dia util
  FUNCTION fn_ultimo_dia_util(dt_base in date, p_perfil VARCHAR2) RETURN date;
  
  -- Formata numero
  function numFormat(vNumero in number) return varchar2;

  --Chamada Principal do processo customizado
  FUNCTION Executar(p_emp    VARCHAR2,
                    p_dtini  DATE,
                    p_dtfim  DATE,
                    p_opcao  LIB_PROC.varTab,
                    p_perfil VARCHAR2,
                    p_dEntrada  DATE,
                    p_dLanc     DATE
                    ) RETURN INTEGER;
                    
                    
  -- Retorna uma dabela com os parametros de Vencimento
  FUNCTION FN_VENCIMENTO RETURN T_VEN_TABLE
    PIPELINED;

 
  -- Retorna o Tipo de Consulta
  FUNCTION FN_TIPO RETURN T_TIPO_TABLE
    PIPELINED;

  -- Retorna a tabela de feriados
  FUNCTION FN_FERIADO_CONT RETURN T_FERIADO_CONT_TABLE
    PIPELINED;
    
  -- Retorna o tipo de impostos 
  FUNCTION FN_TIPO_IMP RETURN T_TIPO_TABLE
    PIPELINED;
    
  -- Retorna o Codigo de Pagamento  
  FUNCTION FN_COGPGTO RETURN T_CODPGTO_TABLE
    PIPELINED;

END LKM_APTRIB_CPROC;
/
CREATE OR REPLACE PACKAGE BODY LKM_APTRIB_CPROC IS

  MCOD_EMPRESA EMPRESA.COD_EMPRESA%TYPE; --014
  
  vt_varchar2           varchar2(10)               	:= 'varchar2';
  vt_Date               varchar2(10)               	:= 'Date';
  vt_text               varchar2(10)               	:= 'text';
  vt_Textbox            varchar2(10)               	:= 'Textbox';
  vt_S                  varchar2(10)               	:= 'S';
  vt_N                  varchar2(10)               	:= 'N';
  vt_DateMarcara        varchar2(10)               	:= 'dd/mm/yyyy';
  vt_DateMarcara2       varchar2(10)                := 'DDMMYYYY';
  vt_DateMarcara3       varchar2(10)                := 'MMYYYY';
  vt_DateMarcara4       varchar2(10)                := 'MM.YYYY';
  
  vt_Combobox           varchar2(10)               	:= 'Combobox';
  vt_apTrib             varchar2(10)                := 'AP-TRIB';
  vt_FERIADO            varchar2(10)                := 'FERIADO';
  vt_REGEXP1            varchar2(10)                := '[^-]+';
  vt_numeroMascara      varchar2(50)                := '99999999999.99';
  vt_ponto              varchar2(10)                := '.';
  vt_Todas              varchar2(10)                := 'TODAS';
  
  vt_ISSFAT             varchar2(10)                := 'ISSFAT';
  vt_ISSRET             varchar2(10)                := 'ISSRET';
  vt_COFINS             varchar2(10)                := 'COFINS';
  vt_PIS                varchar2(10)                := 'PIS';
  vt_INSS               varchar2(10)                := 'INSS';
  vt_PCC                varchar2(10)                := 'PCC';
  vt_IRRF               varchar2(10)                := 'IRRF';
  vt_DEPARA_EMP         varchar2(10)                := 'DEPARA_EMP';
  vt_MSG_ERRO_DP        varchar2(255)               := 'ERRO: Realizar DE x PARA da Empresa selecionada.';
  vt_DEPARA_ESTAB       varchar2(255)               := 'DEPARA_ESTAB';
  vt_COD_DARF_IRPJ_CSLL varchar2(255)               := 'COD_DARF_IRPJ_CSLL';
  
   --010 inicio
  function centralizar(pTexto in varchar2,
                       pQtd   in number,
                       pPree  in varchar2 default '-') return varchar2 is
    Result varchar2(2000);
  begin
    if mod(pQtd, 2) = 0 then
      Result := rpad(lpad(pTexto,
                          trunc(pQtd / 2) + trunc(length(pTexto) / 2),
                          pPree),
                     pQtd,
                     pPree);
    else
      Result := rpad(lpad(pTexto,
                          trunc(pQtd / 2) + 1 + trunc(length(pTexto) / 2),
                          pPree),
                     pQtd,
                     pPree);
    end if;
    return(Result);
  end centralizar;

  function numFormat(vNumero in number) return varchar2 is
    Result varchar2(100);
  begin
    Result := replace(replace(replace(to_char(vNumero, '9,999,990.99'),
                                      vt_ponto,
                                      '*'),
                              ',',
                              vt_ponto),
                      '*',
                      ',');
    return(Result);
  end numFormat;
  --010 fim

  
  FUNCTION Parametros RETURN VARCHAR2 IS
  --Parametro Standard
    pstr VARCHAR2(32767);
    
    
  BEGIN
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => 'AP-TRIB - Automação de Pagamentos',
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => lpad(' ', 32, ' '),
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
  
    lib_proc.add_param(pstr,
                       'Empresa',
                       vt_varchar2,
                       vt_Combobox,
                       vt_S,
                       NULL,
                       null,
                       'select cod_empresa, razao_social from ('
                       ||'         select '||vt_Todas||' cod_empresa, ''Todas as Empresas'' razao_social from dual union all'
                       ||'         select distinct emp.cod_empresa, emp.cod_empresa || '' - '' || emp.razao_social razao_social'
                       ||'           FROM empresa emp)'
                       ||'          order by decode(cod_empresa, '||vt_Todas||', '||vt_ponto||', cod_empresa)'
                       );
    --014 fim
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => lpad(' ', 32, ' '),
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
  
    LIB_PROC.add_param(pstr,
                       'Data inicial do Fato Gerador',
                       vt_Date,
                       vt_Textbox,
                       vt_S,
                       '01/01/2020',
                       --' dd/mm/yyyy ');
                       vt_DateMarcara); --013
  
    LIB_PROC.add_param(pstr,
                       'Data Final do Fato Gerador',
                       vt_Date,
                       vt_Textbox,
                       vt_S,
                       '31/01/2020',
                       --' dd/mm/yyyy ');
                       vt_DateMarcara); --013
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => lpad(' ', 32, ' '),
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => 'Selecione o pagamento: ',
                       ptipo       => vt_varchar2,
                       pcontrole   => 'MULTISELECT',
                       pmandatorio => vt_N,
                       pvalores => 'select '''||vt_ISSRET||'''   codigo, '''||vt_ISSRET||'''   descricao from dual union all'
                                   ||' select '''||vt_ISSFAT||'''   codigo, '''||vt_ISSFAT||'''   descricao from dual union all'
                                   ||'      select '''||vt_PCC||'''     codigo, '''||vt_PCC||'''     descricao from dual union all'
                                   ||'      select '''||vt_INSS||'''    codigo, '''||vt_INSS||'''    descricao from dual union all'
                                   ||'      select ''IR''      codigo, ''IR''      descricao from dual union all'
                                   ||'      select ''PIS_COFINS'' codigo, ''PIS_COFINS'' descricao from dual'
                       );
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => lpad(' ', 32, ' '),
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
  
    LIB_PROC.add_param(pstr,
                       'Perfil',
                       vt_varchar2,
                       vt_Combobox,
                       vt_S,
                       NULL,
                       NULL,
                       'select id_parametros codigo,descricao from fpar_parametros where nome_framework like ''%LKM_APTRIB_CPAR%'' ');
  
  
    LIB_PROC.add_param(pstr,
                       'Data de entrada',
                       vt_Date,
                       vt_Textbox,
                       vt_S,
                       last_day(trunc(sysdate)),
                       --' dd/mm/yyyy ');
                       vt_DateMarcara);
    
    LIB_PROC.add_param(pstr,
                       'Data do Lancamento',
                       vt_Date,
                       vt_Textbox,
                       vt_S,
                       last_day(trunc(sysdate)),
                       --' dd/mm/yyyy ');
                       vt_DateMarcara);
                       
                       
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => lpad(' ', 32, ' '),
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
  
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => lpad(' ', 32, ' '),
                       ptipo       => vt_varchar2,
                       pcontrole   => vt_text,
                       pmandatorio => vt_N);
    RETURN pstr;
  
  END;
  
   
  FUNCTION Nome RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN vt_apTrib;
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN vt_apTrib;
  END;
  
  FUNCTION Versao RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN 'V1';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  --Parametro Standard  
  BEGIN
    RETURN 'Automação de pagamentos de tributos municipais, estaduais e federais';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN vt_apTrib;
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION fn_feriado(d in VARCHAR2, p_perfil VARCHAR2) RETURN integer AS
  --Parametro que retorna se a data é um feriado
    x integer;
  
  BEGIN
  
    SELECT count(*)
      INTO x
      FROM fpar_param_det a
     WHERE to_char(a.id_parametro) = p_perfil
       and a.nome_param = vt_FERIADO
       and a.valor = d;
  
    IF (x >= 1) THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  
  END;

  FUNCTION fn_ultimo_dia_util(dt_base in date, p_perfil VARCHAR2) RETURN date AS
  --Retorna Dia Util
    dt_basex date;
    bo_fimx  boolean;
  
  BEGIN
  
    dt_basex := dt_base;
    bo_fimx  := false;
  
    WHILE NOT (bo_fimx) LOOP
    
      bo_fimx := to_char(dt_basex, 'd') NOT IN ('1', '7');
    
      IF fn_feriado(dt_basex, p_perfil) = 1 THEN
        bo_fimx := false;
      END IF;
    
      IF NOT (bo_fimx) THEN
        dt_basex := dt_basex - 1;
      END IF;
    
    END LOOP;
  
    RETURN dt_basex;
  
  EXCEPTION
  
    WHEN others THEN
      ROLLBACK;
    
  END;

  FUNCTION Executar(p_emp    VARCHAR2,
                    p_dtini  DATE,
                    p_dtfim  DATE,
                    p_opcao  LIB_PROC.varTab,
                    p_perfil VARCHAR2,
                    p_dEntrada  DATE,
                    p_dLanc     DATE) RETURN INTEGER IS
   -- Funcao principal
    
    fb60Record   T_FB60;
    CUR1         SYs_REFCURSOR;
    v_count int;
    v_codigo VARCHAR2(255);
    v_contaLinhas int;
    v_desc_HEADER_TXT varchar2(255);
    mHeader     varchar2(5000);
    mDebito     varchar2(5000);
    mCredito    varchar2(5000);
    vImp        varchar2(10);
    vContaDeb   varchar2(15);
    vContaCre   varchar2(15);
    vCostCenter varchar2(15);
    vCostLucro varchar2(15);
    vCustomer   VARCHAR2(50);
    vVendor     VARCHAR2(50);
    vHeader1    varchar2(5000);
    vHeader2    varchar2(5000);
    vHeader3    varchar2(5000);
    vHeader4    varchar2(5000);
    mLinhaH     varchar2(5000);
    i PLS_INTEGER;
 BEGIN
   mproc_id     := LIB_PROC.new('LKM_APTRIB_CPROC', 48, 150);
    MCOD_EMPRESA := LIB_PARAMETROS.RECUPERAR('EMPRESA');
  
    Begin
      select Razao_social, cnpj
        into wEmpresa.razao_social, wEmpresa.Cnpj
        from empresa
       where cod_empresa = p_emp;
    exception
      when others then
        wEmpresa.razao_social := 'Todas Empresas' --'Nao Identificada' --014
         ;
    end;
    
    -- Estabelecimento
    begin
      select e.cod_estab,
             e.razao_social,
             e.cgc,
             x.DESCRICAO,
             e.cod_municipio,
             e.ident_estado
        into wEtab.Cod_Estab,
             wEtab.Nome_Fantasia,
             wEtab.Cgc,
             wEtab.Cidade,
             wEtab.Cod_Municipio,
             wEtab.Ident_Estado
        from estabelecimento e, municipio x
       where e.cod_empresa = p_emp
         and x.ident_estado = e.ident_estado
         and x.cod_municipio = e.cod_municipio;
    exception
      when others then
        wEtab.Cod_Estab     := 'Todos';
        wEtab.Nome_Fantasia := 'Estabelecimentos';
        wEtab.Cgc           := ' ';
    end;
   
    lib_proc.add_tipo(mproc_id, 1, 'APTRIB.TXT', 2);
    lib_proc.add_tipo(mproc_id, 2, 'Relatorio Conferência', 1); --009
  
    --inicio
    begin
      select distinct descricao
        into v_perfil
        from fpar_parametros
       where id_parametros = p_perfil;
    exception
      when others then
        v_perfil := NULL;
    end;
  
    LIB_PROC.Add_Log('Empresa: ' || p_emp || ' Data Inicial: ' || p_dtini ||
                     ' Data Final: ' || p_dtfim || ' Perfil: ' || v_perfil ||
                     ' - ' || p_perfil,
                     1);
  
    select count(*)
      into v_count
      from user_objects a
     where a.OBJECT_NAME = 'TBR_CLC_OP_CALCTION';
  
    --inicia a execucao caso nao haja erros
    if (v_validacao = 0) then
      begin
      
        a := 2;
        LIB_PROC.add_header(rpad('-', 138, '-'), NULL, a);
        LIB_PROC.add_header(lpad('AUTOMAÇÃO DO PAGAMENTO DE TRIBUTOS',
                                 85,
                                 ' '),
                            NULL,
                            a);
        LIB_PROC.add_header('-  Empresa: ' || p_emp || ' - ' ||
                            wEmpresa.razao_social,
                            NULL,
                            a);
        LIB_PROC.add_header('-  Estabelecimento: ' || wEtab.Cod_Estab ||
                            ' - ' || wEtab.Nome_Fantasia,
                            NULL,
                            a);
        LIB_PROC.add_header(rpad('-', 188, '-'), NULL, a);
      
        LIB_PROC.add_header(centralizar('EMPRESA', vCol01, ' ') || sep ||
                            centralizar('CNPJ', vCol02, ' ') || sep ||
                            centralizar('FILIAL', vCol03, ' ') || sep ||
                            centralizar('COMPETENCIA', vCol04, ' ') || sep ||
                            centralizar('COD REC', vCol05, ' ') || sep ||
                            centralizar('VALOR IMPOSTO', vCol06, ' ') || sep ||
                            centralizar('VENCIMENTO', vCol07, ' ') || sep ||
                            centralizar('VALOR DA MULTA', vCol08, ' ') || sep ||
                            centralizar('VALOR DE JUROS', vCol09, ' ') || sep ||
                            centralizar('VALOR TOTAL', vCol010, ' ') || sep ||
                            centralizar('DOMICILIO FISCAL', vCol011, ' ') || sep,
                            NULL,
                            a);
        LIB_PROC.add_header(rpad('-', 188, '-'), NULL, a);
      
        LIB_PROC.add_footer(rpad('-', 157, '-'), NULL, a);
        LIB_PROC.add_footer('Emitido em: ' ||
                            to_char(SYSDATE, 'DD/MM/YYYY HH:MI'),
                            NULL,
                            a);
        
        v_contaLinhas := 1;
        
        i := p_opcao.FIRST;
        
        --MAIN Header INICIO
        vHeader1 :=  'Header ( Date in Format yyyy/MM/dd or dd/MM/yyyy )'	|| CHR(9) -- COUNT              01
                           ||null                                         || CHR(9) -- COMP_CODE          02
                           ||null                                         || CHR(9) -- DOC_TYPE           03
                           ||null                                         || CHR(9) -- DOC_DATE           04
                           ||null                                         || CHR(9) -- PSTNG_DATE         05
                           ||null                                         || CHR(9) -- HEADER_TXT         06
                           ||null                                         || CHR(9) -- CURRENCY           07
                           ||null                                         || CHR(9)  -- EXCH_RATE         08
                           ||null                                         || CHR(9) -- TRANS_DATE         09
                           ||null                                         || CHR(9) -- REF_DOC_NO         10
                           ||null                                         || CHR(9) -- REF_KEY_3          11
                                     
                           ||'Line Items'                                 || CHR(9) --GL_ACCOUNT           12
                           ||null                                         || CHR(9) --CUSTOMER             13
                           ||null                                         || CHR(9) --VENDOR_NO            14
                           ||null                                         || CHR(9) --ITEM_TEXT            15
                           ||null                                         || CHR(9) --AMT_DOCCUR_D         16
                           ||null                                         || CHR(9) --AMT_DOCCUR_C         17
                           ||null                                         || CHR(9) --TAX_CODE             18
                           ||null                                         || CHR(9) --PMNTTRMS             19
                           ||null                                         || CHR(9) --COSTCENTER           20
                           ||null                                         || CHR(9) --PROFIT_CTR           21
                           ||null                                         || CHR(9) --ORDERID              22
                           ||null                                         || CHR(9) --WBS_ELEMENT          23
                           ||null                                         || CHR(9) --ALLOC_NMBR           24
                           ||null                                         || CHR(9) --TRADE_ID             25
                           ||null                                         || CHR(9) --FUNC_AREA            26
                           ||null                                         || CHR(9) --VALUE_DATE           27
                           ||null                                         || CHR(9) --PYMT_METH            28
                           ||null                                         --|| CHR(9) --BLINE_DATE           29
                           --||null                                                   --REF_KEY_3            30
                           ;
                                     
         vHeader2 :=       'COUNT'	                                      || CHR(9) -- COUNT              01
                           ||'COMP_CODE'                                  || CHR(9) -- COMP_CODE          02
                           ||'DOC_TYPE'                                   || CHR(9) -- DOC_TYPE           03
                           ||'DOC_DATE'                                   || CHR(9) -- DOC_DATE           04
                           ||'PSTNG_DATE'                                 || CHR(9) -- PSTNG_DATE         05
                           ||'HEADER_TXT'                                 || CHR(9) -- HEADER_TXT         06
                           ||'CURRENCY'                                   || CHR(9) -- CURRENCY           07
                           ||'EXCH_RATE'                                  || CHR(9)  -- EXCH_RATE         08
                           ||'TRANS_DATE'                                 || CHR(9) -- TRANS_DATE         09
                           ||'REF_DOC_NO'                                 || CHR(9) -- REF_DOC_NO         10
                           ||'REF_KEY_3'                                  || CHR(9) -- REF_KEY_3          11
                                     
                           ||'GL_ACCOUNT'                                 || CHR(9) --GL_ACCOUNT           12
                           ||'CUSTOMER'                                   || CHR(9) --CUSTOMER             13
                           ||'VENDOR_NO'                                  || CHR(9) --VENDOR_NO            14
                           ||'ITEM_TEXT'                                  || CHR(9) --ITEM_TEXT            15
                           ||'AMT_DOCCUR_D'                               || CHR(9) --AMT_DOCCUR_D         16
                           ||'AMT_DOCCUR_C'                               || CHR(9) --AMT_DOCCUR_C         17
                           ||'TAX_CODE'                                   || CHR(9) --TAX_CODE             18
                           ||'PMNTTRMS'                                   || CHR(9) --PMNTTRMS             19
                           ||'COSTCENTER'                                 || CHR(9) --COSTCENTER           20
                           ||'PROFIT_CTR'                                 || CHR(9) --PROFIT_CTR           21
                           ||'ORDERID'                                    || CHR(9) --ORDERID              22
                           ||'WBS_ELEMENT'                                || CHR(9) --WBS_ELEMENT          23
                           ||'ALLOC_NMBR'                                 || CHR(9) --ALLOC_NMBR           24
                           ||'TRADE_ID'                                   || CHR(9) --TRADE_ID             25
                           ||'FUNC_AREA'                                  || CHR(9) --FUNC_AREA            26
                           ||'VALUE_DATE'                                 || CHR(9) --VALUE_DATE           27
                           ||'PYMT_METH'                                  || CHR(9) --PYMT_METH            28
                           ||'BLINE_DATE'                                 --|| CHR(9) --BLINE_DATE           29
                           --||'REF_KEY_3'                                            --REF_KEY_3            30
                           ;
                                     
        vHeader3 :=  'INT4'	|| CHR(9) -- COUNT              01
                           ||'BUKRS'                                         || CHR(9) -- COMP_CODE          02
                           ||'BLART'                                         || CHR(9) -- DOC_TYPE           03
                           ||'BLDAT'                                         || CHR(9) -- DOC_DATE           04
                           ||'BUDAT'                                         || CHR(9) -- PSTNG_DATE         05
                           ||'BKTXT'                                         || CHR(9) -- HEADER_TXT         06
                           ||'WAERS'                                         || CHR(9) -- CURRENCY           07
                           ||'KURSF'                                         || CHR(9)  -- EXCH_RATE         08
                           ||'WWERT_D'                                       || CHR(9) -- TRANS_DATE         09
                           ||'XBLNR'                                         || CHR(9) -- REF_DOC_NO         10
                           ||'XREF3'                                         || CHR(9) -- REF_KEY_3          11
                                     
                           ||'HKONT'                                         || CHR(9) --GL_ACCOUNT           12
                           ||'KUNNR'                                         || CHR(9) --CUSTOMER             13
                           ||'LIFNR'                                         || CHR(9) --VENDOR_NO            14
                           ||'SGTXT'                                         || CHR(9) --ITEM_TEXT            15
                           ||'BAPIWRBTR'                                     || CHR(9) --AMT_DOCCUR_D         16
                           ||'BAPIWRBTR'                                     || CHR(9) --AMT_DOCCUR_C         17
                           ||'MWSKZ'                                         || CHR(9) --TAX_CODE             18
                           ||'ACPI_ZTERM'                                    || CHR(9) --PMNTTRMS             19
                           ||'KOSTL'                                         || CHR(9) --COSTCENTER           20
                           ||'PRCTR'                                         || CHR(9) --PROFIT_CTR           21
                           ||'AUFNR'                                         || CHR(9) --ORDERID              22
                           ||'PS_POSID'                                      || CHR(9) --WBS_ELEMENT          23
                           ||'ACPI_ZUONR'                                    || CHR(9) --ALLOC_NMBR           24
                           ||'RASSC'                                         || CHR(9) --TRADE_ID             25
                           ||'FKBER_SHORT'                                   || CHR(9) --FUNC_AREA            26
                           ||'VALUT'                                         || CHR(9) --VALUE_DATE           27
                           ||'ACPI_ZLSCH'                                    || CHR(9) --PYMT_METH            28
                           ||'ACPI_ZFBDT'                                    --|| CHR(9) --BLINE_DATE           29
                           --||'XREF3'                                                   --REF_KEY_3            30
                           ;
                                     
        vHeader4 :=  '*Counter (10)'	                                       || CHR(9) -- COUNT              01
                           ||'*Company Code (4)'                             || CHR(9) -- COMP_CODE          02
                           ||'*Journal Entry Type (2)'                       || CHR(9) -- DOC_TYPE           03
                           ||'*Journal Entry Date'                           || CHR(9) -- DOC_DATE           04
                           ||'*Posting Date'                                 || CHR(9) -- PSTNG_DATE         05
                           ||'Document Header Text (25)'                     || CHR(9) -- HEADER_TXT         06
                           ||'*Transaction Currency (5)'                     || CHR(9) -- CURRENCY           07
                           ||'Exchange Rate (12)'                            || CHR(9)  -- EXCH_RATE         08
                           ||'Currency Translation Date'                     || CHR(9) -- TRANS_DATE         09
                           ||'Reference Document Number (16)'                || CHR(9) -- REF_DOC_NO         10
                           ||'Ref Key 3'                                     || CHR(9) -- REF_KEY_3          11
                                     
                           ||'G/L Account (10)'                              || CHR(9) --GL_ACCOUNT           12
                           ||'Customer'                                      || CHR(9) --CUSTOMER             13
                           ||'Supplier'                                      || CHR(9) --VENDOR_NO            14
                           ||'Item Text (50)'                                || CHR(9) --ITEM_TEXT            15
                           ||'Debit Amount in Transaction Currency'          || CHR(9) --AMT_DOCCUR_D         16
                           ||'Credit Amount in Transaction Currency'         || CHR(9) --AMT_DOCCUR_C         17
                           ||'Tax Code (2)'                                  || CHR(9) --TAX_CODE             18
                           ||'Payment term'                                  || CHR(9) --PMNTTRMS             19
                           ||'Cost Center (10)'                              || CHR(9) --COSTCENTER           20
                           ||'Profit Center (10)'                            || CHR(9) --PROFIT_CTR           21
                           ||'Order Number (12)'                             || CHR(9) --ORDERID              22
                           ||'WBS Element (24)'                              || CHR(9) --WBS_ELEMENT          23
                           ||'Assignment number (18)'                        || CHR(9) --ALLOC_NMBR           24
                           ||'Trading Partner (6)'                           || CHR(9) --TRADE_ID             25
                           ||'Functional Area (4)'                           || CHR(9) --FUNC_AREA            26
                           ||'Value Date'                                    || CHR(9) --VALUE_DATE           27
                           ||'Payment Method (1)'                            || CHR(9) --PYMT_METH            28
                           ||'Baseline Date'                                 --|| CHR(9) --BLINE_DATE           29
                           --||'Ref Key 3'                                               --REF_KEY_3            30
                           ;
                  
        --MAIN Header FIM
                  
                  
         mLinhaH := null;
         mLinhaH := LIB_STR.w(mLinhaH    , vHeader1,1);
         LIB_PROC.add(mLinhaH);
                    
         mLinhaH := null;
         mLinhaH := LIB_STR.w(mLinhaH    , vHeader2,1);
         LIB_PROC.add(mLinhaH);
                    
         mLinhaH := null;
         mLinhaH := LIB_STR.w(mLinhaH    , vHeader3,1);
         LIB_PROC.add(mLinhaH);
                    
         mLinhaH := null;
         mLinhaH := LIB_STR.w(mLinhaH    , vHeader4,1);
         LIB_PROC.add(mLinhaH);
             
                  
                  
        
        WHILE (i IS NOT NULL) loop
          begin
            v_pagto     := p_opcao(i);
            v_contador  := 0;
            v_cod_estab := NULL;
            v_validacao := 0;
          
            if (v_pagto <> 'IRPJ_CSLL' or v_count > 0) then
            
             
              if (v_pagto = vt_PCC) then
                begin
                  open CUR1 for 
                       select distinct e.cod_empresa                                                         as BUKRS,
                                substr(d.cnpj, 1, 16)                                                        as BRANCH,
                                e.cod_estab                                                                  as GSBER,
                                to_char(e.data_apuracao, vt_DateMarcara2)                                         as FATGER,
                                nvl(to_char(e.data_apuracao, vt_DateMarcara2), ' ')                               as BUDAT,
                                substr(c.cod_darf, 1, 6)                                                     as CODREC,
                                ' '                                                                          as CNPJ_CPF,
                                ' '                                                                          as XBLNR,
                                trim(replace(replace(to_char(e.vlr_base, vt_numeroMascara),
                                                     '.',
                                                     null),
                                             ',',
                                             ''))                                                            as VLRTRIB,
                                trim(replace(replace(to_char(decode(e.aliq_tributo,
                                                                    0,
                                                                    4.6500,
                                                                    e.aliq_tributo),
                                                             vt_numeroMascara),
                                                     '.',
                                                     null),
                                             ',',
                                             ''))                                                           as ALIQ,
                                trim(replace(replace(to_char(e.vlr_principal,
                                                             vt_numeroMascara),
                                                     '.',
                                                     null),
                                             ',',
                                             ''))                                                           as VLRET,
                                to_char(e.data_vencto, vt_DateMarcara2)                                     as VECTO,
                                trim(replace(replace(to_char(e.vlr_multa, vt_numeroMascara),
                                                     '.',
                                                     null),
                                             ',',
                                             ''))                                                           as DMBTR,
                                trim(replace(replace(to_char(e.vlr_juros, vt_numeroMascara),
                                                     '.',
                                                     null),
                                             ',',
                                             ''))                                                           as WRBTR,
                                trim(replace(replace(to_char(e.vlr_total, vt_numeroMascara),
                                                     '.',
                                                     null),
                                             ',',
                                             ''))                                                           as VLRCORR,
                                ' '                                                                         as TXJCD,
                                substr(replace(replace(replace(f.insc_municipal, '.', ''),
                                                       ',',
                                                       ''),
                                               '-',
                                               ''),
                                       1,
                                       18)                                                                  as STCD3,
                                ' '                                                                         as cod_estado,
                                ''                                                                          as dat_end_clc_op_calction
                      from x2019_cod_darf c
                           , empresa d
                           , x75_dctf e
                           , estabelecimento f
                     where 1 = 1
                       and e.ident_darf = c.ident_darf
                       and e.cod_empresa = d.cod_empresa
                       and e.cod_empresa = f.cod_empresa
                       and e.cod_estab = f.cod_estab
                       and c.cod_darf in (select conteudo
                                            from fpar_param_det
                                           where id_parametro = p_perfil
                                             and nome_param = 'COD_DARF_PCC')
                       and e.cod_empresa = decode('p_emp', vt_Todas, e.cod_empresa, p_emp)
                       and to_date(e.data_apuracao, vt_DateMarcara) between
                           to_date(p_dtini, vt_DateMarcara) and
                           to_date(p_dtfim, vt_DateMarcara);
                  end;
                
              elsif (v_pagto = vt_ISSFAT) then
                begin
                  open CUR1 for 
                       with dados as (
                       select a.cod_empresa                                                                               as BUKRS,
                                 a.cod_estab                                                                              as GSBER,
                                 substr(to_char(a.dat_apuracao, vt_DateMarcara2), 1, 8)                                        as FATGER,
                                 substr(to_char(a.dat_apuracao, vt_DateMarcara2), 1, 8)                                        as BUDAT,
                                 ' '                                                                                      as XBLNR,
                                 ' '                                                                                      as VLRTRIB,
                                 ' '                                                                                      as ALIQ,
                                 trim(replace(replace(to_char(a.vlr_princ_recolh, vt_numeroMascara),
                                                      '.',
                                                      ''),
                                              ',',
                                              ''))                                                                        as VLRET,
                                 trim(replace(replace(to_char(a.vlr_multa, vt_numeroMascara),
                                                      '.',
                                                      ''),
                                              ',',
                                              ''))                                                                        as DMBTR,
                                 trim(replace(replace(to_char(a.vlr_juros, vt_numeroMascara),
                                                      '.',
                                                      ''),
                                              ',',
                                              ''))                                                                        as WRBTR,
                                 trim(replace(replace(to_char(a.vlr_iss_recolh,vt_numeroMascara),
                                                      '.',
                                                      ''),
                                              ',',
                                              ''))                                                                        as VLRCORR,
                                 ''                                                                                       as cod_estado,
                                 ''                                                                                       as dat_end_clc_op_calction
                                 ,a.dat_apuracao
                                    from ist_guia_recolh   a,
                                         apuracao          b,
                                         registro_estadual e
                                   where a.cod_empresa = b.cod_empresa
                                     and a.cod_estab = b.cod_estab
                                     and a.dat_apuracao = b.dat_apuracao
                                     and e.cod_empresa = a.cod_empresa
                                     and e.cod_estab = a.cod_estab
                                     
                                     and b.cod_tipo_livro = '503' --Registro NF's Serv. Prestados / Tomados
                                     and b.ind_situacao_apur = '2' --Apuracao Realizada
                                     and b.ind_valid_apur = '2' --Valido
                                     and a.cod_empresa = decode( p_emp, vt_Todas, a.cod_empresa, p_emp) 
                                      and a.dat_apuracao between  p_dtini and p_dtfim 
                          )
                          select  a.BUKRS,
                                  substr(c.cgc, 1, 16)                                                                     as BRANCH,
                                  a.GSBER,
                                  a.FATGER,
                                  a.BUDAT,
                                  substr(f.cod_receita, 1, 6)                                                              as CODREC,
                                  substr(c.cgc, 1, 16)                                                                     as CNPJ_CPF,
                                  a.XBLNR,
                                  a.VLRTRIB,
                                  a.ALIQ,
                                  a.VLRET,
                                  nvl(lpad(2,f.dia_vencto,'0'),'01') || to_char(add_months(a.dat_apuracao, 1), vt_DateMarcara3)   as VECTO,
                                  a.DMBTR,
                                  a.WRBTR,
                                  a.VLRCORR,
                                  substr(g.cod_estado || ' ' || c.cod_munic_iss, 1, 15)                                    as TXJCD,
                                  substr(c.insc_municipal, 1, 18)                                                          as STCD3,
                                  a.cod_estado,
                                  a.dat_end_clc_op_calction   
                          from dados a,
                               estado            g,
                               estabelecimento   c,
                               x2097_munic_iss   f
                               
                                         
                          where c.ident_estado = g.ident_estado
                                and a.BUKRS = c.cod_empresa
                                and a.GSBER = c.cod_estab
                                and f.cod_munic_iss = c.cod_munic_iss;
                end;
                

              elsif (v_pagto = vt_ISSRET) then
                begin
                    open CUR1 for 
                        with dados as (
                              select a.cod_empresa                                                      as BUKRS,
                                   a.cod_estab                                                          as GSBER,
                                   substr(to_char(max(last_day(a.data_fiscal)),
                                                  vt_DateMarcara2),
                                          1,
                                          8)                                                            as FATGER,
                                   substr(to_char(max(last_day(a.data_fiscal)),
                                                  vt_DateMarcara2),
                                          1,
                                          8)                                                            as BUDAT,
                                   
                                   
                                   ' '                                                                  as XBLNR,
                                   ' '                                                                  as VLRTRIB,
                                   ' '                                                                  as ALIQ,
                                   trim(replace(replace(to_char(sum(a.vlr_tributo_iss),
                                                                vt_numeroMascara),
                                                        '.',
                                                        ''),
                                                ',',
                                                ''))                                                    as VLRET,
                                  
                                   trim(replace(replace(to_char(0,
                                                                vt_numeroMascara),
                                                        '.',
                                                        ''),
                                                ',',
                                                ''))                                                    as DMBTR,
                                   trim(replace(replace(to_char(0,
                                                                vt_numeroMascara),
                                                        '.',
                                                        ''),
                                                ',',
                                                ''))                                                    as WRBTR,
                                   trim(replace(replace(to_char(sum(a.vlr_tributo_iss),
                                                                vt_numeroMascara),
                                                        '.',
                                                        ''),
                                                ',',
                                                ''))                                                    as VLRCORR,
                                   
                                   
                                   ''                                                                   as cod_estado,
                                   ''                                                                   as dat_end_clc_op_calction,
                                   b.ident_estado_ampar ,
                                   max(a.data_fiscal)                                                   as data_fiscal
                              from dwt_itens_serv a
                              
                              left join dwt_docto_fiscal b
                                on a.num_docfis = b.num_docfis
                               and a.data_fiscal = b.data_fiscal
                               and a.cod_empresa = b.cod_empresa
                               and a.cod_estab = b.cod_estab
                               and a.ident_fis_jur = b.ident_fis_jur
                              
                              left join x04_pessoa_fis_jur c
                                on a.ident_fis_jur = c.ident_fis_jur
                              
                              
                              
                             where a.data_fiscal between p_dtini and p_dtfim
                               and a.cod_empresa =
                                   decode(p_emp, vt_Todas, a.cod_empresa, p_emp)
                               and a.movto_e_s <> '9'
                             group by a.cod_empresa,
                                     
                                      a.cod_estab
                                      ,b.ident_estado_ampar 
                            having sum(a.vlr_tributo_iss) > 0
                    )
                    select a.BUKRS,
                            substr(e.cgc, 1, 16)                                                 as BRANCH,
                            a.GSBER,
                            a.FATGER,
                            a.BUDAT,
                            substr(f.cod_receita, 1, 6)                                          as CODREC,
                            substr(e.cgc, 1, 16)                                                 as CNPJ_CPF,
                            a.XBLNR,
                            a.VLRTRIB,
                            a.ALIQ,
                            a.VLRET,
                             nvl(lpad(2, f.dia_vencto, '0'), '01') ||

                                   to_char(add_months((a.data_fiscal), 1),
                                           vt_DateMarcara3)                                                    as VECTO,
                            a.DMBTR,
                            a.WRBTR,
                            a.VLRCORR,
                            substr(d.cod_estado || ' ' || f.cod_munic_iss,

                                          1,
                                          15)                                                           as TXJCD,
                            substr(e.insc_municipal, 1, 18)                                      as STCD3,
                            a.cod_estado,
                            a.dat_end_clc_op_calction 
                    from dados a
                         left join estabelecimento e
                                on a.BUKRS = e.cod_empresa
                               and a.GSBER = e.cod_estab
                              
                          left join x2097_munic_iss f
                            on e.cod_munic_iss = f.cod_munic_iss
                            
                          left join estado d
                                on a.ident_estado_ampar = d.ident_estado;
                end;

              elsif (v_pagto = vt_INSS) then
                begin
                    open CUR1 for      
                         select distinct x.cod_empresa                                                                       as BUKRS,
                                    substr(emp.cnpj, 1, 16)                                                                  as BRANCH,
                                    x.cod_estab                                                                              as GSBER,
                                    to_char(x.dat_fiscal, vt_DateMarcara2)                                                   as FATGER,
                                    to_char(x.dat_fiscal, vt_DateMarcara2)                                                   as BUDAT,
                                    substr(x.cod_pagto, 1, 6)                                                                as CODREC,
                                    substr(y.cpf_cgc, 1, 16)                                                                 as CNPJ_CPF,
                                    ' '                                                                                      as XBLNR,
                                    trim(replace(replace(to_char('0',
                                                                 vt_numeroMascara),
                                                         '.',
                                                         ''),
                                                 ',',
                                                 ''))                                                                        as VLRTRIB,
                                    trim(replace(replace(to_char('0',
                                                                 '999.99'),
                                                         '.',
                                                         ''),
                                                 ',',
                                                 ''))                                                                        as ALIQ,
                                    trim(replace(replace(to_char(x.vlr_inss,
                                                                 vt_numeroMascara),
                                                         '.',
                                                         ''),
                                                 ',',
                                                 ''))                                                                        as VLRET,
                                    (select dia_limite_receb
                                       from prt_juros_multa) ||
                                    to_char(add_months(p_dtini, 1),
                                            vt_DateMarcara3)                                                                        as VECTO,
                                    trim(replace(replace(to_char(x.vlr_multa,
                                                                 vt_numeroMascara),
                                                         '.',
                                                         ''),
                                                 ',',
                                                 ''))                                                                        as DMBTR,
                                    trim(replace(replace(to_char(x.vlr_juros,
                                                                 vt_numeroMascara),
                                                         '.',
                                                         ''),
                                                 ',',
                                                 ''))                                                                        as WRBTR,
                                    trim(replace(replace(to_char(x.vlr_tot_recolh,
                                                                 vt_numeroMascara),
                                                         '.',
                                                         ''),
                                                 ',',
                                                 ''))                                                                        as VLRCORR,
                                    ' '                                                                                      as TXJCD,
                                    replace(replace(replace(w.insc_municipal,
                                                            '.',
                                                            ''),
                                                    ',',
                                                    ''),
                                            '-',
                                            '')                                                                              as STCD3,
                                    ''                                                                                       as cod_estado,
                                    ''                                                                                       as dat_end_clc_op_calction
                      from irt_gps            x,
                           x04_pessoa_fis_jur y,
                           estabelecimento    w,
                           empresa            emp
                     where x.cod_fis_jur = y.cod_fis_jur
                       and x.ind_fis_jur = y.ind_fis_jur
                       and x.grupo_fis_jur = y.grupo_fis_jur
                       and x.cod_empresa = w.cod_empresa
                       and x.cod_estab = w.cod_estab
                       and x.cod_empresa = emp.cod_empresa
                       and x.cod_empresa =
                           decode(p_emp, vt_Todas, x.cod_empresa, p_emp)
                       and x.ano_competencia =
                           to_char(to_date(p_dtini, vt_DateMarcara), 'YYYY')
                       and x.mes_competencia =
                           to_char(to_date(p_dtini, vt_DateMarcara), 'MM')
                       and x.cod_pagto in
                           (select conteudo
                              from fpar_param_det
                             where id_parametro =  p_perfil 
                               and nome_param = 'COD_PAGTO_INSS');
                end;

              elsif (v_pagto = 'IR') then
                begin
                    open CUR1 for 
                         select distinct h.cod_empresa                                                                          as BUKRS,
                                            substr(d.cnpj, 1, 16)                                                               as BRANCH,
                                            h.cod_estab                                                                         as GSBER,
                                            nvl(to_char(h.data_apuracao,
                                                        vt_DateMarcara2),
                                                ' ')                                                                            as FATGER,
                                            to_char(h.data_apuracao,
                                                    vt_DateMarcara2)                                                            as BUDAT,
                                            substr(c.cod_darf, 1, 6)                                                            as CODREC,
                                            ' '                                                                                 as CNPJ_CPF,
                                            ' '                                                                                 as XBLNR,
                                            trim(replace(replace(to_char(h.vlr_base,
                                                                         vt_numeroMascara),
                                                                 '.',
                                                                 ''),
                                                         ',',
                                                         ''))                                                                   as VLRTRIB,
                                            trim(replace(replace(to_char(h.aliq_tributo,
                                                                         '9999.99'),
                                                                 '.',
                                                                 ''),
                                                         ',',
                                                         ''))                                                                   as ALIQ,
                                            trim(replace(replace(to_char(h.vlr_principal,
                                                                         vt_numeroMascara),
                                                                 '.',
                                                                 ''),
                                                         ',',
                                                         ''))                                                                   as VLRET,
                                            to_char(h.data_vencto,
                                                    vt_DateMarcara2)                                                            as VECTO,
                                            trim(replace(replace(to_char(h.vlr_multa,
                                                                         vt_numeroMascara),
                                                                 '.',
                                                                 ''),
                                                         ',',
                                                         ''))                                                                   as DMBTR,
                                            trim(replace(replace(to_char(h.vlr_juros,
                                                                         vt_numeroMascara),
                                                                 '.',
                                                                 ''),
                                                         ',',
                                                         ''))                                                                   as WRBTR,
                                            trim(replace(replace(to_char(h.vlr_total,
                                                                         vt_numeroMascara),
                                                                 '.',
                                                                 ''),
                                                         ',',
                                                         ''))                                                                   as VLRCORR,
                                            ' '                                                                                 as TXJCD,
                                            replace(replace(replace(f.insc_municipal,
                                                                    '.',
                                                                    ''),
                                                            ',',
                                                            ''),
                                                    '-',
                                                    '')                                                                         as STCD3,
                                            ''                                                                                  as cod_estado,
                                            ''                                                                                  as dat_end_clc_op_calction
                              from x2019_cod_darf  c,
                                   empresa         d,
                                   estabelecimento f,
                                   x75_dctf        h
                             where h.ident_darf = c.ident_darf
                               and h.cod_empresa = d.cod_empresa
                               and h.cod_empresa = f.cod_empresa
                               and h.cod_estab = f.cod_estab
                               and h.vlr_principal > 0
                               and c.cod_darf in
                                   (select conteudo
                                      from fpar_param_det
                                     where id_parametro = p_perfil
                                       and nome_param = 'COD_DARF_IR')
                               and h.cod_empresa =
                                   decode(p_emp,
                                          vt_Todas,
                                          h.cod_empresa,
                                          p_emp)
                               and to_date(h.data_apuracao, vt_DateMarcara) between
                                   p_dtini and p_dtfim;
                end;

              elsif (v_pagto = 'PIS_COFINS') then
                begin
                    open CUR1 for 
                        with dados as (
                                select epc.cod_empresa                                                                                  as BUKRS,
                                           epc.cod_estab                                                                                as GSBER,
                                           nvl(to_char(epc.dat_apur_fim, vt_DateMarcara2),' ')                                          as FATGER,
                                           to_char(epc.dat_apur_fim, vt_DateMarcara2)                                                   as BUDAT,
                                           m205.cod_receita                                                                             as CODREC,
                                           case
                                             when m200.cod_reg = '200' then
                                              vt_PIS
                                             when m200.cod_reg = '600' then
                                              vt_COFINS
                                             else ''
                                           end                                                                                          as XBLNR,
                                           trim(replace(replace(to_char(round(m200.vl_tot_cont_rec /
                                                                              (m210.aliq_pis / 100),
                                                                              2),
                                                                        vt_numeroMascara),
                                                                '.',
                                                                ''),
                                                        ',',
                                                        ''))                                                                            as VLRTRIB,
                                           trim(replace(replace(to_char(m210.aliq_pis,
                                                                        '9999.99'),
                                                                '.',
                                                                ''),
                                                        ',',
                                                        ''))                                                                            as ALIQ,
                                           trim(replace(replace(to_char(m200.vl_tot_cont_rec,
                                                                        vt_numeroMascara),
                                                                '.',
                                                                ''),
                                                        ',',
                                                        ''))                                                                            as VLRET,
                                           
                                           trim(replace(replace(to_char('0',
                                                                        vt_numeroMascara),
                                                                '.',
                                                                ''),
                                                        ',',
                                                        ''))                                                                            as DMBTR,
                                           trim(replace(replace(to_char(0,
                                                                        vt_numeroMascara),
                                                                '.',
                                                                ''),
                                                        ',',
                                                        ''))                                                                            as WRBTR,
                                           trim(replace(replace(to_char('0',
                                                                        vt_numeroMascara),
                                                                '.',
                                                                ''),
                                                        ',',
                                                        ''))                                                                            as VLRCORR,
                                           ' '                                                                                          as TXJCD,
                                           
                                           ''                                                                                           as COD_ESTADO,
                                           epc.dat_apur_fim                                                                             as dat_end_clc_op_calction
                                           ,m200.cod_reg
                                           ,epc.dat_apur_fim
                                      from epc_apuracao epc
                                      left join EPC_REG_AJT_M200_M600 m200
                                        on epc.ID_REG = m200.Id_Reg
                                      
                                      left join EPC_REG_AJT_M205_M605 m205
                                        on m200.ID_REG_M200_M600 =
                                           m205.ID_REG_M200_M600
                                      
                                      left join EPC_REG_AJT_M210_M610 m210
                                        on m200.ID_REG_M200_M600 =
                                           m210.ID_REG_M200_M600
                                       and '01' = m210.cod_cont
                                      
                                      
                                     where epc.cod_empresa =
                                           decode(p_emp,
                                                  vt_Todas,
                                                  epc.cod_empresa,
                                                  p_emp)
                                       and epc.dat_apur_ini between p_dtini and
                                           p_dtfim
                                     order by epc.dat_apur_ini desc, m200.cod_reg asc
                           )
                           
                           select a.BUKRS,
                                  estab.cgc                                                                                    as BRANCH,
                                  a.GSBER,
                                  a.FATGER,
                                  a.BUDAT,
                                  a.CODREC,
                                  estab.cgc                                                                                    as CNPJ_CPF,
                                  a.XBLNR,
                                  a.VLRTRIB,
                                  a.ALIQ,
                                  a.VLRET,
                                  lpad(det2.valor, 2, '0') || to_char(add_months(a.dat_apur_fim, 1),vt_DateMarcara3)                  as VECTO,
                                  a.DMBTR,
                                  a.WRBTR,
                                  a.VLRCORR,
                                  a.TXJCD,
                                  replace(replace(replace(estab.insc_municipal,

                                                                   '.',
                                                                   ''),
                                                           ',',
                                                           ''),
                                                   '-',
                                                   '')                                                                                  as STCD3,
                                  a.cod_estado,
                                  a.dat_end_clc_op_calction
                                  
                           from dados a
                            left join estabelecimento estab
                                        on a.BUKRS = estab.cod_empresa
                                       and a.GSBER = estab.cod_estab
                            left join fpar_parametros fpar
                                        on p_perfil = fpar.id_parametros
                                      
                                      left join fpar_param_det det2
                                        on fpar.id_parametros = det2.id_parametro
                                       and 'VENCIMENTO' = det2.nome_param
                                       and case
                                             when a.cod_reg = '200' then
                                              vt_PIS
                                             when a.cod_reg = '600' then
                                              vt_COFINS
                                             else ''
                                           end = det2.conteudo
                                     ;
                end;

              end if;
              
              FETCH CUR1 INTO fb60Record;       
                 
              WHILE CUR1%FOUND LOOP
              
                lib_proc.add_log('Qtd Linhas Cursor: '||CUR1%ROWCOUNT,      0);
                
                mLinha2 := NULL;
                
                
                if (v_pagto = vt_PCC) then
                  begin
                    v_validacao := 0;
                    begin
                      select distinct valor
                        into v_bukrs
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = vt_DEPARA_EMP
                         and conteudo =
                             decode(p_emp, vt_Todas, fb60Record.bukrs, p_emp); --014
                    exception
                      when others then
                        v_bukrs := NULL;
                        lib_proc.add_log(vt_MSG_ERRO_DP,0);
                        v_validacao := v_validacao + 1;
                    end;
                  
                    begin
                      select valor
                        into v_cod_estab
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and conteudo =
                             fb60Record.bukrs || '-' || fb60Record.gsber
                         and nome_param = vt_DEPARA_ESTAB;
                    exception
                      when NO_DATA_FOUND then
                        lib_proc.add_log('ERRO: Linha de pagto do PCC nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                      when OTHERS then
                        lib_proc.add_log('ERRO: Linha de pagto do PCC nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                    end;
                  
                    v_codigo := fb60Record.codrec;
                  
                  end;
                elsif (v_pagto = vt_ISSRET or v_pagto = vt_ISSFAT) then
                  begin
                    v_validacao := 0;
                    begin
                      select distinct valor
                        into v_bukrs
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = vt_DEPARA_EMP
                         and conteudo =
                             decode(p_emp, vt_Todas, fb60Record.bukrs, p_emp); --014
                    exception
                      when others then
                        v_bukrs := NULL;
                        lib_proc.add_log(vt_MSG_ERRO_DP,0);
                        v_validacao := v_validacao + 1;
                    end;
                  
                    begin
                      select valor
                        into v_cod_estab
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and conteudo =
                             fb60Record.bukrs || '-' || fb60Record.gsber
                         and nome_param = vt_DEPARA_ESTAB;
                    exception
                      when NO_DATA_FOUND then
                        lib_proc.add_log('ERRO: Linha de pagto do ISSQN nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                      when OTHERS then
                        lib_proc.add_log('ERRO: Linha de pagto do ISSQN nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                    end;
                  
                    v_codigo := fb60Record.codrec;
                  
                  end;
                elsif (v_pagto = vt_INSS) then
                  begin
                    v_validacao := 0;
                    begin
                      select distinct valor
                        into v_bukrs
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = vt_DEPARA_EMP
                         and conteudo =
                             decode(p_emp, vt_Todas, fb60Record.bukrs, p_emp); --014
                    exception
                      when others then
                        v_bukrs := NULL;
                        lib_proc.add_log(vt_MSG_ERRO_DP, 0);
                        v_validacao := v_validacao + 1;
                    end;
                  
                    begin
                      select valor
                        into v_cod_estab
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and conteudo =
                             fb60Record.bukrs || '-' || fb60Record.gsber
                         and nome_param = vt_DEPARA_ESTAB;
                    exception
                      when NO_DATA_FOUND then
                        lib_proc.add_log('ERRO: Linha de pagto do ICMS nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                      when OTHERS then
                        lib_proc.add_log('ERRO: Linha de pagto do ICMS nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                    end;
                  
                    v_codigo := fb60Record.codrec;
                  
                  end;
                elsif (v_pagto = 'IR') then
                  begin
                    v_validacao := 0;
                    begin
                      select distinct valor
                        into v_bukrs
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = vt_DEPARA_EMP
                         and conteudo =
                             decode(p_emp, vt_Todas, fb60Record.bukrs, p_emp); --014
                    exception
                      when others then
                        v_bukrs := NULL;
                        lib_proc.add_log(vt_MSG_ERRO_DP, 0);
                        v_validacao := v_validacao + 1;
                    end;
                  
                   
                    begin
                      select valor
                        into v_cod_estab
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and conteudo =
                             fb60Record.bukrs || '-' || fb60Record.gsber
                         and nome_param = vt_DEPARA_ESTAB;
                    exception
                      when NO_DATA_FOUND then
                        lib_proc.add_log('ERRO: Linha de pagto do INSS-NF nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                      when OTHERS then
                        lib_proc.add_log('ERRO: Linha de pagto do INSS-NF nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                    end;
                    v_codigo := fb60Record.codrec;
                  end;
               elsif (v_pagto = 'PIS_COFINS') then
                  begin
                    v_validacao := 0;
                    begin
                      select distinct valor
                        into v_bukrs
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = vt_DEPARA_EMP
                         and conteudo =
                             decode(p_emp, vt_Todas, fb60Record.bukrs, p_emp); --014
                    exception
                      when others then
                        v_bukrs := NULL;
                        lib_proc.add_log(vt_MSG_ERRO_DP,0);
                        v_validacao := v_validacao + 1;
                    end;
                  
                    begin
                      select valor
                        into v_cod_estab
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and conteudo =
                             fb60Record.bukrs || '-' || fb60Record.gsber
                         and nome_param = vt_DEPARA_ESTAB;
                    exception
                      when NO_DATA_FOUND then
                        lib_proc.add_log('ERRO: Linha de pagto do PIS_COFINS nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                      when OTHERS then
                        lib_proc.add_log('ERRO: Linha de pagto do PIS_COFINS nao sera gerado. Falta parametro para o codigo do estabelecimento: ' ||
                                         fb60Record.bukrs || '-' ||
                                         fb60Record.gsber,
                                         0);
                        v_cod_estab := NULL;
                    end;
                  
                    v_codigo := fb60Record.codrec;
                  
                  exception
                    when others then
                      lib_proc.add_log('*********ERRO na geração PIS_COFINS: ' ||
                                       ' - p_emp:  ' || p_emp ||
                                       ' -  p_dtini: ' || p_dtini ||
                                       ' -  p_dtfim: ' || p_dtfim ||
                                       ' -  p_perfil: ' || p_perfil ||
                                       '- Erro: ' || sqlerrm,
                                       1);
                  end;
                
                end if;
              
                if (v_validacao = 0) then
                  
                  begin
                      mLinha2 := LIB_STR.w(mLinha2,
                                           rpad(nvl(v_bukrs, '0'), vCol01, '0') || sep || --'EMPRESA - SAP'
                                           rpad(nvl(fb60Record.BRANCH, ' '),
                                                vCol02,
                                                ' ') || sep || --'CNPJ'
                                           rpad(nvl(v_cod_estab, ' '),
                                                vCol03,
                                                ' ') || sep || --'ESTAB - SAP'
                                           rpad(to_date(fb60Record.FATGER, vt_DateMarcara),
                                                vCol04,
                                                ' ') || sep || --'DATA FATO GERADOR'
                                           rpad(nvl(v_codigo, ' '), vCol05, ' ') || sep || --'COD. RECEITA'
                                           rpad(numFormat(nvl(fb60Record.VLRET / 100,
                                                              0)),
                                                vCol06,
                                                ' ') || sep || --'VALOR IMPOSTO'
                                           rpad(to_date(fb60Record.VECTO,
                                                        vt_DateMarcara),
                                                vCol07,
                                                ' ') || sep || --'VENCIMENTO'
                                           rpad(numFormat(nvl(fb60Record.DMBTR / 100,
                                                              0)),
                                                vCol08,
                                                ' ') || sep || --'VALOR DA MULTA'
                                           rpad(numFormat(nvl(fb60Record.WRBTR / 100,
                                                              0)),
                                                vCol09,
                                                ' ') || sep || --'VALOR DE JUROS'
                                           rpad(numFormat(nvl(fb60Record.VLRCORR / 100,
                                                              0)),
                                                vCol010,
                                                ' ') || sep || --'VALOR TOTAL'
                                           rpad(nvl(fb60Record.TXJCD, ' '),
                                                vCol011,
                                                ' ') || sep --'DOMICILIO FISCAL'
                                          ,
                                           a);
                    exception
                      	when others then 
                          lib_proc.add_log('Erro na geração do relatório! '||sqlerrm,0);
                    end;
                  
                  vImp :=    case v_pagto 
                            when vt_PCC then v_pagto
                            when 'IR' then vt_IRRF
                            when vt_INSS then v_pagto
                            else v_pagto
                       end ;   
                       
                       
                  select case when fb60Record.XBLNR in( vt_PIS,vt_COFINS) then 
                                   fb60Record.XBLNR||'-'||fb60Record.codrec||'-'||to_char(to_date(fb60Record.fatger,vt_DateMarcara2),vt_DateMarcara4)
                              else   v_pagto||'-'||fb60Record.codrec||'-'||to_char(to_date(fb60Record.fatger,vt_DateMarcara2),vt_DateMarcara4)
                         end
                         into v_desc_HEADER_TXT
                  from dual ;
                
                  
                  lib_proc.add_log('Log: '||v_pagto||' - '||vImp||' - Empresa: '||fb60Record.bukrs|| ' - '||'Estab: '||fb60Record.GSBER,0);
                  lib_proc.add_log(v_desc_HEADER_TXT,0);
                  
                  begin
                      select distinct valor
                        into vContaDeb
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = 'COD_CONTA_DEB'
                         and (REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = vImp
                             or REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = fb60Record.xblnr
                             )
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2)  = fb60Record.bukrs
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 3)  = fb60Record.GSBER
                         ; 
                    exception
                      when others then
                        vContaDeb := NULL;
                    end;
                          
                  begin
                      select distinct valor
                        into vContaCre
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = 'COD_CONTA_CRE'
                         and (REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = vImp
                             or REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = fb60Record.xblnr
                             )
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2)  = fb60Record.bukrs
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 3)  = fb60Record.GSBER
                         ; 
                    exception
                      when others then
                        vContaDeb := NULL;
                    end;
                          
                  begin
                      select distinct valor
                        into vCostCenter
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = 'COD_CUSTO'
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1) = fb60Record.bukrs
                         and ( REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2) = vImp
                               or REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2) = fb60Record.xblnr
                             )
                            ;
                    exception
                      when others then
                        vCostCenter := NULL;
                    end;
                    
                  begin
                      select distinct valor
                        into vCostLucro
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = 'COD_LUCRO'
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1) = fb60Record.bukrs
                         and ( REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2) = vImp
                               or REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2) = fb60Record.xblnr
                             )
                         
                         ; 
                    exception
                      when others then
                        vCostLucro := NULL;
                    end;
                  
                   begin
                      select distinct valor
                        into vCustomer
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = 'COD_CUSTOMER'
                         and (    REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = v_codigo
                               or REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = v_pagto
                               or  REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = fb60Record.xblnr
                             )
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2)  = fb60Record.bukrs
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 3)  = fb60Record.GSBER
                         ; 
                    exception
                      when others then
                        vCustomer := NULL;
                    end;
                    
                   
                   begin
                      select distinct valor
                        into vVendor
                        from fpar_param_det
                       where id_parametro = p_perfil
                         and nome_param = 'COD_VENDOR_NO'
                         and (     REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = v_codigo
                               or  REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = v_pagto
                               or  REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 1)  = fb60Record.xblnr
                             )
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 2)  = fb60Record.bukrs
                         and REGEXP_SUBSTR(replace(conteudo,' ',''), vt_REGEXP1, 1, 3)  = fb60Record.GSBER
                         ; 
                    exception
                      when others then
                        vVendor := NULL;
                    end;
                   
                    
                  lib_proc.add_log('xblnr: '||fb60Record.xblnr||' - vVendor: '||vVendor||' - vCustomer: '||vCustomer,0);
                  
                  mLinha := NULL;
                  
                  
                  
                  
                  mHeader :=  lpad(v_contaLinhas,3,'0')             || CHR(9) -- COUNT
                                     ||v_bukrs                      || CHR(9) -- COMP_CODE
                                     ||'KR'                         || CHR(9) -- DOC_TYPE
                                     ||p_dEntrada                   || CHR(9) -- DOC_DATE
                                     ||p_dLanc                      || CHR(9) -- PSTNG_DATE
                                     ||v_desc_HEADER_TXT            || CHR(9) -- HEADER_TXT
                                     ||'BRL'                        || CHR(9) -- CURRENCY
                                     ||null                         || CHR(9)  -- EXCH_RATE
                                     ||null                         || CHR(9) -- TRANS_DATE
                                     ||v_desc_HEADER_TXT                      || CHR(9) -- REF_DOC_NO
                                     ||null                         || CHR(9) -- REF_KEY_3
                                     ;
                                     
                 
                  
                           
                  mDebito := vContaDeb                              || CHR(9) --GL_ACCOUNT           12
                             ||vCustomer                            || CHR(9) --CUSTOMER             13
                             ||case when nvl(vContaCre,'0') <> '0' then 
                                     vVendor 
                                    else 
                                      ''
                               end                                  || CHR(9) --VENDOR_NO            14
                             ||v_desc_HEADER_TXT                    || CHR(9) --ITEM_TEXT            15
                             ||null                                 || CHR(9) --AMT_DOCCUR_D         16
                             ||replace(fb60Record.VLRET /100,',','.')                || CHR(9) --AMT_DOCCUR_C         17
                             ||null                                 || CHR(9) --TAX_CODE             18
                             ||'0001'                               || CHR(9) --PMNTTRMS             19
                             ||vCostCenter                          || CHR(9) --COSTCENTER           20
                             ||vCostLucro                           || CHR(9) --PROFIT_CTR           21
                             ||null                                 || CHR(9) --ORDERID              22
                             ||null                                 || CHR(9) --WBS_ELEMENT          23
                             ||v_codigo                                 || CHR(9) --ALLOC_NMBR           24
                             ||null                                 || CHR(9) --TRADE_ID             25
                             ||null                                 || CHR(9) --FUNC_AREA            26
                             ||null                                 || CHR(9) --VALUE_DATE           27
                             ||null                                 || CHR(9) --PYMT_METH            28
                             ||null                                 --|| CHR(9) --BLINE_DATE           29
                             ;
                  
                  mCredito := vContaCre                             || CHR(9) --GL_ACCOUNT           12
                             ||vCustomer                            || CHR(9) --CUSTOMER             13
                             ||case when nvl(vContaDeb,'0') <> '0' then 
                                     vVendor 
                                    else 
                                      ''
                               end                                  || CHR(9) --VENDOR_NO            14
                             ||v_desc_HEADER_TXT                    || CHR(9) --ITEM_TEXT            15
                             ||replace(fb60Record.VLRET /100,',','.')               || CHR(9) --AMT_DOCCUR_D         16
                             ||null                                 || CHR(9) --AMT_DOCCUR_C         17
                             ||null                                 || CHR(9) --TAX_CODE             18
                             ||'0001'                               || CHR(9) --PMNTTRMS             19
                             ||vCostCenter                          || CHR(9) --COSTCENTER           20
                             ||vCostLucro                           || CHR(9) --PROFIT_CTR           21
                             ||null                                 || CHR(9) --ORDERID              22
                             ||null                                 || CHR(9) --WBS_ELEMENT          23
                             ||v_codigo                                 || CHR(9) --ALLOC_NMBR           24
                             ||null                                 || CHR(9) --TRADE_ID             25
                             ||null                                 || CHR(9) --FUNC_AREA            26
                             ||null                                 || CHR(9) --VALUE_DATE           27
                             ||null                                 || CHR(9) --PYMT_METH            28
                             ||null                                 --|| CHR(9) --BLINE_DATE           29
                             ;
                  
                  mLinha := null;
                  mLinha3 := null;
                  
                  mLinha := LIB_STR.w(mLinha    , mHeader ||mDebito ,1);
                  mLinha3 := LIB_STR.w(mLinha3  , mHeader ||mCredito,1);
                 
                  
                  select case when fb60Record.VLRET <= 0 then 
                               null 
                              else mLinha
                         end into mLinha
                  from dual ;
                
                 LIB_PROC.add(mLinha);
                  LIB_PROC.add(mLinha3);
                  LIB_PROC.add(mLinha2, null, null, 2);
                
                  mLinha  := LIB_STR.w(' ', mLinha, 1);
                  mLinha2 := LIB_STR.w(' ', mLinha2, 1);
                  mLinha3 := LIB_STR.w(' ', mLinha3, 1);
                
                  
                  select case when v_cod_estab is not null then 
                              v_contador + 1
                              else v_contador
                         end into v_contador
                  from dual ;
                  
              
                end if;

                v_contaLinhas := v_contaLinhas + 1;
                
                FETCH CUR1 INTO fb60Record; 
              end loop;
            
              CLOSE CUR1;
            else
              lib_proc.add_log('Não existe a conexão com o OneSource para gerar os dados do IRPJ CSLL',
                               0);
            end if;
          end;
          lib_proc.add_log('Registro(s) ' || v_pagto || ' gerado(s):' ||
                           v_contador,
                           0);
                           
                           
          i := p_opcao.NEXT(i);
        end loop;
        lib_proc.add_log('Termino dos Procedimentos: ' ||
                         to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss'),
                         0);
      end;
    end if;
  
    LIB_PROC.CLOSE();
    RETURN mproc_id;
  END;

  FUNCTION FN_VENCIMENTO RETURN T_VEN_TABLE
    PIPELINED IS
    V_RECORD T_VEN_RECORD;
  BEGIN
    for dados in (select decode(a.nome_param,
                                vt_COD_DARF_IRPJ_CSLL,
                                a.conteudo,
                                replace(a.nome_param, 'COD_RECEITA_', '') || '-' ||
                                a.conteudo || '-' || a.valor
                                )   as conteudo,
                         'Codigo de receita ' ||
                         decode(a.nome_param,
                                vt_COD_DARF_IRPJ_CSLL,
                                a.conteudo,
                                replace(a.nome_param, 'COD_RECEITA_', '') || '-' ||
                                a.conteudo || '-' || a.valor
                                )  as valor
                    from fpar_param_det a
                   where a.nome_param in
                         ('COD_RECEITA_ICMS',
                          'COD_RECEITA_ICMSST',
                          vt_COD_DARF_IRPJ_CSLL)
                  
                  union all
                  select vt_PIS as conteudo, 'Codigo de receita PIS'       as valor
                    from dual
                  union all
                  select vt_COFINS as conteudo, 'Codigo de receita COFINS' as valor
                    from dual) loop
    
      V_RECORD.CONTEUDO := dados.conteudo;
      V_RECORD.VALOR    := dados.valor;
      PIPE ROW(V_RECORD);
    end loop;
  END;


  FUNCTION FN_TIPO RETURN T_TIPO_TABLE
  -- Retorna o Tipo da Consulta
    PIPELINED IS
    V_RECORD T_TIPO_RECORD;
  BEGIN
    for dados in (select 'IRPJ_REAL' as tipo
                    from dual
                  union all
                  select 'CSLL_REAL' as tipo
                    from dual
                  union all
                  select 'IRPJ_PRESUMIDO' as tipo
                    from dual
                  union all
                  select 'CSLL_PRESUMIDO' as tipo
                    from dual) loop
    
      V_RECORD.TIPO := dados.tipo;
      PIPE ROW(V_RECORD);
    end loop;
  END;

  FUNCTION FN_FERIADO_CONT RETURN T_FERIADO_CONT_TABLE
    -- Retorna a tabela de Feriados
    PIPELINED IS
    V_RECORD T_FERIADO_CONT;
  BEGIN
    for dados in (select to_char(NVL((select max(a.conteudo)
                                       from fpar_param_det a
                                      where a.nome_param = vt_FERIADO),
                                     0) + 1
                                     
                                  ) as  contador
                    from dual
                  union all
                  select to_char(NVL((select max(a.conteudo)
                                       from fpar_param_det a
                                      where a.nome_param = vt_FERIADO),
                                     0) + 2
                                  ) as contador
                    from dual
                  union all
                  select to_char(NVL((select max(a.conteudo)
                                       from fpar_param_det a
                                      where a.nome_param = vt_FERIADO),
                                     0) + 3
                                 ) as contador
                    from dual
                  union all
                  select to_char(NVL((select max(a.conteudo)
                                       from fpar_param_det a
                                      where a.nome_param = vt_FERIADO),
                                     0) + 4
                                 ) as contador
                    from dual
                  union all
                  select to_char(NVL((select max(a.conteudo)
                                       from fpar_param_det a
                                      where a.nome_param = vt_FERIADO),
                                     0) + 5
                                 ) as contador
                    from dual) loop
    
      V_RECORD.contador := lpad(dados.contador,7,'0');
      PIPE ROW(V_RECORD);
    end loop;
  END;
  
  FUNCTION FN_TIPO_IMP RETURN T_TIPO_TABLE
    --Retorna os tipos de Impostos
    PIPELINED IS
    V_RECORD T_TIPO_RECORD;
  BEGIN
    for dados in (select vt_IRRF      as tipo from dual union all
                  select vt_PCC       as tipo from dual union all
                  select vt_INSS      as tipo from dual union all
                  select vt_PIS       as tipo from dual union all
                  select vt_COFINS    as tipo from dual union all
                  select vt_ISSFAT       as tipo from dual union all
                  select vt_ISSRET       as tipo from dual
                 ) loop
    
      V_RECORD.TIPO := dados.tipo;
      PIPE ROW(V_RECORD);
    end loop;
  END;
  
  
  FUNCTION FN_COGPGTO RETURN T_CODPGTO_TABLE
    --Retorna o Codigo de Pagamento
    PIPELINED IS
    V_RECORD T_CODPGTO_RECORD;
  BEGIN
    for dados in ( select cast(a.cod_darf as VARCHAR2(10)) || ' - ' || b.cod_empresa || ' - ' ||  c.cod_estab as IMP_EMP_ESTAB
                         ,a.cod_darf  as codigo
                         ,c.cod_empresa
                         ,c.cod_estab
                    from X2019_COD_DARF a, empresa b, estabelecimento c
                   where b.cod_empresa = c.cod_empresa
                     and valid_darf = (select max(valid_darf) from X2019_COD_DARF)
                   
                   
                   union all
                   
                   select cast(a.cod_pagto as VARCHAR2(10)) || ' - ' || b.cod_empresa || ' - ' || c.cod_estab as IMP_EMP_ESTAB
                         ,a.cod_pagto  as codigo
                         ,c.cod_empresa
                         ,c.cod_estab
                    from irt_cod_pg_inss a, empresa b, estabelecimento c
                   where b.cod_empresa = c.cod_empresa
                   
                   union all
                   
                   select cast(vt_ISSRET as VARCHAR2(10)) || ' - ' || b.cod_empresa || ' - ' || c.cod_estab as IMP_EMP_ESTAB
                         ,vt_ISSRET  as codigo
                         ,c.cod_empresa
                         ,c.cod_estab
                    from  empresa b, estabelecimento c
                   where b.cod_empresa = c.cod_empresa
                   
                   union all
                   select cast(vt_ISSFAT as VARCHAR2(10)) || ' - ' || b.cod_empresa || ' - ' || c.cod_estab as IMP_EMP_ESTAB
                         ,vt_ISSFAT  as codigo
                         ,c.cod_empresa
                         ,c.cod_estab
                    from  empresa b, estabelecimento c
                   where b.cod_empresa = c.cod_empresa
                   
                   union all
                   select cast(vt_PIS as VARCHAR2(10)) || ' - ' || b.cod_empresa || ' - ' || c.cod_estab as IMP_EMP_ESTAB
                         ,vt_PIS  as codigo
                         ,c.cod_empresa
                         ,c.cod_estab
                    from  empresa b, estabelecimento c
                   where b.cod_empresa = c.cod_empresa
                   
                   union all
                   select cast(vt_COFINS as VARCHAR2(10)) || ' - ' || b.cod_empresa || ' - ' || c.cod_estab as IMP_EMP_ESTAB
                         ,vt_COFINS  as codigo
                         ,c.cod_empresa
                         ,c.cod_estab
                    from  empresa b, estabelecimento c
                   where b.cod_empresa = c.cod_empresa
                 ) loop
    
      V_RECORD.IMP_EMP_ESTAB := dados.IMP_EMP_ESTAB;
      V_RECORD.codigo := dados.codigo;
      V_RECORD.cod_empresa := dados.cod_empresa;
      V_RECORD.cod_estab := dados.cod_estab;
      PIPE ROW(V_RECORD);
    end loop;
  END;


END LKM_APTRIB_CPROC;
/
