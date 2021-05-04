CREATE OR REPLACE PACKAGE GSR_ARQ_PIS_COFINS_CONT_CPROC IS

  -- autor   : Everton Zamarioli
  -- created : 23/03/2011
  -- purpose : PIS/COFINS

  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */
    FUNCTION Parametros RETURN VARCHAR2;
    FUNCTION Nome RETURN VARCHAR2;
    FUNCTION Tipo RETURN VARCHAR2;
    FUNCTION Versao RETURN VARCHAR2;
    FUNCTION Descricao RETURN VARCHAR2;
    FUNCTION Modulo RETURN VARCHAR2;
    FUNCTION Classificacao RETURN VARCHAR2;

    FUNCTION Executar(pd_data_ini      date
                    , pd_data_fim      date
                    , pind_geracao     char
                    , pcod_estab       LIB_PROC.varTab
                  ) RETURN INTEGER;


    PROCEDURE teste_rel ;



END GSR_ARQ_PIS_COFINS_CONT_CPROC;
/
CREATE OR REPLACE PACKAGE body GSR_ARQ_PIS_COFINS_CONT_CPROC IS

  mcod_empresa empresa.cod_empresa%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;
    vs_linha                   varchar2(4000);
    vs_tab                     char(1) := chr(9);


    vn_qtd_reg_out_cre number := 0;
    vn_qtd_reg_ret     number := 0;



  procedure gera_outros_cred (vs_cod_estab  varchar2
                            , vd_data_ini   date
                            , vd_data_fim   date) is

             cursor outros_cred(c_cod_estab  varchar2
                              , c_data_ini   date
                              , c_data_fim   date) is
                select x147.cod_empresa
                     , x147.cod_estab
                     , x2005.cod_docto
                     , x04.ind_fis_jur
                     , x04.cod_fis_jur
                     , x147.data_oper
                     , x147.discri_oper
                     , x147.vlr_oper
                     , x147.vlr_base_pis
                     , x147.vlr_aliq_pis
                     , x147.vlr_pis
                     , x147.vlr_base_cofins
                     , x147.vlr_aliq_cofins
                     , x147.vlr_cofins
                     , x147.ind_origem_cred
                     , x2002.cod_conta
                     , x2003.cod_custo
                     , x147.desc_compl
                     , x147.num_docto
                     , x147.serie
                     , x147.sub_serie
                     , x147.num_lancto
                 from x147_oper_cred x147
                    , x2005_tipo_docto x2005
                    , x04_pessoa_fis_jur x04
                    , x2002_plano_contas x2002
                    , x2003_centro_custo x2003
                where x147.ident_docto   = x2005.ident_docto
                  and x147.ident_fis_jur = x04.ident_fis_jur(+)
                  and x147.ident_conta   = x2002.ident_conta(+)
                  and x147.ident_custo   = x2003.ident_custo(+)
                  and x147.cod_estab     = c_cod_estab
                  and x147.cod_empresa   = mcod_empresa
                  and x147.data_oper between c_data_ini and c_data_fim
                  order by cod_estab;

  begin

     if vn_qtd_reg_out_cre = 0 then

             vs_linha := 'cod_empresa'
                     ||vs_tab||'cod_estab'
                     ||vs_tab||'cod_docto'
                     ||vs_tab||'ind_fis_jur'
                     ||vs_tab||'cod_fis_jur'
                     ||vs_tab||'data_oper'
                     ||vs_tab||'discri_oper'
                     ||vs_tab||'vlr_oper'
                     ||vs_tab||'vlr_base_pis'
                     ||vs_tab||'vlr_aliq_pis'
                     ||vs_tab||'vlr_pis'
                     ||vs_tab||'vlr_base_cofins'
                     ||vs_tab||'vlr_aliq_cofins'
                     ||vs_tab||'vlr_cofins'
                     ||vs_tab||'ind_origem_cred'
                     ||vs_tab||'cod_conta'
                     ||vs_tab||'cod_custo'
                     ||vs_tab||'desc_compl'
                     ||vs_tab||'num_docto'
                     ||vs_tab||'serie'
                     ||vs_tab||'sub_serie'
                     ||vs_tab||'num_lancto';
                 lib_proc.add(vs_linha, null, null, 1);

        vn_qtd_reg_out_cre := vn_qtd_reg_out_cre + 1;

      end if;


  for mreg in outros_cred (vs_cod_estab
                         , vd_data_ini
                         , vd_data_fim) loop



                   vs_linha := mreg.cod_empresa
                     ||vs_tab||mreg.cod_estab
                     ||vs_tab||mreg.cod_docto
                     ||vs_tab||mreg.ind_fis_jur
                     ||vs_tab||mreg.cod_fis_jur
                     ||vs_tab||mreg.data_oper
                     ||vs_tab||mreg.discri_oper
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_oper),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_pis),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_aliq_pis),'999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_pis),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_cofins),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_aliq_cofins),'999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_cofins),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                     ||vs_tab||mreg.ind_origem_cred
                     ||vs_tab||mreg.cod_conta
                     ||vs_tab||mreg.cod_custo
                     ||vs_tab||mreg.desc_compl
                     ||vs_tab||mreg.num_docto
                     ||vs_tab||mreg.serie
                     ||vs_tab||mreg.sub_serie
                     ||vs_tab||mreg.num_lancto;
                 lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg_out_cre := vn_qtd_reg_out_cre +1;

  end loop;


  end gera_outros_cred;

  procedure gera_retencoes (vs_cod_estab  varchar2
                          , vd_data_ini   date
                          , vd_data_fim   date) is

      cursor ret_fonte is
            select x145.COD_EMPRESA
                 , x145.COD_ESTAB
                 , x145.DATA_REC_RET
                 , decode(x145.IND_NAT_REC,'0','0 - Receita Não Cumulativa'
                                          ,'1','1 - Receita Cumulativa', '') IND_NAT_REC
                 , decode(x145.COD_RET_FONTE, '01','01 Ret. Órg, Aut e Fund. Fed'
                                            , '02','02 Ret. Out Entid Adm Púb Fed'
                                            , '03','03 Ret. Pes.Jur Dir Privado'
                                            , '04','04 Rec. Sociedade Coop.'
                                            , '05','05 Ret. Fab. Máq. e Veíc.'
                                            , '99 Outras Retenções') COD_RET_FONTE
                 , x04.ind_fis_jur
                 , x04.cod_fis_jur
                 , substr(x04.razao_social,1,15) razao_social
                 , x145.VLR_RECEBIDO
                 , x145.VLR_TOT_RET_FONTE
                 , x145.VLR_RET_FONTE_PIS
                 , x145.VLR_RET_FONTE_COFINS
            --, x145.COD_RECEITA
                , decode(x145.IND_COND_PJ_DECL,'0','0 - Beneficiária da Retenção/Recolhimento'
                                              ,'1','1 - Responsável pelo Recolhimento') IND_COND_PJ_DECL
             from x145_contrib_ret_fonte x145
                , x04_pessoa_fis_jur     x04
            where x145.ident_fonte_pag = x04.ident_fis_jur(+)
              and x145.cod_estab       = vs_cod_estab
              and x145.cod_empresa     = mcod_empresa
              and x145.DATA_REC_RET between vd_data_ini and vd_data_fim
         order by x145.cod_estab;

  begin

     if vn_qtd_reg_ret = 0 then

                   vs_linha := 'cod_empresa'
                     ||vs_tab||'cod_estab'
                     ||vs_tab||'data_rec_ret'
                     ||vs_tab||'cod_ret_fonte'
                     ||vs_tab||'cod_fis_jur'
                     ||vs_tab||'razao_social'
                     ||vs_tab||'vlr_recebido'
                     ||vs_tab||'vlr_tot_ret_fonte'
                     ||vs_tab||'vlr_ret_fonte_pis'
                     ||vs_tab||'vlr_ret_fonte_cofins';
                 lib_proc.add(vs_linha, null, null, 2);

        vn_qtd_reg_ret := vn_qtd_reg_ret +1;

      end if;


