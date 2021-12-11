import os

from datetime import datetime
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.hooks.mysql_hook import MySqlHook
import pandas as pd
import time
import pytz
from datetime import date
from datetime import datetime
import numpy as np
from airflow.contrib.hooks.fs_hook import FSHook
from structlog import get_logger
logger = get_logger()

#----------------------------DAG DEFINITION--------------------------------------------------------
dag = DAG('Files_ingestion', description='Ingestion ETL COVID-19 dashboard',
          default_args={
              'owner': 'PD_2021',
              'depends_on_past': False,
              'max_active_runs': 5,
              'start_date': days_ago(5)
          },
          schedule_interval='0 1 * * *',
          catchup=False)


#----------------------------DB TABLE CREATION-----------------------------------------------------
def checkDBTables(**kwargs):
    file_path = f"{FSHook('fs_DBSchema').get_path()}/CovidDashDBSchema.sql"
    logger.info(file_path)
    file = open(file_path,mode='r')
    dbSchema = file.read().split(';')
    dbSchema[:] = [x for x in dbSchema if x]
    file.close()

    connection = MySqlHook('mysql_default').get_sqlalchemy_engine()
    with connection.begin() as transacion:
        for table in dbSchema:
            transacion.execute(table)
            logger.info(table)


#----------------------------TABLE COLUMNS DEFINITION----------------------------------------------
COLUMNS = {
    "Province/State": "PROVINCE_STATE",
    "Country/Region": "COUNTRY_REGION",
    "Lat": "LATITUDE",
    "Long": "LONGITUDE",
    "Acumulado": "ACUMULATED",
    "Date": "DATE",
    "Delta":"DELTA"
    
}

#----------------------------TRANSFORM AND INSERT DATA INTO DATABASE-------------------------------
def ingest_file(connectionName, fileName, tableName):
    try:
        file_path = f"{FSHook(connectionName).get_path()}/1_ToProcess/{fileName}"
        connection = MySqlHook('mysql_default').get_sqlalchemy_engine()
        events = pd.read_csv(file_path,encoding = 'ISO-8859-1')
        column_list = list(events)
        column_list.remove('Province/State')
        column_list.remove('Country/Region')
        column_list.remove('Lat')
        column_list.remove('Long')

        #Proceso de transponer columnas a filas
        first_time = True
        for x in column_list:
            if(first_time == True):
                events_all = events[['Province/State','Country/Region','Lat','Long',x]]
                date = x[:-2]+'20'+x[-2:]
                events_all['Date'] =  datetime.strptime(date,'%m/%d/%Y')
                events_all['Delta'] =  0
                events_all = events_all.rename(columns={x:'Acumulado'})
                
                first_time = False
            else:
                events_all2 = events[['Province/State','Country/Region','Lat','Long',x]]
                date = x[:-2]+'20'+x[-2:]
                events_all2['Date'] =  datetime.strptime(date,'%m/%d/%Y')
                events_all2['Delta'] =  0
                events_all2 = events_all2.rename(columns={x:'Acumulado'})
                events_all = pd.concat([events_all, events_all2], axis=0) 

    #Proceso creacion de delta
        events_all['Country/Region'] = events_all['Country/Region'].fillna("")
        events_all['Province/State'] = events_all['Province/State'].fillna("")
        a_df=events_all[["Country/Region","Province/State"]]
        a_df = a_df.drop_duplicates()
        a_df = a_df.where(pd.notnull(a_df), "")

        first_time = True
        for index, row in a_df.iterrows():
            acumulado_ant = 0
            df_mask = events_all.loc[events_all.loc[:, 'Country/Region'] == row['Country/Region']].sort_values(["Country/Region","Province/State" ,"Date"], ascending = (True, True,True))
            
            
            df_mask = df_mask.loc[df_mask.loc[:, 'Province/State'] == row['Province/State']].sort_values(["Country/Region","Province/State" ,"Date"], ascending = (True, True,True))
            acumulado_ant = 0
                
            df_mask.reset_index(drop=True,inplace=True)
            for index2, row2 in df_mask.iterrows():        
                delta = row2['Acumulado'] - acumulado_ant        
                df_mask.loc[index2, 'Delta'] = delta
                acumulado_ant = row2['Acumulado']
            if(first_time == True):
                events_final = df_mask
                first_time = False
            else:        
                events_final = pd.concat([events_final, df_mask], axis=0) 
        events_final = events_final.rename(columns=COLUMNS)

        logger.info(events_final)

        with connection.begin() as transacion:
            transacion.execute(f'DELETE FROM {tableName} WHERE 1 = 1')
            events_final.to_sql(tableName,con=transacion,schema='dash',if_exists='replace',index=False)
        logger.info(f"Records Inserted: {len(events_final.index)}")
        os.rename(file_path, f"{FSHook(connectionName).get_path()}/2_Processed/{fileName}")
    except:
        os.rename(file_path, f"{FSHook(connectionName).get_path()}/3_Error/{fileName}")    

#----------------------------METHODS TO TRIGGER INGESTION PROCESS----------------------------------
def process_death_file(**kwargs):
    logger.info(kwargs['execution_date'])
    ingest_file('fs_DeathsFiles', 'deaths.csv', 'deaths')

def process_confirmed_file(**kwargs):
    logger.info(kwargs['execution_date'])
    ingest_file('fs_ConfirmedFiles', 'confirmed.csv', 'confirmed')    
    
def process_recovered_file(**kwargs):
    logger.info(kwargs['execution_date'])
    ingest_file('fs_RecoveredFiles', 'recovered.csv', 'recovered')  
    
#----------------------------DEFINING DAG PROCESSES------------------------------------------------          
sensorDeath = FileSensor(filepath = '1_ToProcess/deaths.csv', 
                    fs_conn_id='fs_DeathsFiles', 
                    task_id = 'check_for_deaths_file',
                    poke_interval = 5,
                    timeout = 60,
                    dag = dag)

sensorConfirmed = FileSensor(filepath = '1_ToProcess/confirmed.csv', 
                    fs_conn_id='fs_ConfirmedFiles', 
                    task_id = 'check_for_confirmed_file',
                    poke_interval = 5,
                    timeout = 60,
                    dag = dag)   

sensorRecovered = FileSensor(filepath = '1_ToProcess/recovered.csv', 
                    fs_conn_id='fs_RecoveredFiles', 
                    task_id = 'check_for_recovered_file',
                    poke_interval = 5,
                    timeout = 60,
                    dag = dag) 


operateDeathFile = PythonOperator(task_id='process_death_file',
                          dag=dag,
                          python_callable =process_death_file,
                          provide_context = True)

operateConfirmedFile = PythonOperator(task_id='process_confirmed_file',
                          dag=dag,
                          python_callable =process_confirmed_file,
                          provide_context = True)
    
operateRecoveredFile = PythonOperator(task_id='process_recovered_file',
                          dag=dag,
                          python_callable =process_recovered_file,
                          provide_context = True)


dbCheckOperator = PythonOperator(task_id='DB_Check_process',
                          dag=dag,
                          python_callable =checkDBTables,
                          provide_context = True)



#sensor>>operador
dbCheckOperator >> sensorDeath     >> operateDeathFile
dbCheckOperator >> sensorConfirmed >> operateConfirmedFile
dbCheckOperator >> sensorRecovered >> operateRecoveredFile