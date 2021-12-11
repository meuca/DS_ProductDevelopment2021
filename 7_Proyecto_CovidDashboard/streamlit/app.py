import configparser
from sqlalchemy import create_engine
import pymysql
import streamlit as st
import numpy as np
import pandas as pd
import datetime
import plotly.express as px
import time
import math
import base64 
import pydeck as pdk

config = configparser.ConfigParser()
config.read('/var/CovidDash/config.ini') 

@st.cache(allow_output_mutation=True, hash_funcs={"_thread.RLock": lambda _: None})
def init_connection():       
    sqlEngine = create_engine(f"mysql+pymysql://{config['mysql']['user']}:{config['mysql']['password']}@{config['mysql']['host']}", pool_recycle=3600)
    return sqlEngine.connect()    
    
conn = init_connection()

def pullData(query):
    return pd.read_sql(query, conn)

df_confirmados = pullData(config['queries']['pullConfirmed'])
df_reccuperados = pullData(config['queries']['pullRecovered'])
df_fallecidos = pullData(config['queries']['pullDeaths'])


@st.cache
def load_data(file, metric):
    data = file
    data['coordinates'] = data[['LONGITUDE', 'LATITUDE']].values.tolist()
    data['PROVINCE_STATE'] = data['PROVINCE_STATE'].fillna(data['COUNTRY_REGION'])
    data['CountryRegion'] = data['PROVINCE_STATE']
    data['CountryRegion'] = data.apply(lambda x: x['COUNTRY_REGION'] if x['COUNTRY_REGION'] == 'Canada' else x['CountryRegion'], axis=1)
    data['CountryRegion'] = data.apply(lambda x: x['COUNTRY_REGION'] if x['COUNTRY_REGION'] == 'Australia' else x['CountryRegion'], axis=1)
    data['CountryRegion'] = data.apply(lambda x: x['COUNTRY_REGION'] if x['COUNTRY_REGION'] == 'China' else x['CountryRegion'], axis=1)
    data['Metric'] = metric
    data = data.dropna()

    return data


df_confirmados=df_confirmados[df_confirmados['DELTA']>=0]
df_reccuperados=df_reccuperados[df_reccuperados['DELTA']>=0]
df_fallecidos=df_fallecidos[df_fallecidos['DELTA']>=0]


st.write("------------------")
st.title('Covid19 - Analisis de datos')
my_bar = st.progress(0)
st.write("------------------")    
    
confirmados = '{:20,.0f}'.format(df_confirmados['DELTA'].sum()) 
recuperados = '{:20,.0f}'.format(df_reccuperados['DELTA'].sum()) 
fallecidos =  '{:20,.0f}'.format(df_fallecidos['DELTA'].sum()) 


datos = {'Ubicacion':'Global',
         'Casos Confirmados':confirmados,
        'Casos Recuperados' :  recuperados,
         'Casos Fallecidos' : fallecidos}


st.write('Casos de covid19  a nivel munical')
st.write(pd.DataFrame([datos]))

Pais_confirmados=df_confirmados['COUNTRY_REGION'].unique()
Pais_recuperados=df_reccuperados['COUNTRY_REGION'].unique()
Pais_fallecidos=df_fallecidos['COUNTRY_REGION'].unique()


#prov_confirmados=df_confirmados['COUNTRY_REGION'].unique()
#prov_recuperados=df_reccuperados['COUNTRY_REGION'].unique()
#prov_fallecidos=df_fallecidos['COUNTRY_REGION'].unique()



pais  = st.sidebar.multiselect(
    'Selecciones  pais(es)',
    Pais_confirmados
    )



    
fechainicio = st.sidebar.date_input(
    "Seleccione de inico",
    datetime.date(2020, 1, 22)   
 )


fechafin = st.sidebar.date_input(
    "Seleccione fecha de fin",
    datetime.date(2021, 8, 4)   
 )
 

st.write("Casos  por pais")
with st.expander("Detalle", expanded=True):
    
    if len(pais)==0:
       pais= Pais_confirmados

    
    df_resumenGeneral = pd.DataFrame()
    filtered_con= df_confirmados[df_confirmados['COUNTRY_REGION'].isin(pais)] 
    filtered_con= filtered_con[filtered_con['DATE']>=str(fechainicio)]      
    filtered_conf= filtered_con[filtered_con['DATE']<=str(fechafin)]
    resumen_con=filtered_conf.groupby(['COUNTRY_REGION'])['DELTA'].sum()
    general = pd.DataFrame(resumen_con)
    total_casos = general.rename(columns={'DELTA':'Casos_confirmados'})
    
    
    
    filtered_rec= df_reccuperados[df_reccuperados['COUNTRY_REGION'].isin(pais)] 
    filtered_rec= filtered_rec[filtered_rec['DATE']>=str(fechainicio)]      
    filtered_rec= filtered_rec[filtered_rec['DATE']<=str(fechafin)]
    resumen_rec=filtered_rec.groupby(['COUNTRY_REGION'])['DELTA'].sum()
    general_rec = pd.DataFrame(resumen_rec)
    total_casos['Casos_recuperados']=general_rec['DELTA']
    
    
    filtered_fa= df_fallecidos[df_fallecidos['COUNTRY_REGION'].isin(pais)] 
    filtered_fa= filtered_fa[filtered_fa['DATE']>=str(fechainicio)]      
    filtered_fa= filtered_fa[filtered_fa['DATE']<=str(fechafin)]
    resumen_fa=filtered_fa.groupby(['COUNTRY_REGION'])['DELTA'].sum()
    general = pd.DataFrame(resumen_fa)
    total_casos['Casos_fallecidos']=general['DELTA']
    
    
    st.write(total_casos)
    
 
    fig = px.line(filtered_conf, x="DATE", y="DELTA", color='COUNTRY_REGION',
                  title='Grafica  - Casos confirmados'
                  )
    st.plotly_chart(fig)
    
    
    
    fig = px.line(filtered_rec, x="DATE", y="DELTA", color='COUNTRY_REGION',
                  title='Grafica  - Casos recuperados'
                  )
    st.plotly_chart(fig)
    
    
    fig = px.line(filtered_fa, x="DATE", y="DELTA", color='COUNTRY_REGION',
                  title='Grafica  - Casos Fallecidos' )
    st.plotly_chart(fig)
    
    
