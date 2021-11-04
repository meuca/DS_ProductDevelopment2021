import streamlit as st
import numpy as np
import pandas as pd
import time

st.title("This is my first stramlit app, for Galileo Master")

x = 4

st.write(x, 'square is', x*x)

df = pd.DataFrame({
    'Column A': [1,2,3,4,5],
    'Column B': ['A', 'B', 'C', 'D', 'E']
})

st.write(df)

"""
## Let's use some graphs

"""
chart_df = pd.DataFrame(
    np.random.rand(20,3),
    columns=['A', 'B', 'C']
)

st.line_chart(chart_df)


"""
## How about a map
"""
map_df = pd.DataFrame(
    np.random.randn(1000, 2) / [50,50]+[37.76, -122.4],
    columns=['lat', 'lon']
)

st.map(map_df)

"""
## Show me some widgets
"""
if st.checkbox('show me the dataframe'):
    map_df

x = st.slider('select value for x')
st.write(x, 'square is', x**2)

option = st.selectbox(
    'Which number do you like best?',
    [1,2,3,4,5,6,7,8,9,10]
)

st.write('you select the option', option)

""" 
### Progress Bar
"""
progress_label = st.empty()
progress = st.progress(0)


for i in range(100):
    progress_label.text(f'iteration {i}')
    progress.progress(i)
    time.sleep(0.1)

""" 
### Sidebar
"""
option_side = st.sidebar.selectbox('Choose you weapon', ['handgun', 'machinegun', 'knife'])
st.sidebar.write('Your weapon of choise is: ', option_side)

another_slider = st.sidebar.slider('select te range', 0.0, 100.0, (25.0, 75))

st.sidebar.write('The range selected is:', another_slider)
