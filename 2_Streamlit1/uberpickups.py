import streamlit as st
import numpy as np
import pandas as pd
import math
import datetime as dt

st.title("Uber pickups test")

#---------------------CONSTANTS
DATA_SOURCE = "https://s3-us-west-2.amazonaws.com/streamlit-demo-data/uber-raw-data-sep14.csv.gz"
ROWS_PER_PAGE = 1000


# LOADING DATA

@st.cache
def download_data():
    tempdf = (pd.read_csv(DATA_SOURCE)
    .rename(columns={'Lat':'lat', 'Lon':'lon'})
    )
    tempdf['Date/Time'] = pd.to_datetime(tempdf['Date/Time'])
    return tempdf

df = download_data()

"""
### Pickups by Hour of the Day
"""

hoursDF = pd.DataFrame(df["Date/Time"].dt.hour).rename(columns = {'0':'Hour'})
hoursDF = hoursDF.groupby(["Date/Time"]).size()
st.bar_chart(hoursDF)

"""
### Filters
"""

#Filtering by time
timeSlider = st.slider('Filter day time', 0, 23, value = [0,23])
after_start_time = df["Date/Time"].dt.time >= dt.time(timeSlider[0])
before_end_time = df["Date/Time"].dt.time <= dt.time(timeSlider[1],59)
filtered_times = df.loc[after_start_time & before_end_time]

st.write(len(filtered_times))


#Limting pages
totalPages =  math.ceil(len(filtered_times) / ROWS_PER_PAGE)

slider = st.slider('Select the page', 1, totalPages)
lower = (slider -1) * ROWS_PER_PAGE
upper = len(filtered_times) if ((slider * ROWS_PER_PAGE) -1) > len(filtered_times) else (slider * ROWS_PER_PAGE) -1

st.write('page selected', slider, 'with limits', lower, upper)

filtered_times = filtered_times[lower: upper]

"""
### Data Frame
"""
filtered_times
"""
### Map
"""
st.map(filtered_times)