st.write("------------------")    
st.write("Mapa de casos")
with st.expander("Metricas por pais"):

    def merge_data(x, y, z):
        xyz = pd.concat([x, y, z], ignore_index=True)
        xyz = xyz.dropna()
        xyz = xyz.drop(['DELTA'], axis='columns')
        return xyz


    def grouping(df):
        x = df[['CountryRegion', 'DATE', 'ACUMULATED', 'Metric']]
        suma = x.groupby(['CountryRegion', 'DATE', 'Metric'], as_index=False).sum()
        return suma


    def unique(df):
        x = df[['CountryRegion', 'coordinates']]
        x = x.groupby('CountryRegion', as_index=False)['coordinates'].first()
        x['r'] = np.random.randint(0, 256, x.shape[0])
        x['g'] = np.random.randint(0, 256, x.shape[0])
        x['b'] = np.random.randint(0, 256, x.shape[0])
        return x


    def final(df, df1):
        x = pd.merge(df, df1, on='CountryRegion', how='left')
        x['tacumulado'] = x['ACUMULATED'].apply(lambda d: f'{round(d, 2):,}')
        return x


    ######################################## Data Load ###############################################

    df1 = load_data(df_confirmados, 'Confirmed')
    df2 = load_data(df_reccuperados, 'Recovered')
    df3 = load_data(df_fallecidos, 'Deaths')

    dfmerge = merge_data(df1, df2, df3)

    dfgroup = grouping(dfmerge)

    dfunique = unique(dfmerge)

    dfinal = final(dfgroup, dfunique)

    ####################################### Layout ###################################################

    #st.title('Metricas por pais')

    #st.markdown("""--------""")

    opciones = ['Confirmed', 'Recovered', 'Deaths']

    cols = st.selectbox('Seleccion', opciones)

    date = st.date_input('Select Date', value=pd.to_datetime('2020-01-01', format=('%Y-%m-%d')))
    starts = date.strftime("%Y-%m-%d")

    if cols in opciones:
        opciones_layer = cols

    test = dfinal[(dfinal.Metric == opciones_layer) & (dfinal.DATE == starts)]

    valores = {'Confirmed': 0.06, 'Recovered': 0.06, 'Deaths': 1.3}

    if cols in valores:
        valores_layer = valores.get(cols)

    #########################################################################################

    layer = pdk.Layer(
        "ScatterplotLayer",
        test,
        pickable=True,
        opacity=0.2,
        stroked=False,
        filled=True,
        radius_scale=valores_layer,
        radius_min_pixels=1,
        radius_max_pixels=50,
        line_width_min_pixels=1,
        get_position="coordinates",
        get_radius='ACUMULATED',
        get_fill_color=['r','g','b'],
        get_line_color=[0, 0, 0],
    )

    # Set the viewport location
    view_state = pdk.ViewState(latitude=0.0, longitude=-0.0, zoom=1, bearing=0, pitch=0)

    # Render

    r = pdk.Deck(layers=[layer], initial_view_state=view_state,
                 tooltip={"text": "{CountryRegion}\n{Date}\n{tacumulado}"}
                 # map_style="mapbox://styles/mapbox/light-v10"
                 )


    st.pydeck_chart(r)


    #-----------------------------------------------------------------------------------------------------



st.write("------------------")
   

st.write("Detalle general de casos")
with st.expander("Detalle: ", expanded=False):
    op= ['Casos confirmados','Casos recuperados','Muertes']
    opcion  = st.selectbox('Selección:', op)
    
    if  (opcion=="Casos confirmados" or  opcion is None  or  opcion==""):
        if len(pais)==0:
            Pais_confirmados

        filtered_df = df_confirmados[df_confirmados['COUNTRY_REGION'].isin(pais)] 
        filtered_df= filtered_df[filtered_df['DATE']>=str(fechainicio)]      
        filtered_df= filtered_df[filtered_df['DATE']<=str(fechafin)]

        st.write(filtered_df)


    if  (opcion=='Casos recuperados'):
        if len(pais)==0:
            Pais_recuperados

        filtered_df = df_reccuperados[df_reccuperados['COUNTRY_REGION'].isin(pais)]
        filtered_df= filtered_df[filtered_df['DATE']>=str(fechainicio)]      
        filtered_df= filtered_df[filtered_df['DATE']<=str(fechafin)]
        st.write(filtered_df)

    if  (opcion=='Muertes'):
        if len(pais)==0:
            Pais_fallecidos

        filtered_df = df_fallecidos[df_fallecidos['COUNTRY_REGION'].isin(pais)]
        filtered_df= filtered_df[filtered_df['DATE']>=str(fechainicio)]      
        filtered_df= filtered_df[filtered_df['DATE']<=str(fechafin)]
        st.write(filtered_df)




