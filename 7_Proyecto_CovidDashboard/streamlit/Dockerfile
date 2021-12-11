FROM python:3.8
EXPOSE 8501
RUN pip install streamlit
RUN pip install sqlalchemy
RUN pip install pymysql
RUN pip install plotly
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]
RUN mkdir -p /var/CovidDash
CMD streamlit run /var/CovidDash/app.py