for mreg in ret_fonte  loop


                   vs_linha := mcod_empresa
                     ||vs_tab||to_char(mreg.cod_estab)
                     ||vs_tab||to_char(mreg.DATA_REC_RET,'dd/mm/yyyy')
                     ||vs_tab||mreg.cod_ret_fonte
                     ||vs_tab||mreg.cod_fis_jur
                     ||vs_tab||mreg.razao_social
                     ||vs_tab||lpad(trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_RECEBIDO),'9,999,999,999.99'),'.',';'),',','.'),';',',')),16,' ')
                     ||vs_tab||lpad(trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_TOT_RET_FONTE),'9,999,999,999.99'),'.',';'),',','.'),';',',')),16,' ')
                     ||vs_tab||lpad(trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_RET_FONTE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',',')),16,' ')
                     ||vs_tab||lpad(trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_RET_FONTE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',',')),16,' ');
                     lib_proc.add(vs_linha, null, null, 2);


             vn_qtd_reg_ret := vn_qtd_reg_ret + 1;


    end loop;


  end gera_retencoes;

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN

    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    musuario     := LIB_PARAMETROS.Recuperar('Usuario');

    LIB_PROC.add_param(pstr, 'Data Inicio', 'date', 'textbox', 'S', null, 'dd/mm/yyyy');
    LIB_PROC.add_param(pstr, 'Data Fim', 'date', 'textbox', 'S', null, 'dd/mm/yyyy');

    LIB_PROC.add_param(pstr,'Relatorio','varchar2','listbox','S',1,null,'1=Outros_creditos,2=Retencoes,3=Todos');


    LIB_PROC.add_param(pstr,'Estabelecimento','Varchar2','MultiSelect','S', NULL, NULL,
                      'select estab.cod_estab, estab.cod_estab || '' - '' || estab.razao_social '||
                      'from estabelecimento estab '||
                      'where estab.cod_empresa ='''||mcod_empresa||'''  '||
                      'order by 1 ',
                      'S');


    RETURN pstr;

  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS - Relatórios Analíticos / Contabilidade';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Geracao de relatorios analiticos de apoio ao PIS/COFINS';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS';
  END;

FUNCTION Executar(pd_data_ini      date
                , pd_data_fim      date
                , pind_geracao     char
                , pcod_estab       LIB_PROC.varTab
                  ) RETURN INTEGER IS


    /* Variaveis de Trabalho */
    mproc_id                 integer;
    vs_cod_estab             varchar2(6);




  BEGIN



    mproc_id := LIB_PROC.new('GSR_ARQ_PIS_COFINS_CONT_CPROC', 48, 150);

    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    musuario     := LIB_PARAMETROS.Recuperar('Usuario');




--lib_proc.add_log(vs_ind_ivecore||vs_ind_sapiens||vs_ind_powersap||vs_ind_mainframe||vs_ind_outros,1);

    if pind_geracao = 1 then -- Outros Creditos

          LIB_PROC.add_tipo(mproc_id, 1, 'PIS_COFINS_OUTROS_CRED', 2);


          FOR cont_estab IN 1 .. pcod_estab.COUNT LOOP

             vs_cod_estab := pcod_estab(cont_estab);

             gera_outros_cred (vs_cod_estab
                             , pd_data_ini
                             , pd_data_fim);

          end loop;

    elsif pind_geracao = 2 then -- Retencoes

          LIB_PROC.add_tipo(mproc_id, 2, 'PIS_COFINS_RETENCOES', 2);


          FOR cont_estab IN 1 .. pcod_estab.COUNT LOOP

               vs_cod_estab := pcod_estab(cont_estab);

               gera_retencoes (vs_cod_estab
                             , pd_data_ini
                             , pd_data_fim);
          end loop;

    else -- Todos

          LIB_PROC.add_tipo(mproc_id, 1, 'PIS_COFINS_OUTROS_CRED', 2);
          LIB_PROC.add_tipo(mproc_id, 2, 'PIS_COFINS_RETENCOES', 2);

          FOR cont_estab IN 1 .. pcod_estab.COUNT LOOP

             vs_cod_estab := pcod_estab(cont_estab);


             gera_outros_cred (vs_cod_estab
                             , pd_data_ini
                             , pd_data_fim);

             gera_retencoes (vs_cod_estab
                           , pd_data_ini
                           , pd_data_fim);


          end loop;

    end if;



    lib_proc.add_log('Quantidade de registros outros creditos gerados: '||vn_qtd_reg_out_cre,1);
    lib_proc.add_log('Quantidade de registros retencoes gerados: '||vn_qtd_reg_ret,1);

    lib_proc.add_log('Processo Finalizado com sucesso',1);

    vn_qtd_reg_out_cre := 0;
    vn_qtd_reg_ret := 0;


    LIB_PROC.CLOSE();
    RETURN mproc_id;

END;


	-------------------------------------------------------------------------
	-- Procedure para Teste
	-------------------------------------------------------------------------


    PROCEDURE teste_rel IS
    --mproc_id INTEGER;
    resultado integer := 0;
  BEGIN
    lib_parametros.salvar( 'EMPRESA', '001' );
    mcod_empresa := '001';
   -- resultado := Executar( '01/05/2011','31/05/2011','0304');

    dbms_output.put_line('');
    dbms_output.put_line('---Arquivo Magnetico----');
    dbms_output.put_line('');

    lib_proc.list_output(resultado, 1);
  END;

END GSR_ARQ_PIS_COFINS_CONT_CPROC;
/
