create or replace package MSAF_LV_CREDPIS_CPROC is


  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */

  function parametros return varchar2;
  function nome return varchar2;
  function tipo return varchar2;
  function versao return varchar2;
  function descricao return varchar2;
  function modulo return varchar2;
  function classificacao return varchar2;

  function executar (pcd_empr      varchar2,
                     pdt_apur     date) return integer;

end MSAF_LV_CREDPIS_CPROC;
/
create or replace package body MSAF_LV_CREDPIS_CPROC is

  mcod_empresa empresa.cod_empresa%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;


  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');

   LIB_PROC.add_param(pstr, 'Empresa', 'Varchar2',
                             'Combobox', 'S', NULL, NULL,
                             'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa 
                                  e where cod_empresa = '''||mcod_empresa||''' order by 1' );

    LIB_PROC.add_param(pstr,
                       'Data Apuração',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');


  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'ATENÇÃO: A data de apuração corresponde ao último dia de cada mês.', 'varchar2'  , 'text'  , 'N', null   , null) ;


    RETURN pstr;
  END;

FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Livro de Apuracao CREDPIS - Controle de Creditos';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Livro - Apuracao CREDPIS';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V1R1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Livro de Apuracao CREDPIS - Controle de Creditos';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION Executar (pcd_empr      varchar2,
                     pdt_apur     date) RETURN INTEGER IS

    /* Variáveis de Trabalho */
    mproc_id         INTEGER;
    mLinha           VARCHAR2(7000);
    v_linha          number(15)  := 0;
    v_reg            varchar2(7000);
    v_reg_c          varchar2(7000);

--cursor relatório sintetico---
CURSOR ict_1 is

select  x13.codigo     x1,
        replace(x13.numero_patrimonial,CHR(13),'-') x2,
        emp.codigo_contabil x3,
        estab.codigo_contabil x4,
        x13.numero_nfe x5,
        x13.serie_nfs  x6,
        x13.data_entrada x7,
        x04.nome x8,
        x04.cnpj x9,
        x13.descricao x10,
        x13.pis_cofins_data_inicio x11,
        x13.pis_cofins_data_fim    x12,
        x148.data x13,
        trunc((months_between(x148.data,x13.pis_cofins_data_inicio))) x14,
        x13.valor_pis x15,
        x13.valor_cofins x16,
        round((x13.valor_pis/reg.numero_meses) * trunc((months_between(x148.data,x13.pis_cofins_data_inicio))),2) x17,
        round((x13.valor_cofins/reg.numero_meses) * trunc((months_between(x148.data,x13.pis_cofins_data_inicio))),2) x18,
        reg.numero_meses x19,        
        x148.base_calculo_mensal x20,
        x13.aliquota_pis x21,
        x148.valor_pis_mensal x22,
        x13.aliquota_cofins x23,
        x148.valor_cofins_mensal x24,
        x13.valor_pis-round((x13.valor_pis/reg.numero_meses) * trunc((months_between(x148.data,x13.pis_cofins_data_inicio))+1),2) x25,
        x13.valor_cofins-round((x13.valor_cofins/reg.numero_meses) * trunc((months_between(x148.data,x13.pis_cofins_data_inicio))+1),2) x26,
        trunc((months_between(x148.data,x13.pis_cofins_data_inicio))+1) x27,
        reg.numero_meses-trunc((months_between(x148.data,x13.pis_cofins_data_inicio))+1) x28
        ,decode(x13.flag_importado, 'S','Importado','Nacional') x29
        ,(case when x13.indicador_operacoes_credito = '1' then 'Creditos com base nos encargos de Depreciação' else
           case when x13.indicador_operacoes_credito = '2' then 'Creditos com base nos encargos de Amortização' else
            'Creditos com base no Valor de Aquisição' end end) x30


from credpis.creditos x148
    ,credpis.empresas emp
    ,credpis.filiais  estab
    ,credpis.bens     x13
    ,credpis.fornecedores x04
    ,credpis.regras reg

where emp.codigo = estab.empresa_codigo
and   x148.empresa_codigo = estab.empresa_codigo
and   x148.filial_codigo = estab.codigo
and   x148.empresa_codigo = emp.codigo
and   x148.empresa_codigo = x13.empresa_codigo
and   x148.filial_codigo = x13.filial_codigo
and   x148.bem_codigo = x13.codigo
and   x13.empresa_codigo = x04.empresa_codigo
and   x13.fornecedor_codigo = x04.codigo
and   x13.regra_codigo = reg.codigo
and   emp.codigo_contabil = pcd_empr
and   x148.data = pdt_apur;

BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('MSAF_LV_CREDPIS_CPROC', 48, 150);
    LIB_PROC.add_tipo(mproc_id, 2, 'ARQ_LV_CREDPIS_EXT', 2);

    BEGIN

         v_reg_c :=   'CODIGO'                           ||'|'||
                      'NUMERO_PATRIMONIAL'               ||'|'||
                      'COD_EMPRESA'                      ||'|'||
                      'COD_ESTAB'                        ||'|'||
                      'NUM_DOCFIS'                       ||'|'||
                      'SERIE_DOCFIS'                     ||'|'||
                      'DATA_ENTRADA'                     ||'|'||
                      'FORNECEDOR'                       ||'|'||
                      'CPF_CNPJ'                         ||'|'||
                      'DESCRICAO'                        ||'|'||
                      'DATA_INICIO_CREDITO'              ||'|'||
                      'DATA_FIM_CREDITO'                 ||'|'||
                      'DATA_APURACAO'                    ||'|'||
                      'SALDO_INICIAL_PARC_APROPRIADAS'   ||'|'||
                      'VALOR_PIS'                        ||'|'||
                      'VALOR_COFINS'                     ||'|'||
                      'PIS_CRED_ACUMULADO'               ||'|'||
                      'COFINS_CRED_ACUMULADO'            ||'|'||
                      'TOTAL_PARCELAS'                   ||'|'||
                      'BASE_CALCULO_MENSAL'              ||'|'||
                      'ALIQUOTA_PIS'                     ||'|'||
                      'VALOR_PIS_MENSAL'                 ||'|'||
                      'ALIQUOTA_COFINS'                  ||'|'||
                      'VALOR_COFINS_MENSAL'              ||'|'||
                      'SALDO_PIS_A_CREDITAR'             ||'|'||
                      'SALDO_COFINS_A_CREDITAR'          ||'|'||
                      'SALDO_FINAL_PARC_APROPRIADAS'     ||'|'||
                      'PARCELAS_A_CREDITAR'              ||'|'||
                      'IND_ORIGEM_BEM'                   ||'|'||
                      'TIPO_CREDITAMENTO';



          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 2);

          LIB_PROC.add(mLinha, null, null, 2);

      FOR mreg IN ict_1 LOOP

          v_reg :=  mreg.x1                   ||'|'||
                    mreg.x2                   ||'|'||
                    mreg.x3                   ||'|'||
                    mreg.x4                   ||'|'||
                    mreg.x5                   ||'|'||
                    mreg.x6                   ||'|'||
                    mreg.x7                   ||'|'||
                    mreg.x8                   ||'|'||
                    mreg.x9                   ||'|'||
                    mreg.x10                  ||'|'||
                    mreg.x11                  ||'|'||
                    mreg.x12                  ||'|'||
                    mreg.x13                  ||'|'||
                    mreg.x14                  ||'|'||
                    trim(translate(to_char(mreg.x15,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x16,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x17,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x18,'999999999999d00'), '.',','))                  ||'|'||
                    mreg.x19                  ||'|'||
                    trim(translate(to_char(mreg.x20,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x21,'9999d0000'), '.',','))                        ||'|'||
                    trim(translate(to_char(mreg.x22,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x23,'9999d0000'), '.',','))                        ||'|'||
                    trim(translate(to_char(mreg.x24,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x25,'999999999999d00'), '.',','))                  ||'|'||
                    trim(translate(to_char(mreg.x26,'999999999999d00'), '.',','))                  ||'|'||
                    mreg.x27                  ||'|'||
                    mreg.x28                  ||'|'||
                    mreg.x29                  ||'|'||
                    mreg.x30;
                    

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 1);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;

          v_reg := null;

      END LOOP;



    END;

    if v_linha = 0 then
     lib_proc.add_log('Não foram localizados registros - verificar se a apuracao foi realizada. ', 1);
    else
     lib_proc.add_log('Geração do relatório concluída! Foram gravados '||v_linha||' registros ', 1);
    end if;

     LIB_PROC.CLOSE();

    RETURN mproc_id;
  END;

END MSAF_LV_CREDPIS_CPROC;
/
